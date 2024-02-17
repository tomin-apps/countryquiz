/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#include <QLoggingCategory>
#include <QQuickWindow>
#include <QSGClipNode>
#include <QSGSimpleTextureNode>
#include <sailfishapp.h>

#include "map.h"
#include "maprenderer.h"

Q_LOGGING_CATEGORY(lcMap, "site.tomin.apps.CountryQuiz.Map", QtWarningMsg)

Map::Map(QQuickItem *parent)
    : QQuickItem(parent)
    , m_dirty(true)
    , m_load(true)
    , m_renderingReady(false)
    , m_renderer(MapRenderer::get(SailfishApp::pathTo("assets/map.svg").toLocalFile()))
    , m_window(nullptr)
{
    setFlag(QQuickItem::ItemHasContents);
    connect(this, &Map::renderMap, m_renderer, &MapRenderer::renderMap, Qt::QueuedConnection);
    connect(this, &QQuickItem::windowChanged, this, [this](QQuickWindow *window) {
        if (m_window)
            m_window->disconnect(this);
        if (window) {
            connect(window, &QQuickWindow::sceneGraphInitialized, this, &Map::drawAgain);
            connect(window, &QQuickWindow::sceneGraphInvalidated, this, [this]() {
                m_renderingReady = false;
                m_tiles.clear();
                m_overlay.texture.reset();
            });
        }
        m_window = window;
    });
    connect(this, &QQuickItem::windowChanged, m_renderer, &MapRenderer::windowChanged);
}

void Map::drawAgain()
{
    m_renderingReady = false;
    emit renderMap(m_sourceSize, m_code);
}

void Map::componentComplete()
{
    QQuickItem::componentComplete();
    emit windowChanged(window());
    if (canDraw())
        drawAgain();
}

void Map::updatePolish()
{
    if (texturesReady()) {
        setImplicitWidth(m_sourceSize.width());
        setImplicitHeight(m_sourceSize.height());
        m_dirty = true;
        qCDebug(lcMap) << "Polish done";
        update();
    }
}

QSGNode *Map::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    if (!texturesReady())
        return nullptr; // not ready

    auto *node = static_cast<QSGClipNode *>(oldNode);
    if (!node || m_dirty) {
        if (!node) {
            node = new QSGClipNode;
            node->setIsRectangular(true);
        }
        node->removeAllChildNodes();
        for (const Tile &tile : m_tiles) {
            auto *tileNode = new QSGSimpleTextureNode;
            tileNode->setTexture(tile.texture.data());
            tileNode->setRect(tile.location);
            node->appendChildNode(tileNode);
        }
        auto *overlayNode = new QSGSimpleTextureNode;
        overlayNode->setTexture(m_overlay.texture.data());
        overlayNode->setRect(m_overlay.location);
        node->appendChildNode(overlayNode);
        m_dirty = false;
    }

    node->setClipRect(boundingRect());
    qCDebug(lcMap) << "Update done";
    return node;
}

QString Map::code() const
{
    return m_code;
}

void Map::setCode(const QString &code)
{
    if (m_code != code) {
        m_code = code;
        emit codeChanged();
        if (canDraw())
            drawAgain();
    }
}

bool Map::load() const
{
    return m_load;
}

void Map::setLoad(bool load)
{
    if (m_load != load) {
        m_load = load;
        emit loadChanged();
        if (canDraw())
            drawAgain();
    }
}

void Map::setSourceSize(const QSize &sourceSize)
{
    if (m_sourceSize != sourceSize) {
        m_sourceSize = sourceSize;
        emit sourceSizeChanged();
        if (canDraw())
            drawAgain();
    }
}

const QSize &Map::sourceSize() const
{
    return m_sourceSize;
}

void Map::renderingReady(MapRenderer::MessageType message, QSGTexture *texture, const QRectF &tile)
{
    qCDebug(lcMap) << "Got" << (message == MapRenderer::TileRendered ? "tile" : message == MapRenderer::OverlayRendered ? "overlay" : "done") << "message";
    m_dirty = true;
    if (message == MapRenderer::TileRendered) {
        m_tiles.emplace_back(std::move(Tile(texture, tile)));
    } else if (message == MapRenderer::OverlayRendered) {
        m_overlay.texture.reset(texture);
        m_overlay.location = tile;
    } else /*message == MapRenderer::RenderingDone */ {
        m_renderingReady = true;
    }
    if (m_renderingReady)
        polish();
}

bool Map::canDraw() const
{
    return isComponentComplete() && m_load && m_sourceSize.isValid() && !m_code.isEmpty();
}

bool Map::texturesReady() const
{
    if (!m_renderingReady)
        return false;
    if (!m_overlay.texture)
        return false;
    for (const Tile &tile : m_tiles) {
        if (!tile.texture)
            return false;
    }
    return true;
}

Map::Tile::Tile(QSGTexture *texture, const QRectF &location)
    : texture(texture)
    , location(location)
{
}

Map::Tile::Tile(Tile &&other)
    : location(other.location)
{
    texture.reset(other.texture.take());
}