/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#include <algorithm>
#include <cmath>
#include <iterator>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QLoggingCategory>
#include <QPainter>
#include <QThreadPool>
#include <sys/sysinfo.h>
#include <utility>
#include "map.h"
#include "maprenderer.h"

/* TODO
 * - Color the area
 *   - Colouring (DONE)
 *   - Use theme colour
 * - Zoom out
 *   - Generic minimum zoom (DONE)
 *   - Adjust zoom for each country
 * - Circle small islands
 * - Better performance?
 *   - Would splitting tiles to separate textures (and threads) help? (DONE)
 *   - Smaller texture? Generating the correct texture on startup? (DONE)
 *   - Or just some UI change to allow for a bit of loading time? (NOT PLANNED)
 *   - Splitting some big countries in svg? (TODO, mainly helps Canada)
 *   - Two tiered drawing? First rough version and then replace that when better tiles are ready?
 * - Other improvements
 *   - Clip tiles already here while resizing
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
            qCInfo(lcMapRenderer) << "Setup for rendering thread completed";
            qCDebug(lcMapRenderer) << "Cores:" << get_nprocs() << "cores online," << get_nprocs_conf() << "cores configured";
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
    Map *map = qobject_cast<Map *>(sender());

    QRectF fullArea = m_renderer.boundsOnElement("world");
    QMatrix matrix = m_renderer.matrixForElement(code);
    QRectF element = matrix.mapRect(m_renderer.boundsOnElement(code));
    qreal aspectRatio = static_cast<qreal>(maxSize.width()) / maxSize.height();
    QRectF bounds = adjusted_area(element, fullArea, 0.15, aspectRatio);

    QTransform translation = QTransform::fromTranslate(-bounds.left(), -bounds.top());
    QTransform scaling = QTransform::fromScale(maxSize.width() / bounds.width(), maxSize.height() / bounds.height());
    const Tiles &tiles = getTilesForScaling(maxSize, bounds.size());
    QSizeF tileSize(fullArea.width() / tiles.dimensions.width(), fullArea.height() / tiles.dimensions.height());

    QThreadPool pool;
    pool.setMaxThreadCount(get_nprocs_conf());

    QColor overlayColor(Qt::red);
    overlayColor.setAlphaF(0.25);
    auto *overlayRenderer = new OverlayRenderer(m_renderer, element, overlayColor, translation, scaling, code, this);
    connect(overlayRenderer, &OverlayRenderer::renderingReady, map, &Map::renderingReady, Qt::QueuedConnection);
    overlayRenderer->setAutoDelete(true);
    pool.start(overlayRenderer, QThread::HighPriority);

    QPoint position(std::floor((bounds.left() - fullArea.left()) / tileSize.width()), std::max((qreal)0.0, std::floor((bounds.top() - fullArea.top()) / tileSize.height())));
    QPointF point((qreal)position.x() * tileSize.width() + fullArea.left(), (qreal)position.y() * tileSize.height() + fullArea.top());
    while (point.y() <= bounds.bottom()) {
        while (point.x() <= bounds.right()) {
            QString name(tiles.pathTemplate.arg(mod(position.x(), tiles.dimensions.width())).arg(position.y()));
            auto *tileRenderer = new TileRenderer(name, QRectF(point, tileSize), translation, scaling, this);
            connect(tileRenderer, &TileRenderer::renderingReady, map, &Map::renderingReady, Qt::QueuedConnection);
            tileRenderer->setAutoDelete(true);
            pool.start(tileRenderer, QThread::NormalPriority);

            position.setX(position.x() + 1);
            point.setX(point.x() + tileSize.width());
        }
        position = QPoint(std::floor((bounds.left() - fullArea.left()) / tileSize.width()), position.y() + 1);
        point = QPointF((qreal)position.x() * tileSize.width() + fullArea.left(), point.y() + tileSize.height());
    }

    pool.waitForDone();
    QMetaObject::invokeMethod(map, "renderingReady", Qt::QueuedConnection, Q_ARG(MapRenderer::MessageType, RenderingDone), Q_ARG(QSGTexture *, nullptr), Q_ARG(QRectF, QRectF(QPointF(), maxSize)));
}

MapRenderer::MapRenderer(const QString &filePath, QObject *parent)
    : QObject(parent)
    , m_mapFilePath(filePath)
    , m_renderer(filePath)
    , m_window(nullptr)
{
    QFile tiles(filePath + ".txt");
    if (tiles.exists() && tiles.open(QIODevice::ReadOnly)) {
        auto info = tiles.readLine();
        while (!info.isEmpty()) {
            if (info.endsWith('\n'))
                info.chop(1);
            auto parts = info.split(';');
            if (parts.size() != 4) {
                qCWarning(lcMapRenderer) << tiles.fileName() << "looks malformed, wrong number of parts";
                return;
            }
            bool ok = false;
            qreal scale = parts.at(1).toFloat(&ok);
            if (!ok) {
                qCWarning(lcMapRenderer) << tiles.fileName() << "looks malformed," << parts.at(1) << "is not a float";
                return;
            }
            int width = parts.at(2).toInt(&ok);
            if (!ok) {
                qCWarning(lcMapRenderer) << tiles.fileName() << "looks malformed," << parts.at(2) << "is not an integer";
                return;
            }
            int height = parts.at(3).toInt(&ok);
            if (!ok) {
                qCWarning(lcMapRenderer) << tiles.fileName() << "looks malformed," << parts.at(3) << "is not an integer";
                return;
            }
            m_tiles.emplace(std::piecewise_construct, std::forward_as_tuple(scale), std::forward_as_tuple(QFileInfo(filePath).dir().absoluteFilePath(parts.at(0)), QSize(width, height)));
            qCDebug(lcMapRenderer).nospace() << "Pushed tiles of scale " << scale << ", width: " << width << ", height: " << height << " into tile set";
            info = tiles.readLine();
        }
    } else {
        qCDebug(lcMapRenderer) << "Could not read tiles info file from" << tiles.fileName() << ", error" << tiles.error();
    }
}

void MapRenderer::windowChanged(QQuickWindow *window)
{
    m_window = window;
}

QQuickWindow *MapRenderer::getWindow()
{
    return m_window;
}

MapRenderer::Tiles::Tiles(const QString &pathTemplate, const QSize &dimensions)
    : pathTemplate(pathTemplate)
    , dimensions(dimensions)
{
}

const MapRenderer::Tiles &MapRenderer::getTilesForScaling(const QSize &target, const QSizeF &original) const
{
    QSizeF worldSize = m_renderer.boundsOnElement("world").size();
    QSizeF documentSize = m_renderer.defaultSize();
    qreal scale_x = target.width() / original.width() * (worldSize.width() / documentSize.width());
    qreal scale_y = target.height() / original.height() * (worldSize.height() / documentSize.height());
    if (abs(scale_x - scale_y) > 0.01)
        qCWarning(lcMapRenderer) << "Different x and y scaling:" << scale_x << "and" << scale_y;
    qreal scale = (scale_x + scale_y) / (qreal)2.0;
    qCDebug(lcMapRenderer) << "Scaling is" << scale;

    auto it = m_tiles.cbegin();
    while (it != m_tiles.cend() && scale > it->first) {
        std::advance(it, 1);
    }
    if (it == m_tiles.cend()) {
        auto last = m_tiles.crbegin();
        qCDebug(lcMapRenderer) << "Falling back to best quality tiles with scaling" << last->first;
        return last->second;
    }
    qCDebug(lcMapRenderer) << "Selecting tiles for scaling" << it->first;
    return it->second;
}

TileRenderer::TileRenderer(const QString &path, const QRectF &rect, const QTransform &translation, const QTransform &scaling, MapRenderer *parent)
    : QObject(parent)
    , m_path(path)
    , m_rect(rect)
    , m_translation(translation)
    , m_scaling(scaling)
{
}

void TileRenderer::run()
{
    QRectF transformed = m_scaling.mapRect(m_translation.mapRect(m_rect));
    QImage tile = QImage(m_path).convertToFormat(QImage::Format_ARGB32_Premultiplied).scaled(transformed.size().toSize());

    QSGTexture *texture = getMapRenderer()->getWindow()->createTextureFromImage(tile);
    emit renderingReady(MapRenderer::TileRendered, texture, transformed);
}

OverlayRenderer::OverlayRenderer(QSvgRenderer &renderer, const QRectF &rect, const QColor &color, const QTransform &translation, const QTransform &scaling, const QString &code, MapRenderer *parent)
    : QObject(parent)
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

    QSGTexture *texture = getMapRenderer()->getWindow()->createTextureFromImage(overlay);
    emit renderingReady(MapRenderer::OverlayRendered, texture, transformed);
}