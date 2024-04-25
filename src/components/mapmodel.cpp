/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#include <QLoggingCategory>
#include <QUrl>
#include <sys/sysinfo.h>
#include "mapmodel.h"
#include "maprenderer.h"

Q_LOGGING_CATEGORY(lcMapModel, "site.tomin.apps.CountryQuiz.MapModel", QtWarningMsg)

MapModel::MapModel(QQuickItem *parent)
    : QQuickItem(parent)
    , m_inverted(false)
{
    m_thread.setObjectName("MapRendererThread");
    connect(QCoreApplication::instance(), &QCoreApplication::aboutToQuit, [this]() {
        m_thread.quit();
        m_thread.wait();
    });
    m_thread.start();
    qCInfo(lcMapModel) << "Setup for rendering thread completed";
    qCDebug(lcMapModel) << "Cores:" << get_nprocs() << "cores online," << get_nprocs_conf() << "cores configured";
}

const QString &MapModel::mapFile() const
{
    return m_mapFile;
}

void MapModel::setMapFile(const QString &mapFile)
{
    if (m_mapFile != mapFile) {
        m_mapFile = mapFile;
        emit mapFileChanged();
        if (isComponentComplete())
            setupRenderer();
    }
}

const QSize &MapModel::miniMapSize() const
{
    return m_miniMapSize;
}

void MapModel::setMiniMapSize(const QSize &miniMapSize)
{
    if (m_miniMapSize != miniMapSize) {
        m_miniMapSize = miniMapSize;
        emit miniMapSizeChanged();
        if (m_renderer)
            drawMiniMap();
    }
}

bool MapModel::invertedColors() const
{
    return m_inverted;
}

void MapModel::setInvertedColors(bool inverted)
{
    if (m_inverted != inverted) {
        m_inverted = inverted;
        emit invertedColorsChanged();
        m_miniMap = QImage();
        emit miniMapChanged();
        if (m_renderer)
            drawMiniMap();
    }
}

MapRenderer *MapModel::renderer()
{
    return m_renderer.data();
}

void MapModel::componentComplete()
{
    if (!m_mapFile.isEmpty())
        setupRenderer();
}

QSGTexture *MapModel::miniMap() const
{
    return !m_miniMap.isNull() && window() ? window()->createTextureFromImage(m_miniMap) : nullptr;
}

QRectF MapModel::miniMapBounds(const QString &code, qreal aspectRatio) const
{
    if (m_renderer && !m_miniMap.isNull()) {
        QRectF fullArea = m_renderer->fullArea();
        QRectF bounds = m_renderer->calculateBounds(code, aspectRatio);
        QTransform translation = QTransform::fromTranslate(-fullArea.left(), -fullArea.top());
        QTransform scaling = QTransform::fromScale(static_cast<qreal>(m_miniMap.width()) / fullArea.width(), static_cast<qreal>(m_miniMap.height()) / fullArea.height());
        return scaling.mapRect(translation.mapRect(bounds));
    }
    return QRectF();
}

void MapModel::fullMapReady(const QImage &map)
{
    m_miniMap = map;
    emit miniMapChanged();
}

void MapModel::setupRenderer()
{
    MapRenderer *renderer = new MapRenderer(QUrl(m_mapFile).toLocalFile());
    renderer->moveToThread(&m_thread);
    connect(&m_thread, &QThread::finished, renderer, [this, renderer] {
        if (m_renderer.data() == renderer)
            m_renderer.reset();
    });
    connect(this, &MapModel::renderFullMap, renderer, &MapRenderer::renderFullMap, Qt::QueuedConnection);
    connect(this, &QQuickItem::windowChanged, renderer, &MapRenderer::windowChanged);
    m_renderer.reset(renderer);
    emit windowChanged(window());
    qCDebug(lcMapModel) << "Created new renderer for" << m_mapFile;
    emit rendererChanged();

    if (m_miniMapSize.isValid())
        drawMiniMap();
}

void MapModel::drawMiniMap()
{
    emit renderFullMap(m_miniMapSize, m_inverted);
}