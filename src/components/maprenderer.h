/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef MAPRENDERER_H
#define MAPRENDERER_H

#include <QCoreApplication>
#include <QMutex>
#include <QObject>
#include <QSvgRenderer>
#include <QThread>
#include <QVector>

class MapRenderer : public QObject
{
    Q_OBJECT

public:
    static MapRenderer *get(const QString &filePath);
    static void setup(QCoreApplication *app);

public slots:
    void renderMap(const QSize &maxSize, const QString &code);

signals:
    void mapReady(const QImage &image, const QString &code);

private:
    explicit MapRenderer(const QString &filePath, QObject *parent = nullptr);
    QSize getSize(const QSize &maxSize, const QString &code) const;

    static QMutex s_rendererMutex;
    static QVector<MapRenderer *> s_renderers;
    static QThread *s_rendererThread;

    QString m_mapFilePath;
    QSvgRenderer m_renderer;
};

#endif // MAPRENDERER_H