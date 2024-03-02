/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#include <algorithm>
#include <cassert>
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
#include "mapmodel.h"
#include "maprenderer.h"

/* TODO
 * - Use theme colour
 * - Light theme support
 * - Circle tiny islands and city states that would be otherwise invisible
 */

Q_LOGGING_CATEGORY(lcMapRenderer, "site.tomin.apps.CountryQuiz.MapRenderer", QtWarningMsg)

#define IMAGE_FORMAT QImage::Format_RGBA8888_Premultiplied

namespace {
    const qreal CircleLimit = 250;
    const qreal CircleMinimumWidth = 20;
    const qreal CirclePenWidth = 2.0;
    const qreal CircleScalingFactor = 355.0 / 113.0;
    const qreal FastScalingFactor = 0.25;
    const QString SubElementTemplate = QStringLiteral("%1-%2");

    int mod(int x, int y) {
        return x >= 0 ? x % y : (y + x) % y;
    }

    QRectF adjusted_area(const QRectF &target, const QRectF &fullArea, qreal minArea, qreal aspectRatio)
    {
        QSizeF size(target.size() * 1.25);
        if (target.width() < minArea * fullArea.width()) {
            size.setWidth(minArea * fullArea.width());
        }
        size = QSizeF(aspectRatio, 1).scaled(size, Qt::KeepAspectRatioByExpanding);
        qreal width = target.width() / size.width();
        qreal height = target.height() / size.height();
        if (width > 0.5 && height > 0.5) {
            if (width > height) {
                size.scale(QSizeF(target.width() * 2, size.height()), Qt::KeepAspectRatioByExpanding);
            } else {
                size.scale(QSizeF(size.width(), target.height() * 2), Qt::KeepAspectRatioByExpanding);
            }
        }
        QRectF bounds(QPointF(), size);
        bounds.moveCenter(target.center());
        return bounds;
    }

    QRectF get_union_of_rects(const std::vector<QRectF> rects)
    {
        QRectF united;
        for (const QRectF &rect : rects) {
            united = united.united(rect);
        }
        return united;
    }

    QRectF get_circle(const QRectF &rect)
    {
        QRectF circle;
        circle.setSize(QSizeF(1, 1).scaled(rect.size(), Qt::KeepAspectRatioByExpanding) * CircleScalingFactor);
        if (circle.width() < CircleMinimumWidth)
            circle.setSize(QSizeF(CircleMinimumWidth, CircleMinimumWidth));
        circle.moveCenter(rect.center());
        return circle;
    }

    std::vector<QRectF> get_circles_locked(QSvgRenderer &renderer, const QString &code, const QTransform &scaling, const QTransform &translation, const QRectF &element)
    {
        std::vector<QRectF> circles;
        if (element.width() * element.height() < CircleLimit) {
            circles.push_back(scaling.mapRect(translation.mapRect(get_circle(element))));
        } else {
            for (int i = 1; renderer.elementExists(SubElementTemplate.arg(code).arg(i)); ++i) {
                QString subCode = SubElementTemplate.arg(code).arg(i);
                QMatrix matrix = renderer.matrixForElement(subCode);
                QRectF subElement = matrix.mapRect(renderer.boundsOnElement(subCode));
                if (subElement.width() * subElement.height() < CircleLimit)
                    circles.push_back(scaling.mapRect(translation.mapRect(get_circle(subElement))));
            }
        }
        return circles;
    }

    QImage draw_overlay_locked(QSvgRenderer &renderer, const QString &code, const QSizeF &size, const QColor &color)
    {
        QImage overlay(size.toSize(), IMAGE_FORMAT);
        overlay.fill(color);

        QImage element(size.toSize(), IMAGE_FORMAT);
        element.fill(Qt::transparent);
        QPainter elementPainter(&element);
        renderer.render(&elementPainter, code);

        QPainter overlayPainter(&overlay);
        overlayPainter.setCompositionMode(QPainter::CompositionMode_DestinationIn);
        overlayPainter.drawImage(QPoint(0, 0), element);
        return overlay;
    }

