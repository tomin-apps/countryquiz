/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#include <QLoggingCategory>
#include <QQuickWindow>
#include <QSGSimpleTextureNode>
#include <sailfishapp.h>

#include "map.h"
#include "mapmodel.h"
#include "maprenderer.h"

Q_LOGGING_CATEGORY(lcMap, "site.tomin.apps.CountryQuiz.Map", QtWarningMsg)
Q_LOGGING_CATEGORY(lcMapElapsed, "site.tomin.apps.CountryQuiz.Map.Elapsed", QtWarningMsg)

namespace {
    class TextureCleaningJob : public QRunnable
    {
    public:
        TextureCleaningJob(std::vector<QSGTexture *> textures)
            : textures(textures)
        {
            setAutoDelete(true);
        }

        void run() override
        {
            qCDebug(lcMap) << "Destroying" << textures.size() << "textures";
            for (QSGTexture *texture : textures)
                delete texture;
            textures.clear();
        }
    private:
        std::vector<QSGTexture *> textures;
    };
}

Map::Map(QQuickItem *parent)
    : QQuickItem(parent)
    , m_mapModel(nullptr)
    , m_overlayColor(Qt::red)
    , m_dirty(true)
    , m_renderer(nullptr)
    , m_window(window())
    , m_ready(NothingReady)
{
    setFlag(QQuickItem::ItemHasContents);
    connect(this, &QQuickItem::windowChanged, this, [this](QQuickWindow *window) {
        if (m_window)
            m_window->disconnect(this);
        if (window) {
            connect(window, &QQuickWindow::sceneGraphInitialized, this, &Map::renderAgain);
            connect(window, &QQuickWindow::sceneGraphInvalidated, this, &Map::releaseResources);
        }
        m_window = window;
    });
    if (m_window) {
        connect(m_window, &QQuickWindow::sceneGraphInitialized, this, &Map::renderAgain);
        connect(m_window, &QQuickWindow::sceneGraphInvalidated, this, &Map::releaseResources);
    }
}

Map::~Map()
{
    // Hopefully Qt has done its job and releaseResources() has been called
    for (QSGTexture *ptr : m_abandoned)
        delete ptr;
    m_abandoned.clear();
}

void Map::releaseResources()
{
    m_ready = NothingReady;
    m_abandoned.reserve(m_abandoned.size() + m_tiles.size() + 3);
    for (Tile &tile : m_tiles)
        m_abandoned.push_back(tile.texture.take());
    m_tiles.clear();
    m_abandoned.push_back(m_overlay.texture.take());
    m_abandoned.push_back(m_miniMap.texture.take());
    cleanupTextures();
}

void Map::renderAgain()
{
    if (lcMapElapsed().isDebugEnabled()) {
        auto *renderingTimer = new RenderingTimer;
        connect(this, &Map::renderingProgressed, renderingTimer, [this, renderingTimer](MapRenderer::MessageType message, int count) {
            const char *msg;
            switch (message) {
                case MapRenderer::TileRendered: msg = "Rendered tile"; break;
                case MapRenderer::OverlayRendered: msg = "Rendered overlay"; break;
                case MapRenderer::RenderingDone: msg = "Rendering finished"; break;
            }

            qCDebug(lcMapElapsed).nospace() << msg << " for " << m_code << ", count: " << count << ", elapsed: " << renderingTimer->elapsed() << "ms";
            if (message == MapRenderer::RenderingDone) {
                disconnect(this, 0, renderingTimer, 0);
                renderingTimer->deleteLater();
            }
        });
        renderingTimer->start();
    }
    releaseResources();
    setTexture(m_miniMap.texture, m_mapModel->miniMap());

    emit renderMap(m_sourceSize, m_code, m_overlayColor);
}

void Map::rendererChanged()
{
    if (m_renderer) {
        disconnect(this, 0, m_renderer, 0);
    }
    m_renderer = m_mapModel ? m_mapModel->renderer() : nullptr;
    if (m_renderer) {
        connect(this, &Map::renderMap, m_renderer, &MapRenderer::renderMap, Qt::QueuedConnection);
        if (canRender())
            renderAgain();
    }
}

