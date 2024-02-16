/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef MAP_H
#define MAP_H

#include <vector>
#include <QImage>
#include <QQuickItem>
#include <QSGTexture>

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

signals:
    void codeChanged();
    void loadChanged();
    void sourceSizeChanged();

    void renderMap(const QSize &size, const QString &code);

protected:
    void componentComplete() override;

private slots:
    void createMapTextures();
    void tileCountReady(const QSize &size, const QSize &tiles, const QString &code);
    void tileReady(const QImage &image, const QRectF &tile, const QString &code);
    void overlayReady(const QImage &image, const QRectF &tile, const QString &code);

private:
    struct Tile {
        QImage image;
        QRectF location;
        QScopedPointer<QSGTexture, QScopedPointerDeleteLater> texture;

        Tile(const QImage &image, const QRectF &location);
        Tile(Tile &&other);
        Tile(Tile &other) = delete;
    };

    bool canDraw() const;
    bool texturesReady() const;

    QString m_code;
    bool m_dirty;
    bool m_load;
    QSize m_sourceSize;

    int m_tileCount;
    std::vector<Tile> m_tiles;
    struct {
        QImage image;
        QRectF location;
        QScopedPointer<QSGTexture, QScopedPointerDeleteLater> texture;
    } m_overlay;

    MapRenderer *m_renderer;
    QQuickWindow *m_window;
};

#endif // MAP_H