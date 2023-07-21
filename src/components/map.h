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
    void createMapTexture();
    void mapReady(const QImage &image, const QString &code);

private:
    QString m_code;
    bool m_dirty;
    bool m_load;
    QImage m_map;
    QSize m_sourceSize;
    MapRenderer *m_renderer;
    struct {
        QScopedPointer<QSGTexture> pending;
        QScopedPointer<QSGTexture> current;
        QRectF sourceRect;
    } m_texture;
    QQuickWindow *m_window;
};

#endif // MAP_H