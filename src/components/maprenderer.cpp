/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#include <algorithm>
#include <cmath>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QLoggingCategory>
#include <QPainter>
#include <QThreadPool>
#include "maprenderer.h"

/* TODO
 * - Color the area
 *   - Colouring (DONE)
 *   - Use theme colour
 * - Zoom out
 *   - Generic minimum zoom (DONE)
 *   - Adjust zoom for each country
 * - Circle small islands
 * - Jolla C performance?
 *   - Would splitting tiles to separate textures (and threads) help?
 *   - Smaller texture? Generating the correct texture on startup?
 *   - Or just some UI change to allow for a bit of loading time?
 */

Q_LOGGING_CATEGORY(lcMapRenderer, "site.tomin.apps.CountryQuiz.MapRenderer", QtWarningMsg)

QMutex MapRenderer::s_rendererMutex;

QVector<MapRenderer *> MapRenderer::s_renderers;

QThread *MapRenderer::s_rendererThread = nullptr;

MapRenderer *MapRenderer::get(const QString &filePath)
{
    QMutexLocker locker(&s_rendererMutex);
    MapRenderer *renderer = nullptr;
    if (!s_rendererThread) {
        qCCritical(lcMapRenderer) << "Could not get MapRenderer as there is no renderer thread!";
    } else {
        for (auto candidate : s_renderers) {
            if (candidate->m_mapFilePath == filePath)
                renderer = candidate;
        }
        if (!renderer) {
            renderer = new MapRenderer(filePath);
            renderer->moveToThread(s_rendererThread);
            connect(s_rendererThread, &QThread::finished, renderer, &QObject::deleteLater);
            s_renderers.append(renderer);
            qCDebug(lcMapRenderer) << "Created new renderer for" << filePath;
        }
    }
    return renderer;
}

void MapRenderer::setup(QCoreApplication *app)
{
    if (!s_rendererThread) {
        QMutexLocker locker(&s_rendererMutex);
        if (!s_rendererThread) {
            s_rendererThread = new QThread(app);
            connect(app, &QCoreApplication::aboutToQuit, []() {
                s_rendererThread->quit();
                s_rendererThread->wait();
            });
            s_rendererThread->start();
            qCDebug(lcMapRenderer) << "Setup for rendering thread completed";
        }
    }
}

namespace {
    int mod(int x, int y) {
        return x >= 0 ? x % y : (y + x) % y;
    }

    QRectF adjusted_area(const QRectF &target, const QRectF &fullArea, qreal minArea, qreal aspectRatio)
    {
        QRectF bounds(target);
        if (target.width() < minArea * fullArea.width()) {
            qreal targetWidth = minArea * fullArea.width();
            qreal margin = (targetWidth - target.width()) / 2;
            bounds.setLeft(target.left() - margin);
            bounds.setRight(target.right() + margin);
        }
        if (bounds.width() < bounds.height() * aspectRatio) {
            qreal targetWidth = bounds.height() * aspectRatio;
            qreal margin = (targetWidth - bounds.width()) / 2;
            bounds.setLeft(bounds.left() - margin);
            bounds.setRight(bounds.right() + margin);
        } else if (bounds.height() < bounds.width() / aspectRatio) {
            qreal targetHeight = bounds.width() / aspectRatio;
            qreal margin = (targetHeight - bounds.height()) / 2;
            bounds.setTop(bounds.top() - margin);
            bounds.setBottom(bounds.bottom() + margin);
        }
        return bounds;
    }

    QImage draw_overlay(QSvgRenderer &renderer, const QString &code, const QRectF &target, const QColor &color)
    {
        QImage overlay(target.size().toSize(), QImage::Format_ARGB32_Premultiplied);
        overlay.fill(color);

        QImage element(target.size().toSize(), QImage::Format_ARGB32_Premultiplied);
        element.fill(Qt::transparent);
        QPainter elementPainter(&element);
        renderer.render(&elementPainter, code);

        QPainter overlayPainter(&overlay);
        overlayPainter.setCompositionMode(QPainter::CompositionMode_DestinationIn);
        overlayPainter.drawImage(QPoint(0, 0), element);
        return overlay;
    }
} // namespace