void Map::componentComplete()
{
    QQuickItem::componentComplete();
    if (m_sourceSize.isValid()) {
        setImplicitWidth(m_sourceSize.width());
        setImplicitHeight(m_sourceSize.height());
    }
    if (canRender())
        renderAgain();
}

namespace {
    qreal getScale(const QSizeF &a, const QSizeF &b)
    {
        return (a.width() / b.width() + a.height() / b.height()) / 2;
    }

    QRectF miniMapSourceRect(const QSizeF &texture, const QRectF &location)
    {
        qreal height = texture.height() * 2 / 3;
        if (height < location.height())
            height = location.height();
        if (height < location.width())
            height = location.width();
        QRectF rect(0, 0, height, height);
        rect.moveCenter(location.center());
        if (rect.top() < 0)
            rect.moveTop(0);
        if (rect.bottom() > texture.height())
            rect.moveBottom(texture.height());
        return rect;
    }

    QRectF miniMapRect(const QRectF &item, const QSizeF &texture)
    {
        return QRectF(QPointF(0, 0), texture.scaled(item.size() / 4, Qt::KeepAspectRatio));
    }

    QRectF getSubtractedArea(const QRectF &a, const QRectF &b, bool atBottom)
    {
        QRectF area(a);
        if (atBottom) {
            area.setTop(b.bottom());
        } else {
            area.setLeft(b.right());
            if (area.bottom() > b.bottom())
                area.setBottom(b.bottom());
        }
        return area;
    }

    QRectF adjustedBy(const QRectF &rect, qreal left, qreal top, qreal right, qreal bottom)
    {
        return QRectF(QPointF(rect.left() + rect.width() * left, rect.top() + rect.height() * top),
                      QPointF(rect.right() + rect.width() * right, rect.bottom() + rect.height() * bottom));
    }

    QRectF unifiedRect(const QRectF &first, const QRectF &second)
    {
        return !second.isValid() ? first : first.united(second);
    }
} // namespace