    QImage draw_circles_to_overlay_locked(const QImage &overlay, QRectF &transformed, const QTransform &scaling, const std::vector<QRectF> &circles, const QColor &color)
    {
        QRectF united = transformed.united(get_union_of_rects(circles));
        united.adjust(-1, -1, 1, 1);

        QImage circled(scaling.mapRect(united).size().toSize(), IMAGE_FORMAT);
        circled.fill(Qt::transparent);
        QPainter painter(&circled);
        painter.drawImage(scaling.map(transformed.topLeft() - united.topLeft()), overlay);

        QColor penColor(color);
        penColor.setAlphaF(1);
        painter.setPen(QPen(penColor, CirclePenWidth));
        for (const QRectF &circle : circles) {
            QRectF target = scaling.mapRect(circle.translated(-united.topLeft()));
            qCDebug(lcMapRenderer).nospace() << "Drawing circle (d=" << target.width() << ") to " << target.center();
            painter.drawArc(target, 0, 5760);
        }

        transformed = united;
        return circled;
    }
} // namespace

QRectF MapRenderer::calculateBounds(const QString &code, qreal aspectRatio)
{
    QMutexLocker locker(&m_rendererMutex);
    QMatrix matrix = m_renderer.matrixForElement(code);
    QRectF element = matrix.mapRect(m_renderer.boundsOnElement(code));
    locker.unlock();
    return adjusted_area(element, m_fullArea, 0.05, aspectRatio);
}

QRectF MapRenderer::fullArea()
{
    return m_fullArea;
}

void MapRenderer::renderMap(const QSize &size, const QString &code, const QColor &overlayColor)
{
    Map *map = qobject_cast<Map *>(sender());
    assert(map);

    qreal aspectRatio = static_cast<qreal>(size.width()) / size.height();
    QRectF bounds = calculateBounds(code, aspectRatio);

    QTransform translation = QTransform::fromTranslate(-bounds.left(), -bounds.top());
    QTransform scaling = QTransform::fromScale(size.width() / bounds.width(), size.height() / bounds.height());
    const Tiles &tiles = getTilesForScaling(size, bounds.size());
    QSizeF tileSize(m_fullArea.width() / tiles.dimensions.width(), m_fullArea.height() / tiles.dimensions.height());

    QThreadPool pool;
    pool.setMaxThreadCount(get_nprocs_conf());

    auto *overlayRenderer = new OverlayRenderer(overlayColor, translation, scaling, code, true, this);
    connect(overlayRenderer, &OverlayRenderer::renderingReady, map, &Map::renderingReady, Qt::QueuedConnection);
    connect(overlayRenderer, &OverlayRenderer::renderingReady, this, [this, map, overlayColor, translation, scaling, code]{
        auto *overlayRenderer = new OverlayRenderer(overlayColor, translation, scaling, code, false, this);
        connect(overlayRenderer, &OverlayRenderer::renderingReady, map, &Map::renderingReady, Qt::QueuedConnection);
        overlayRenderer->setAutoDelete(true);
        QThreadPool::globalInstance()->start(overlayRenderer, QThread::LowPriority);
    });
    overlayRenderer->setAutoDelete(true);
    pool.start(overlayRenderer, QThread::HighPriority);

    QPoint position(std::floor((bounds.left() - m_fullArea.left()) / tileSize.width()), std::max((qreal)0.0, std::floor((bounds.top() - m_fullArea.top()) / tileSize.height())));
    QPointF point((qreal)position.x() * tileSize.width() + m_fullArea.left(), (qreal)position.y() * tileSize.height() + m_fullArea.top());
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
        position = QPoint(std::floor((bounds.left() - m_fullArea.left()) / tileSize.width()), position.y() + 1);
        point = QPointF((qreal)position.x() * tileSize.width() + m_fullArea.left(), point.y() + tileSize.height());
    }

    pool.waitForDone();
    QMetaObject::invokeMethod(map, "renderingReady", Qt::QueuedConnection, Q_ARG(MapRenderer::MessageType, RenderingDone), Q_ARG(QSGTexture *, nullptr), Q_ARG(QRectF, QRectF()));
}

void MapRenderer::renderFullMap(const QSize &maxSize)
{
    MapModel *mapModel = qobject_cast<MapModel *>(sender());
    assert(mapModel);

    QSize size = m_fullArea.size().scaled(maxSize, Qt::KeepAspectRatio).toSize();
    auto *renderer = new FullMapRenderer(size, this);
    connect(renderer, &FullMapRenderer::fullMapReady, mapModel, &MapModel::fullMapReady, Qt::QueuedConnection);
    renderer->setAutoDelete(true);
    QThreadPool::globalInstance()->start(renderer, QThread::HighPriority);
}

void MapRenderer::windowChanged(QQuickWindow *window)
{
    m_window = window;
}

