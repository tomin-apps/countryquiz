/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef MAP_H
#define MAP_H

#include <vector>
#include <QElapsedTimer>
#include <QImage>
#include <QQuickItem>
#include <QSGTexture>
#include "maprenderer.h"

class MapRenderer;
class Map : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(QString code READ code WRITE setCode NOTIFY codeChanged)
    Q_PROPERTY(bool load READ load WRITE setLoad NOTIFY loadChanged)
    Q_PROPERTY(QSize sourceSize READ sourceSize WRITE setSourceSize NOTIFY sourceSizeChanged)

public:
    explicit Map(QQuickItem *parent = nullptr);

    void updatePolish() override;
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;

    QString code() const;
    void setCode(const QString &code);

    bool load() const;
    void setLoad(bool load);

    const QSize &sourceSize() const;
    void setSourceSize(const QSize &sourceSize);

public slots:
    void renderingReady(MapRenderer::MessageType message, QSGTexture *texture, const QRectF &tile);

signals:
    void codeChanged();
    void loadChanged();
    void sourceSizeChanged();

    void renderMap(const QSize &size, const QString &code);
    void renderingProgressed(MapRenderer::MessageType message, int count);

protected:
    void componentComplete() override;

private slots:
    void drawAgain();

private:
    struct Tile {
        QScopedPointer<QSGTexture, QScopedPointerDeleteLater> texture;
        QRectF location;

        Tile(QSGTexture *texture, const QRectF &location);
        Tile(Tile &&other);
        Tile(Tile &other) = delete;
    };

    bool canDraw() const;
    bool texturesReady() const;

    QString m_code;
    bool m_dirty;
    bool m_load;
    QSize m_sourceSize;

    bool m_renderingReady;
    std::vector<Tile> m_tiles;
    struct {
        QRectF location;
        QScopedPointer<QSGTexture, QScopedPointerDeleteLater> texture;
    } m_overlay;

    MapRenderer *m_renderer;
    QQuickWindow *m_window;
};

class RenderingTimer : public QObject, public QElapsedTimer
{
    Q_OBJECT

public:
    explicit RenderingTimer(QObject *parent = nullptr);
};

#endif // MAP_H