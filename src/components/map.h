/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef MAP_H
#define MAP_H

#include <vector>
#include <QColor>
#include <QElapsedTimer>
#include <QImage>
#include <QQuickItem>
#include <QSGTexture>
#include "maprenderer.h"

class MapModel;
class MapRenderer;
class Map : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(QString code READ code WRITE setCode NOTIFY codeChanged)
    Q_PROPERTY(QSize sourceSize READ sourceSize WRITE setSourceSize NOTIFY sourceSizeChanged)
    Q_PROPERTY(MapModel *model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QColor overlayColor READ overlayColor WRITE setOverlayColor NOTIFY overlayColorChanged)

public:
    enum Ready {
        NothingReady   = 0x00,
        MinimapReady   = 0x01,
        OverlayPending = 0x02,
        OverlayReady   = 0x04,
        TilesReady     = 0x08,
        RenderingReady = 0x10,
    };
    Q_DECLARE_FLAGS(Readyness, Ready)
    Q_FLAG(Readyness)

    explicit Map(QQuickItem *parent = nullptr);
    ~Map();

    void updatePolish() override;

    QString code() const;
    void setCode(const QString &code);

    const QSize &sourceSize() const;
    void setSourceSize(const QSize &sourceSize);

    MapModel *model() const;
    void setModel(MapModel *model);

    QColor overlayColor() const;
    void setOverlayColor(const QColor &color);

public slots:
    void renderingReady(MapRenderer::MessageType message, QSGTexture *texture, const QRectF &tile);

signals:
    void codeChanged();
    void sourceSizeChanged();
    void modelChanged();
    void overlayColorChanged();
    void overlayOpacityChanged();

    void renderMap(const QSize &size, const QString &code, const QColor &overlayColor);
    void renderingProgressed(MapRenderer::MessageType message, int count);

protected:
    void componentComplete() override;
    void releaseResources() override;
    QSGNode *updatePaintNode(QSGNode *node, UpdatePaintNodeData *) override;

private slots:
    void renderAgain();
    void rendererChanged();
    void miniMapChanged();

private:
    enum TileParts : size_t {
        Hidden,
        SinglePart,
        SplitParts,
    };

    struct Tile {
        QScopedPointer<QSGTexture> texture;
        QRectF location;
        struct {
            QRectF source;
            QRectF target;
        } rects[2];
        TileParts parts;

        Tile(QSGTexture *texture, const QRectF &location);
        Tile(Tile &&other);
        Tile(Tile &other) = delete;
    };

    bool canRender() const;
    bool texturesReady() const;
    bool allTexturesReady() const;
    void setTexture(QScopedPointer<QSGTexture> &ptr, QSGTexture *texture);
    void cleanupTextures();

    QString m_code;
    QSize m_sourceSize;
    MapModel *m_mapModel;
    QColor m_overlayColor;

    bool m_dirty;
    std::vector<Tile> m_tiles;
    struct {
        QScopedPointer<QSGTexture> texture;
        QRectF location;
    } m_overlay;
    struct {
        QScopedPointer<QSGTexture> texture;
        QRectF location;
        struct {
            QRectF source;
            QRectF target;
        } rect[2];
        QRectF bounds;
    } m_miniMap;
    struct {
        QRectF source;
        QRectF target;
    } m_fastMap[2];

    MapRenderer *m_renderer;
    QQuickWindow *m_window;
    std::vector<QSGTexture *> m_abandoned;

    Readyness m_ready;
};

class RenderingTimer : public QObject, public QElapsedTimer
{
    Q_OBJECT

public:
    explicit RenderingTimer(QObject *parent = nullptr);
};

Q_DECLARE_OPERATORS_FOR_FLAGS(Map::Readyness)

#endif // MAP_H