void Map::updatePolish()
{
    if (!(m_ready & MinimapReady) && m_miniMap.texture) {
        QRectF rect = boundingRect();
        m_miniMap.location = m_mapModel->miniMapBounds(m_code, rect.width() / rect.height());
        if (m_miniMap.location.isValid()) {
            m_ready |= MinimapReady;
            QSizeF textureSize = m_miniMap.texture->textureSize();
            QRectF miniMapSource = miniMapSourceRect(textureSize, m_miniMap.location);
            QRectF miniMapTarget = miniMapRect(boundingRect(), miniMapSource.size());
            m_miniMap.rect[0].source = miniMapSource;
            m_miniMap.rect[0].target = miniMapTarget;
            if (m_miniMap.rect[0].source.left() < 0) {
                m_miniMap.rect[0].source.setLeft(0);
                m_miniMap.rect[1].source = miniMapSource;
                m_miniMap.rect[1].source.setRight(0);
                m_miniMap.rect[1].source.moveRight(textureSize.width());
                m_miniMap.rect[1].target = miniMapTarget;
                m_miniMap.rect[1].target.setSize(m_miniMap.rect[1].source.size().scaled(m_miniMap.rect[1].target.size(), Qt::KeepAspectRatio));
                m_miniMap.rect[0].target.setSize(m_miniMap.rect[0].source.size().scaled(m_miniMap.rect[0].target.size(), Qt::KeepAspectRatio));
                m_miniMap.rect[0].target.moveLeft(m_miniMap.rect[1].target.right());
            } else if (m_miniMap.rect[0].source.right() > textureSize.width()) {
                m_miniMap.rect[0].source.setRight(textureSize.width());
                m_miniMap.rect[1].source = miniMapSource;
                m_miniMap.rect[1].source.setLeft(textureSize.width());
                m_miniMap.rect[1].source.moveLeft(0);
                m_miniMap.rect[1].target = miniMapTarget;
                m_miniMap.rect[0].target.setSize(m_miniMap.rect[0].source.size().scaled(m_miniMap.rect[0].target.size(), Qt::KeepAspectRatio));
                m_miniMap.rect[1].target.setSize(m_miniMap.rect[1].source.size().scaled(m_miniMap.rect[1].target.size(), Qt::KeepAspectRatio));
                m_miniMap.rect[1].target.moveLeft(m_miniMap.rect[0].target.right());
            } else {
                m_miniMap.rect[1].source = QRectF();
                m_miniMap.rect[1].target = QRectF();
            }
            qreal scale = getScale(miniMapTarget.size(), miniMapSource.size());
            QRectF bounds((m_miniMap.location.topLeft() - miniMapSource.topLeft()) * scale, m_miniMap.location.size() * scale);
            m_miniMap.bounds = miniMapTarget.intersected(bounds);

            m_fastMap[0].target = adjustedBy(boundingRect(), 0.25, 0, 0, 0.25);
            m_fastMap[0].source = adjustedBy(m_miniMap.location, 0.25, 0, 0, 0.25);
            m_fastMap[1].target = adjustedBy(boundingRect(), 0, 0.25, 0, 0);
            m_fastMap[1].source = adjustedBy(m_miniMap.location, 0, 0.25, 0, 0);
        }
    }
    if (m_overlay.texture)
        m_ready |= OverlayReady;
    if ((m_ready & RenderingReady) && !(m_ready & TilesReady) && !m_tiles.empty()) {
        QRectF bounds = boundingRect();
        for (Tile &tile : m_tiles) {
            QRectF targetRect = bounds.intersected(tile.location);
            QRectF sourceRect = QRectF(QPointF(targetRect.left() - tile.location.left(), targetRect.top() - tile.location.top()), targetRect.size());
            QRectF miniMapTarget = unifiedRect(m_miniMap.rect[0].target, m_miniMap.rect[1].target);
            if (!tile.location.intersects(miniMapTarget)) {
                tile.rects[0].target = targetRect;
                tile.rects[0].source = sourceRect;
                tile.parts = SinglePart;
            } else {
                tile.parts = Hidden;
                if (targetRect.right() > miniMapTarget.right()) {
                    QRectF rect = getSubtractedArea(targetRect, miniMapTarget, false);
                    tile.rects[0].target = rect;
                    rect.moveTo(sourceRect.topLeft() + rect.topLeft() - targetRect.topLeft());
                    tile.rects[0].source = rect;
                    tile.parts = SinglePart;
                }
                if (targetRect.bottom() > miniMapTarget.bottom()) {
                    QRectF rect = getSubtractedArea(targetRect, miniMapTarget, true);
                    tile.rects[tile.parts].target = rect;
                    rect.moveTo(sourceRect.topLeft() + rect.topLeft() - targetRect.topLeft());
                    tile.rects[tile.parts].source = rect;
                    tile.parts = tile.parts == SinglePart ? SplitParts : SinglePart;
                }
            }
        }
        m_ready |= TilesReady;
    }
    if ((m_ready & MinimapReady) && (m_ready & OverlayReady)) {
        qCDebug(lcMap) << "Polish done";
        update();
    }
    cleanupTextures();
}

namespace {
    template<typename T> T *getNextChildNode(QSGNode *parent, QSGNode *previous)
    {
        T *node;
        QSGNode *next = previous ? previous->nextSibling() : parent->firstChild();
        while (next) { // TODO: Instead of removing this could insert before
            node = dynamic_cast<T *>(next);
            if (node)
                break;
            QSGNode *sibling = next->nextSibling();
            parent->removeChildNode(next); // O(N) => O(N^2)???
            delete next;
            next = sibling;
        }
        if (!next) {
            node = new T;
            parent->appendChildNode(node);
        }
        return node;
    }

