/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef MAPRENDERER_H
#define MAPRENDERER_H

#include <map>
#include <QCoreApplication>
#include <QColor>
#include <QMutex>
#include <QObject>
#include <QQuickWindow>
#include <QRectF>
#include <QRunnable>
#include <QSGTexture>
#include <QSvgRenderer>
#include <QTransform>
#include <QThread>
#include <QVector>

class MapRenderer : public QObject
{
    Q_OBJECT

public:
    explicit MapRenderer(const QString &filePath, QObject *parent = nullptr);

    QRectF calculateBounds(const QString &code, qreal aspectRatio);
    QRectF fullArea();

    std::pair<QMutex *, QSvgRenderer *> accessRenderer();
    QQuickWindow *window();

    enum MessageType {
        TileRendered,
        OverlayRendered,
        RenderingDone
    };
    Q_ENUM(MessageType)

public slots:
    void renderMap(const QSize &size, const QString &code, const QColor &overlayColor, bool inverted);
    void renderFullMap(const QSize &maxSize, bool inverted);
    void windowChanged(QQuickWindow *window);

private:
    struct Tiles {
        QString pathTemplate;
        QSize dimensions;

        Tiles(const QString &pathTemplate, const QSize &dimensions);
    };

    const Tiles &getTilesForScaling(const QSize &target, const QSizeF &original);

    QString m_mapFilePath;
    QSvgRenderer m_renderer;
    QMutex m_rendererMutex;
    QRectF m_fullArea;
    std::map<qreal, Tiles> m_tiles;
    QQuickWindow *m_window;
};

class TileRenderer : public QObject, public QRunnable
{
    Q_OBJECT

public:
    TileRenderer(const QString &path, const QRectF &rect, const QTransform &translation, const QTransform &scaling, bool inverted, MapRenderer *mapRenderer);

    void run() override;

signals:
    void renderingReady(MapRenderer::MessageType message, QSGTexture *texture, const QRectF &tile);

private:
    MapRenderer *m_mapRenderer;
    QString m_path;
    QRectF m_rect;
    QTransform m_translation;
    QTransform m_scaling;
    bool m_inverted;
};

class OverlayRenderer : public QObject, public QRunnable
{
    Q_OBJECT

public:
    OverlayRenderer(const QColor &color, const QTransform &translation, const QTransform &scaling, const QString &code, bool fast, MapRenderer *mapRenderer);

    void run() override;

signals:
    void renderingReady(MapRenderer::MessageType message, QSGTexture *texture, const QRectF &tile);

private:
    MapRenderer *m_mapRenderer;
    QColor m_color;
    QTransform m_translation;
    QTransform m_scaling;
    QString m_code;
    QTransform m_drawScaling;
};

class FullMapRenderer : public QObject, public QRunnable
{
    Q_OBJECT

public:
    FullMapRenderer(const QSize &size, bool inverted, MapRenderer *mapRenderer);

    void run() override;

signals:
    void fullMapReady(const QImage &map);

private:
    MapRenderer *m_mapRenderer;
    QSize m_size;
    bool m_inverted;
};

#endif // MAPRENDERER_H