void MapRenderer::renderMap(const QSize &maxSize, const QString &code)
{
    QRectF fullArea = m_renderer.boundsOnElement("world");
    QMatrix matrix = m_renderer.matrixForElement(code);
    QRectF element = matrix.mapRect(m_renderer.boundsOnElement(code));
    qreal aspectRatio = static_cast<qreal>(maxSize.width()) / maxSize.height();
    QRectF bounds = adjusted_area(element, fullArea, 0.15, aspectRatio);

    QTransform translation = QTransform::fromTranslate(-bounds.left(), -bounds.top());
    QTransform scaling = QTransform::fromScale(maxSize.width() / bounds.width(), maxSize.height() / bounds.height());

    QSizeF tileSize(fullArea.width() / m_dimensions.width(), fullArea.height() / m_dimensions.height());
    QSize tileCount(bounds.width() / tileSize.width(), bounds.height() / tileSize.height());

    emit tileCountReady(maxSize, tileCount, code);

    QThreadPool *pool = QThreadPool::globalInstance();

    QColor overlayColor(Qt::red);
    overlayColor.setAlphaF(0.25);
    auto *overlayRenderer = new OverlayRenderer(m_renderer, element, overlayColor, translation, scaling, code);
    connect(overlayRenderer, &OverlayRenderer::overlayReady, this, &MapRenderer::overlayReady, Qt::QueuedConnection);
    overlayRenderer->setAutoDelete(true);
    pool->start(overlayRenderer);

    QPoint position(std::floor((bounds.left() - fullArea.left()) / tileSize.width()), std::max((qreal)0.0, std::floor((bounds.top() - fullArea.top()) / tileSize.height())));
    QPointF point((qreal)position.x() * tileSize.width() + fullArea.left(), (qreal)position.y() * tileSize.height() + fullArea.top());
    while (point.y() <= bounds.bottom()) {
        while (point.x() <= bounds.right()) {
            // TODO: Some countries don't work, at least Russia is broken
            QString name(m_tilePathTemplate.arg(mod(position.x(), m_dimensions.width())).arg(position.y()));
            auto *tileRenderer = new TileRenderer(name, QRectF(point, tileSize), translation, scaling, code);
            connect(tileRenderer, &TileRenderer::tileReady, this, &MapRenderer::tileReady, Qt::QueuedConnection);
            tileRenderer->setAutoDelete(true);
            pool->start(tileRenderer);

            position.setX(position.x() + 1);
            point.setX(point.x() + tileSize.width());
        }
        position = QPoint(std::floor((bounds.left() - fullArea.left()) / tileSize.width()), position.y() + 1);
        point = QPointF((qreal)position.x() * tileSize.width() + fullArea.left(), point.y() + tileSize.height());
    }
}

MapRenderer::MapRenderer(const QString &filePath, QObject *parent)
    : QObject(parent)
    , m_mapFilePath(filePath)
    , m_renderer(filePath)
{
    QFile tiles(filePath + ".txt");
    if (tiles.exists() && tiles.open(QIODevice::ReadOnly)) {
        auto info = tiles.readAll();
        if (info.endsWith('\n'))
            info.chop(1);
        auto parts = info.split(';');
        if (parts.size() != 3) {
            qCWarning(lcMapRenderer) << tiles.fileName() << "looks malformed, wrong number of parts";
            return;
        }
        bool ok = false;
        int width = parts.at(1).toInt(&ok);
        if (!ok) {
            qCWarning(lcMapRenderer) << tiles.fileName() << "looks malformed," << parts.at(1) << "is not integer";
            return;
        }
        int height = parts.at(2).toInt(&ok);
        if (!ok) {
            qCWarning(lcMapRenderer) << tiles.fileName() << "looks malformed," << parts.at(2) << "is not integer";
            return;
        }
        m_tilePathTemplate = QFileInfo(filePath).dir().absoluteFilePath(parts.at(0));
        m_dimensions = QSize(width, height);
    } else {
        qCDebug(lcMapRenderer) << "Could not read tiles info file from" << tiles.fileName() << ", error" << tiles.error();
    }
}

TileRenderer::TileRenderer(const QString &path, const QRectF &rect, const QTransform &translation, const QTransform &scaling, const QString &code)
    : QObject()
    , m_path(path)
    , m_rect(rect)
    , m_translation(translation)
    , m_scaling(scaling)
    , m_code(code)
{
}

void TileRenderer::run()
{
    // TODO: Also clip tiles here
    QImage tile(m_path);
    QRectF transformed = m_scaling.mapRect(m_translation.mapRect(m_rect));

    QImage scaled(transformed.size().toSize(), QImage::Format_ARGB32_Premultiplied);
    scaled.fill(Qt::transparent);
    QPainter painter(&scaled);
    painter.drawImage(QRectF(QPoint(), transformed.size().toSize()), tile);

    emit tileReady(scaled, transformed, m_code);
}

OverlayRenderer::OverlayRenderer(QSvgRenderer &renderer, const QRectF &rect, const QColor &color, const QTransform &translation, const QTransform &scaling, const QString &code)
    : QObject()
    , m_renderer(renderer)
    , m_rect(rect)
    , m_color(color)
    , m_translation(translation)
    , m_scaling(scaling)
    , m_code(code)
{
}

void OverlayRenderer::run()
{
    QRectF transformed = m_scaling.mapRect(m_translation.mapRect(m_rect));
    QImage overlay = draw_overlay(m_renderer, m_code, transformed, m_color);

    emit overlayReady(overlay, transformed, m_code);
}