    QSGNode *drawRectangle(QSGNode *parent, QSGNode *previous, const QRectF &rect, const QColor &color, qreal border)
    {
        // Left side
        auto *node = getNextChildNode<QSGSimpleRectNode>(parent, previous);
        node->setColor(color);
        node->setRect(rect.left(), rect.top(), border, rect.bottom() - rect.top());

        // Top side
        node = getNextChildNode<QSGSimpleRectNode>(parent, node);
        node->setColor(color);
        node->setRect(rect.left() + border, rect.top(), rect.right() - rect.left() - 2 * border, border);

        // Right side
        node = getNextChildNode<QSGSimpleRectNode>(parent, node);
        node->setColor(color);
        node->setRect(rect.right() - border, rect.top(), border, rect.bottom() - rect.top());

        // Bottom side
        node = getNextChildNode<QSGSimpleRectNode>(parent, node);
        node->setColor(color);
        node->setRect(rect.left() + border, rect.bottom() - border, rect.right() - rect.left() - 2 * border, border);

        return node;
    }

    QColor opaqueColor(const QColor &color)
    {
        QColor result(color);
        result.setAlphaF(1);
        return result;
    }
} // namespace

QSGNode *Map::updatePaintNode(QSGNode *node, UpdatePaintNodeData *)
{
    if (!((m_ready & MinimapReady) && (m_ready & OverlayReady))) {
        delete node;
        return nullptr;
    }

    if (!node || m_dirty) {
        if (!node)
            node = new QSGNode;
        QSGNode *prevNode = nullptr;

        if (!(m_ready & TilesReady)) {
            auto *mapNode = getNextChildNode<QSGSimpleTextureNode>(node, prevNode);
            if (mapNode->texture() != m_miniMap.texture.data()) {
                mapNode->setTexture(m_miniMap.texture.data());
                mapNode->setRect(m_fastMap[0].target);
                mapNode->setSourceRect(m_fastMap[0].source);
            }
            mapNode = getNextChildNode<QSGSimpleTextureNode>(node, mapNode);
            if (mapNode->texture() != m_miniMap.texture.data()) {
                mapNode->setTexture(m_miniMap.texture.data());
                mapNode->setRect(m_fastMap[1].target);
                mapNode->setSourceRect(m_fastMap[1].source);
            }
            prevNode = mapNode;
        } else {
            for (const Tile &tile : m_tiles) {
                for (size_t part = Hidden; part < tile.parts; ++part) {
                    auto *tileNode = getNextChildNode<QSGSimpleTextureNode>(node, prevNode);
                    if (tileNode->texture() != tile.texture.data())
                        tileNode->setTexture(tile.texture.data());
                    tileNode->setRect(tile.rects[part].target);
                    tileNode->setSourceRect(tile.rects[part].source);
                    prevNode = tileNode;
                }
            }
        }

        auto *overlayNode = getNextChildNode<QSGSimpleTextureNode>(node, prevNode);
        if (overlayNode->texture() != m_overlay.texture.data()) {
            overlayNode->setTexture(m_overlay.texture.data());
            overlayNode->setRect(m_overlay.location);
            overlayNode->setSourceRect(QRectF());
        }

        auto *miniMapNode = getNextChildNode<QSGSimpleTextureNode>(node, overlayNode);
        if (miniMapNode->texture() != m_miniMap.texture.data()) {
            miniMapNode->setTexture(m_miniMap.texture.data());
            miniMapNode->setRect(m_miniMap.rect[0].target);
            miniMapNode->setSourceRect(m_miniMap.rect[0].source);
        }

        if (m_miniMap.rect[1].target.isValid()) {
            miniMapNode = getNextChildNode<QSGSimpleTextureNode>(node, miniMapNode);
            if (miniMapNode->texture() != m_miniMap.texture.data()) {
                miniMapNode->setTexture(m_miniMap.texture.data());
                miniMapNode->setRect(m_miniMap.rect[1].target);
                miniMapNode->setSourceRect(m_miniMap.rect[1].source);
            }
        }

        prevNode = drawRectangle(node, miniMapNode, unifiedRect(m_miniMap.rect[0].target, m_miniMap.rect[1].target), QColor(Qt::white), 2);
        prevNode = drawRectangle(node, prevNode, m_miniMap.bounds.toRect(), opaqueColor(m_overlayColor), 2);

        QSGNode *next = prevNode->nextSibling();
        while (next) {
            prevNode = next;
            next = prevNode->nextSibling();
            delete prevNode;
        }

        m_dirty = false;
    }

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
        if (canRender())
            renderAgain();
    }
}

