/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef MAPMODEL_H
#define MAPMODEL_H

#include <QImage>
#include <QQuickItem>
#include <QScopedPointer>
#include <QSize>
#include <QString>
#include <QThread>
#include "maprenderer.h"

class MapModel : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(QString mapFile READ mapFile WRITE setMapFile NOTIFY mapFileChanged)
    Q_PROPERTY(QSize miniMapSize READ miniMapSize WRITE setMiniMapSize NOTIFY miniMapSizeChanged)

public:
    explicit MapModel(QQuickItem *parent = nullptr);

    const QString &mapFile() const;
    void setMapFile(const QString &mapFile);

    const QSize &miniMapSize() const;
    void setMiniMapSize(const QSize &miniMapSize);

    QSGTexture *miniMap() const;
    QRectF miniMapBounds(const QString &code, qreal aspectRatio) const;

    MapRenderer *renderer();

public slots:
    void fullMapReady(const QImage &map);

signals:
    void mapFileChanged();
    void miniMapSizeChanged();
    void miniMapChanged();
    void rendererChanged();
    void renderFullMap(const QSize &size);

protected:
    void componentComplete() override;

private:
    void setupRenderer();
    void drawMiniMap();

    QThread m_thread;
    QString m_mapFile;
    QSize m_miniMapSize;
    QScopedPointer<MapRenderer, QScopedPointerDeleteLater> m_renderer;
    QImage m_miniMap;
};

#endif // MAPMODEL_H