MapRenderer::MapRenderer(const QString &filePath, QObject *parent)
    : QObject(parent)
    , m_mapFilePath(filePath)
    , m_renderer(filePath)
    , m_fullArea(m_renderer.boundsOnElement("world"))
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

std::pair<QMutex *, QSvgRenderer *> MapRenderer::accessRenderer()
{
    return std::make_pair(&m_rendererMutex, &m_renderer);
}

QQuickWindow *MapRenderer::window()
{
    return m_window;
}

MapRenderer::Tiles::Tiles(const QString &pathTemplate, const QSize &dimensions)
    : pathTemplate(pathTemplate)
    , dimensions(dimensions)
{
}

const MapRenderer::Tiles &MapRenderer::getTilesForScaling(const QSize &target, const QSizeF &original)
{
    QMutexLocker locker(&m_rendererMutex);
    QSizeF worldSize = m_renderer.boundsOnElement("world").size();
    QSizeF documentSize = m_renderer.defaultSize();
    locker.unlock();

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
        qCWarning(lcMapRenderer).nospace() << "Falling back to best quality tiles with scaling " << last->first
                                           << " (requested: " << scale << ")";
        return last->second;
    }
    qCDebug(lcMapRenderer) << "Selecting tiles for scaling" << it->first;
    return it->second;
}

TileRenderer::TileRenderer(const QString &path, const QRectF &rect, const QTransform &translation, const QTransform &scaling, MapRenderer *mapRenderer)
    : QObject(nullptr)
    , m_mapRenderer(mapRenderer)
    , m_path(path)
    , m_rect(rect)
    , m_translation(translation)
    , m_scaling(scaling)
{
}

void TileRenderer::run()
{
    if (!QFileInfo::exists(m_path))
        return;

    QRectF transformed = m_scaling.mapRect(m_translation.mapRect(m_rect));
    QImage tile = QImage(m_path).scaled(transformed.size().toSize()).convertToFormat(IMAGE_FORMAT);

    emit renderingReady(MapRenderer::TileRendered, m_mapRenderer->window()->createTextureFromImage(tile), transformed);
}

OverlayRenderer::OverlayRenderer(const QColor &color, const QTransform &translation, const QTransform &scaling, const QString &code, bool fast, MapRenderer *mapRenderer)
    : QObject(nullptr)
    , m_mapRenderer(mapRenderer)
    , m_color(color)
    , m_translation(translation)
    , m_scaling(scaling)
    , m_code(code)
    , m_drawScaling(fast ? QTransform::fromScale(FastScalingFactor, FastScalingFactor) : QTransform())
{
}

void OverlayRenderer::run()
{
    QRectF transformed;
    QImage overlay;

    std::pair<QMutex *, QSvgRenderer *> access = m_mapRenderer->accessRenderer();
    {
        QMutexLocker locker(access.first);
        QSvgRenderer &renderer = *access.second;

        QMatrix matrix = renderer.matrixForElement(m_code);
        QRectF element = matrix.mapRect(renderer.boundsOnElement(m_code));

        transformed = m_scaling.mapRect(m_translation.mapRect(element));
        overlay = draw_overlay_locked(renderer, m_code, m_drawScaling.mapRect(transformed).size(), m_color);

        std::vector<QRectF> circles = get_circles_locked(renderer, m_code, m_scaling, m_translation, element);
        if (!circles.empty())
            overlay = draw_circles_to_overlay_locked(overlay, transformed, m_drawScaling, circles, m_color);
    }

    emit renderingReady(MapRenderer::OverlayRendered, m_mapRenderer->window()->createTextureFromImage(overlay), transformed);
}

FullMapRenderer::FullMapRenderer(const QSize &size, MapRenderer *mapRenderer)
    : QObject(nullptr)
    , m_mapRenderer(mapRenderer)
    , m_size(size)
{
}

void FullMapRenderer::run()
{
    std::pair<QMutex *, QSvgRenderer *> access = m_mapRenderer->accessRenderer();
    QMutexLocker locker(access.first);
    QSvgRenderer &renderer = *access.second;

    QImage map(m_size, IMAGE_FORMAT);
    map.fill(Qt::transparent);
    QPainter painter(&map);

    QRectF viewBox = renderer.viewBoxF();
    renderer.setViewBox(m_mapRenderer->fullArea());
    renderer.render(&painter);
    renderer.setViewBox(viewBox);

    emit fullMapReady(map);
}