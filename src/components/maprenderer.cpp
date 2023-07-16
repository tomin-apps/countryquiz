/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#include <cmath>
#include <QImage>
#include <QLoggingCategory>
#include <QPainter>
#include "maprenderer.h"

Q_LOGGING_CATEGORY(lcMapRenderer, "site.tomin.apps.CountryQuiz.MapRenderer", QtWarningMsg)

QMutex MapRenderer::s_rendererMutex;

QVector<MapRenderer *> MapRenderer::s_renderers;

QThread *MapRenderer::s_rendererThread = nullptr;

MapRenderer *MapRenderer::get(const QString &filePath)
{
    QMutexLocker locker(&s_rendererMutex);
    MapRenderer *renderer = nullptr;
    if (!s_rendererThread) {
        qCCritical(lcMapRenderer) << "Could not get MapRenderer as there is no renderer thread!";
    } else {
        for (auto candidate : s_renderers) {
            if (candidate->m_mapFilePath == filePath)
                renderer = candidate;
        }
        if (!renderer) {
            renderer = new MapRenderer(filePath);
            renderer->moveToThread(s_rendererThread);
            connect(s_rendererThread, &QThread::finished, renderer, &QObject::deleteLater);
            s_renderers.append(renderer);
            qCDebug(lcMapRenderer) << "Created new renderer for" << filePath;
        }
    }
    return renderer;
}

void MapRenderer::setup(QCoreApplication *app)
{
    if (!s_rendererThread) {
        QMutexLocker locker(&s_rendererMutex);
        if (!s_rendererThread) {
            s_rendererThread = new QThread(app);
            connect(app, &QCoreApplication::aboutToQuit, []() {
                s_rendererThread->quit();
                s_rendererThread->wait();
            });
            s_rendererThread->start();
            qCDebug(lcMapRenderer) << "Setup for rendering thread completed";
        }
    }
}

void MapRenderer::renderMap(const QSize &maxSize, const QString &code)
{
    qCDebug(lcMapRenderer) << "Will draw map, max size of" << maxSize << "for" << code;
    QSize size = getSize(maxSize, code);
    if (!size.isValid())
        qCCritical(lcMapRenderer) << "Got invalid size!";
    QImage image(size, QImage::Format_ARGB32_Premultiplied);
    QPainter painter(&image);
    painter.setCompositionMode(QPainter::CompositionMode_Source);
    painter.fillRect(0, 0, size.width(), size.height(), Qt::transparent);
    painter.setRenderHint(QPainter::Antialiasing);
    if (code.isEmpty()) {
        m_renderer.render(&painter);
        qCInfo(lcMapRenderer) << "Drew new world map in size of" << size;
    } else {
        m_renderer.render(&painter, code);
        qCInfo(lcMapRenderer) << "Drew new map of" << code << "in size of" << size;
    }
    emit mapReady(image, code);
}

MapRenderer::MapRenderer(const QString &filePath, QObject *parent)
    : QObject(parent)
    , m_mapFilePath(filePath)
    , m_renderer(filePath)
{
}

namespace {
    inline int scale(int from, int to, int value) {
        return std::lround(static_cast<qreal>(to) / static_cast<qreal>(from) * static_cast<qreal>(value));
    }
}

QSize MapRenderer::getSize(const QSize &maxSize, const QString &code) const
{
    QSize size;
    if (!code.isEmpty()) {
        QRectF bounds = m_renderer.boundsOnElement(code);
        size = QSize(bounds.width(), bounds.height());
        qCDebug(lcMapRenderer) << "Finding fitting size for" << bounds << "bounds";
    } else {
        size = m_renderer.defaultSize();
        qCDebug(lcMapRenderer) << "Finding fitting size for" << size;
    }
    if (maxSize.width() > 0 && maxSize.height() > 0) {
        // Return the largest size that fits
        QSize maxWidth(maxSize.width(), scale(size.width(), maxSize.width(), size.height()));
        QSize maxHeight(scale(size.height(), maxSize.height(), size.width()), maxSize.height());
        size = (maxWidth.height() <= maxSize.height()) ?  maxWidth : maxHeight;
    } else if (maxSize.width() > 0 /* && maxSize.height() <= 0 */) {
        // Scale size to width
        size = QSize(maxSize.width(), scale(size.width(), maxSize.width(), size.height()));
    } else if (maxSize.height() > 0 /* && maxSize.width() <= 0 */) {
        // Scale size to height
        size = QSize(scale(size.height(), maxSize.height(), size.width()), maxSize.height());
    }
    return size;
}