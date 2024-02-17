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
#include <QRectF>
#include <QRunnable>
#include <QSvgRenderer>
#include <QTransform>
#include <QThread>
#include <QVector>

class TileRenderer : public QObject, public QRunnable
{
    Q_OBJECT

public:
    TileRenderer(const QString &path, const QRectF &rect, const QTransform &translation, const QTransform &scaling, const QString &code);

    void run() override;

signals:
    void tileReady(const QImage &image, const QRectF &tile, const QString &code);

private:
    QString m_path;
    QRectF m_rect;
    QTransform m_translation;
    QTransform m_scaling;
    QString m_code;
};

class OverlayRenderer : public QObject, public QRunnable
{
    Q_OBJECT

public:
    OverlayRenderer(QSvgRenderer &renderer, const QRectF &rect, const QColor &color, const QTransform &translation, const QTransform &scaling, const QString &code);

    void run() override;

signals:
    void overlayReady(const QImage &image, const QRectF &tile, const QString &code);

private:
    QSvgRenderer &m_renderer;
    QRectF m_rect;
    QColor m_color;
    QTransform m_translation;
    QTransform m_scaling;
    QString m_code;
};

class MapRenderer : public QObject
{
    Q_OBJECT

public:
    static MapRenderer *get(const QString &filePath);
    static void setup(QCoreApplication *app);

public slots:
    void renderMap(const QSize &maxSize, const QString &code);

signals:
    void tileCountReady(const QSize &size, const QSize &tiles, const QString &code);
    void tileReady(const QImage &image, const QRectF &tile, const QString &code);
    void overlayReady(const QImage &image, const QRectF &tile, const QString &code);

private:
    explicit MapRenderer(const QString &filePath, QObject *parent = nullptr);

    static QMutex s_rendererMutex;
    static QVector<MapRenderer *> s_renderers;
    static QThread *s_rendererThread;

    QString m_mapFilePath;
    QSvgRenderer m_renderer;
    QString m_tilePathTemplate;
    QSize m_tileSize;
    QSize m_dimensions;
};

#endif // MAPRENDERER_H
