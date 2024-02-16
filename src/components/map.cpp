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
    , m_tileCount(-1)
    , m_renderer(MapRenderer::get(SailfishApp::pathTo("assets/map.svg").toLocalFile()))
    , m_window(nullptr)
{
    setFlag(QQuickItem::ItemHasContents);
    connect(this, &Map::renderMap, m_renderer, &MapRenderer::renderMap);
    connect(m_renderer, &MapRenderer::tileCountReady, this, &Map::tileCountReady);
    connect(m_renderer, &MapRenderer::tileReady, this, &Map::tileReady);
    connect(m_renderer, &MapRenderer::overlayReady, this, &Map::overlayReady);
    connect(this, &QQuickItem::windowChanged, this, [this](QQuickWindow *window) {
        if (m_window)
            m_window->disconnect(this);
        if (window) {
            connect(window, &QQuickWindow::sceneGraphInitialized, this, &Map::createMapTextures);
            connect(window, &QQuickWindow::sceneGraphInvalidated, this, [this]() {
                for (Tile &tile : m_tiles) {
                    tile.texture.reset();
                }
                m_overlay.texture.reset();
            });
        }
        m_window = window;
    });
}

void Map::componentComplete()
{
    QQuickItem::componentComplete();
    if (canDraw())
        emit renderMap(m_sourceSize, m_code);
}

void Map::createMapTextures()
{
    // TODO: shouldn't always iterate everything
    for (Tile &tile : m_tiles) {
        if (!tile.image.isNull()) {
            if (!tile.texture)
                tile.texture.reset(window()->createTextureFromImage(tile.image));
        }
    }
    if (!m_overlay.image.isNull()) {
        if (!m_overlay.texture)
            m_overlay.texture.reset(window()->createTextureFromImage(m_overlay.image));
    }

    if (texturesReady())
        polish();
}

void Map::updatePolish()
{
    if (texturesReady()) { // TODO: Check that textures are there!
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
            emit renderMap(m_sourceSize, m_code);
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
            emit renderMap(m_sourceSize, m_code);
    }
}

void Map::setSourceSize(const QSize &sourceSize)
{
    if (m_sourceSize != sourceSize) {
        m_sourceSize = sourceSize;
        emit sourceSizeChanged();
        if (canDraw())
            emit renderMap(m_sourceSize, m_code);
    }
}

const QSize &Map::sourceSize() const
{
    return m_sourceSize;
}

void Map::tileCountReady(const QSize &size, const QSize &tiles, const QString &code)
{
    if (m_code == code && m_sourceSize == size) {
        m_tiles.clear();
        m_tileCount = tiles.width() * tiles.height();
    }
}

void Map::tileReady(const QImage &image, const QRectF &tile, const QString &code)
{
    if (m_code == code) {
        m_tiles.emplace_back(std::move(Tile(image, tile)));
        createMapTextures(); // TODO: inefficient
    }
}

void Map::overlayReady(const QImage &image, const QRectF &tile, const QString &code)
{
    if (m_code == code) {
        m_overlay.image = image;
        m_overlay.location = tile;
        createMapTextures(); // TODO: inefficient
    }
}

bool Map::canDraw() const
{
    return isComponentComplete() && m_load && m_sourceSize.isValid() && !m_code.isEmpty();
}

bool Map::texturesReady() const
{
    if (m_tileCount == -1 || (int)m_tiles.size() < m_tileCount)
        return false;

    for (const Tile &tile : m_tiles) {
        if (!tile.texture)
            return false;
    }
    return m_overlay.texture;
}

Map::Tile::Tile(const QImage &image, const QRectF &location)
    : image(image)
    , location(location)
{
}

Map::Tile::Tile(Tile &&other)
    : image(other.image)
    , location(other.location)
{
    texture.reset(other.texture.take());
}