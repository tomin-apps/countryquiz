/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef MAP_H
#define MAP_H

#include <QImage>
#include <QQuickItem>
#include <QSGTexture>

class MapRenderer;
class Map : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(QString code READ code WRITE setCode NOTIFY codeChanged)
    Q_PROPERTY(QSize maxSize READ maxSize WRITE setMaxSize NOTIFY maxSizeChanged)

public:
    explicit Map(QQuickItem *parent = nullptr);

    void updatePolish() override;
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;

    QString code() const;
    void setCode(const QString &code);

    const QSize &maxSize() const;
    void setMaxSize(const QSize &maxSize);

signals:
    void codeChanged();
    void renderMap(const QSize &size, const QString &code);

    void maxSizeChanged();

protected:
    void componentComplete() override;

private slots:
    void createMapTexture();
    void mapReady(const QImage &image, const QString &code);

private:
    QString m_code;
    bool m_dirty;
    QImage m_map;
    QSize m_maxSize;
    MapRenderer *m_renderer;
    struct {
        QScopedPointer<QSGTexture> pending;
        QScopedPointer<QSGTexture> current;
        QRectF sourceRect;
    } m_texture;
    QQuickWindow *m_window;
};

#endif // MAP_H