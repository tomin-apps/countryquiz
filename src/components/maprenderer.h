/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef MAPRENDERER_H
#define MAPRENDERER_H

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
    static MapRenderer *get(const QString &filePath);
    static void setup(QCoreApplication *app);

    QQuickWindow *getWindow();

    enum MessageType {
        TileRendered,
        OverlayRendered,
        RenderingDone
    };
    Q_ENUM(MessageType)

public slots:
    void renderMap(const QSize &maxSize, const QString &code);
    void windowChanged(QQuickWindow *window);

private:
    explicit MapRenderer(const QString &filePath, QObject *parent = nullptr);

    static QMutex s_rendererMutex;
    static QVector<MapRenderer *> s_renderers;
    static QThread *s_rendererThread;

    QString m_mapFilePath;
    QSvgRenderer m_renderer;
    QString m_tilePathTemplate;
    QSize m_dimensions;
    QQuickWindow *m_window;
};

class TileRenderer : public QObject, public QRunnable
{
    Q_OBJECT

public:
    TileRenderer(const QString &path, const QRectF &rect, const QTransform &translation, const QTransform &scaling, MapRenderer *parent);

    void run() override;

signals:
    void renderingReady(MapRenderer::MessageType message, QSGTexture *texture, const QRectF &tile);

private:
    MapRenderer *getMapRenderer() { return qobject_cast<MapRenderer *>(parent()); }

    QString m_path;
    QRectF m_rect;
    QTransform m_translation;
    QTransform m_scaling;
};

class OverlayRenderer : public QObject, public QRunnable
{
    Q_OBJECT

public:
    OverlayRenderer(QSvgRenderer &renderer, const QRectF &rect, const QColor &color, const QTransform &translation, const QTransform &scaling, const QString &code, MapRenderer *parent);

    void run() override;

signals:
    void renderingReady(MapRenderer::MessageType message, QSGTexture *texture, const QRectF &tile);

private:
    MapRenderer *getMapRenderer() { return qobject_cast<MapRenderer *>(parent()); }

    QSvgRenderer &m_renderer;
    QRectF m_rect;
    QColor m_color;
    QTransform m_translation;
    QTransform m_scaling;
    QString m_code;
};

#endif // MAPRENDERER_H