void Map::setSourceSize(const QSize &sourceSize)
{
    if (m_sourceSize != sourceSize) {
        m_sourceSize = sourceSize;
        emit sourceSizeChanged();
        if (m_sourceSize.isValid()) {
            setImplicitWidth(m_sourceSize.width());
            setImplicitHeight(m_sourceSize.height());
        }
        if (canRender())
            renderAgain();
    }
}

const QSize &Map::sourceSize() const
{
    return m_sourceSize;
}

void Map::setModel(MapModel *mapModel)
{
    if (m_mapModel != mapModel) {
        m_mapModel = mapModel;
        if (m_mapModel)
            connect(m_mapModel, &MapModel::rendererChanged, this, &Map::rendererChanged, Qt::QueuedConnection);
        emit modelChanged();
        rendererChanged();
        miniMapChanged();
    }
}

QColor Map::overlayColor() const
{
    return m_overlayColor;
}

void Map::setOverlayColor(const QColor &color)
{
    if (m_overlayColor != color) {
        m_overlayColor = color;
        emit overlayColorChanged();
    }
}

MapModel *Map::model() const
{
    return m_mapModel;
}

void Map::renderingReady(MapRenderer::MessageType message, QSGTexture *texture, const QRectF &tile)
{
    if (lcMapElapsed().isDebugEnabled()) {
        emit renderingProgressed(message, m_tiles.size() + (m_overlay.texture ? 1 : 0));
    }
    m_dirty = true;
    if (message == MapRenderer::TileRendered) {
        m_tiles.emplace_back(texture, tile);
    } else if (message == MapRenderer::OverlayRendered) {
        bool second = m_overlay.texture;
        setTexture(m_overlay.texture, texture);
        m_overlay.location = tile;
        if (second)
            qCDebug(lcMap) << "Replaced overlay texture with new version";
        m_ready |= OverlayPending;
    } else /* message == MapRenderer::RenderingDone */ {
        m_ready |= RenderingReady;
    }
    if ((m_ready & RenderingReady) || message == MapRenderer::OverlayRendered)
        polish();
}

void Map::miniMapChanged()
{
    if (m_mapModel && !m_code.isEmpty()) {
        m_dirty = true;
        setTexture(m_miniMap.texture, m_mapModel->miniMap());
        if (m_miniMap.texture)
            qCDebug(lcMap) << "Mini map received";
        if (m_ready & OverlayPending)
            polish();
    }
}

bool Map::canRender() const
{
    return isComponentComplete() && m_mapModel && m_renderer && m_sourceSize.isValid() && !m_code.isEmpty();
}

void Map::setTexture(QScopedPointer<QSGTexture> &ptr, QSGTexture *texture)
{
    if (ptr)
        m_abandoned.push_back(ptr.take());
    ptr.reset(texture);
}

void Map::cleanupTextures()
{
    if (!m_abandoned.empty() && window()) {
        std::vector<QSGTexture *> textures;
        textures.swap(m_abandoned);
        window()->scheduleRenderJob(new TextureCleaningJob(textures), QQuickWindow::AfterRenderingStage);
    }
}

Map::Tile::Tile(QSGTexture *texture, const QRectF &location)
    : texture(texture)
    , location(location)
    , parts(Hidden)
{
}

Map::Tile::Tile(Tile &&other)
    : texture(other.texture.take())
    , location(other.location)
    , rects(other.rects)
    , parts(other.parts)
{
}

RenderingTimer::RenderingTimer(QObject *parent)
    : QObject(parent)
{
}