/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#include <QLoggingCategory>
#include <QQuickWindow>
#include <QSGSimpleTextureNode>
#include <sailfishapp.h>

#include "map.h"
#include "maprenderer.h"

Q_LOGGING_CATEGORY(lcMap, "site.tomin.apps.CountryQuiz.Map", QtWarningMsg)

Map::Map(QQuickItem *parent)
    : QQuickItem(parent)
    , m_dirty(true)
    , m_load(true)
    , m_renderer(MapRenderer::get(SailfishApp::pathTo("assets/map.svg").toLocalFile()))
    , m_window(nullptr)
{
    setFlag(QQuickItem::ItemHasContents);
    connect(this, &Map::renderMap, m_renderer, &MapRenderer::renderMap);
    connect(m_renderer, &MapRenderer::mapReady, this, &Map::mapReady);
    connect(this, &QQuickItem::windowChanged, this, [this](QQuickWindow *window) {
        if (m_window)
            m_window->disconnect(this);
        if (window) {
            connect(window, &QQuickWindow::sceneGraphInitialized, this, &Map::createMapTexture);
            connect(window, &QQuickWindow::sceneGraphInvalidated, this, [this]() {
                m_texture.pending.reset();
                m_texture.current.reset();
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

void Map::createMapTexture()
{
    if (!m_map.isNull()) {
        QSGTexture *texture = window()->createTextureFromImage(m_map);
        m_texture.pending.reset(texture);
        polish();
    }
}

void Map::updatePolish()
{
    if (m_texture.pending) {
        QSize size = m_map.size();
        setImplicitWidth(size.width());
        setImplicitHeight(size.height());
        m_texture.current.reset();
        m_texture.current.swap(m_texture.pending);
        m_texture.sourceRect.setSize(size);
        m_dirty = true;
        qCDebug(lcMap) << "Polish done";
        update();
    }
}

QSGNode *Map::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    if (!m_texture.current)
        return nullptr; // not ready

    auto *node = static_cast<QSGSimpleTextureNode *>(oldNode);
    if (!node || m_dirty) {
        if (!node)
            node = new QSGSimpleTextureNode();
        node->setTexture(m_texture.current.data());
        node->setSourceRect(m_texture.sourceRect);
        m_dirty = false;
    }
    node->setRect(boundingRect());
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

void Map::mapReady(const QImage &image, const QString &code)
{
    if (m_code == code) {
        m_map = image;
        createMapTexture();
    }
}

bool Map::canDraw() const
{
    return isComponentComplete() && m_load && m_sourceSize.isValid() && !m_code.isEmpty();
}