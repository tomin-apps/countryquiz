/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef SCORETABLE_H
#define SCORETABLE_H

#include <QColor>
#include <QFont>
#include <QLineF>
#include <QPointF>
#include <QQuickPaintedItem>
#include <QRect>
#include "statsmodel.h"

class ScoreGraph : public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(StatsModel *model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(int arrowTipSize READ arrowTipSize WRITE setArrowTipSize NOTIFY arrowTipSizeChanged)
    Q_PROPERTY(int lineWidth READ lineWidth WRITE setLineWidth NOTIFY lineWidthChanged)
    Q_PROPERTY(QColor lineColor READ lineColor WRITE setLineColor NOTIFY lineColorChanged)
    Q_PROPERTY(QColor secondaryLineColor READ secondaryLineColor WRITE setSecondaryLineColor NOTIFY secondaryLineColorChanged)
    Q_PROPERTY(QColor fillColor READ fillColor WRITE setFillColor NOTIFY fillColorChanged)
    Q_PROPERTY(QColor fontColor READ fontColor WRITE setFontColor NOTIFY fontColorChanged)
    Q_PROPERTY(QFont font READ font WRITE setFont NOTIFY fontChanged)
    Q_PROPERTY(bool canDraw READ canDraw WRITE setCanDraw NOTIFY canDrawChanged)

public:
    enum DirtyFlag {
        CleanFlags,
        MeasuresDirty = (1 << 0),
        ArrowsDirty = (1 << 1),
        TextsDirty = (1 << 2),
        PointsDirty = (1 << 3),
    };
    Q_DECLARE_FLAGS(DirtyFlags, DirtyFlag)
    Q_FLAG(DirtyFlags)

    ScoreGraph(QQuickItem *parent = nullptr);

    StatsModel *model() const;
    void setModel(StatsModel *model);

    int arrowTipSize() const;
    void setArrowTipSize(int arrowTipSize);
    int lineWidth() const;
    void setLineWidth(int lineWidth);
    QColor lineColor() const;
    void setLineColor(QColor lineColor);
    QColor secondaryLineColor() const;
    void setSecondaryLineColor(QColor secondaryLineColor);
    QColor fillColor() const;
    void setFillColor(QColor fillColor);
    QFont font() const;
    void setFont(QFont font);
    QColor fontColor() const;
    void setFontColor(QColor fontColor);
    bool canDraw() const;
    void setCanDraw(bool canDraw);

protected:
    void updatePolish() override;
    void paint(QPainter *painter) override;

signals:
    void modelChanged();
    void arrowTipSizeChanged();
    void lineWidthChanged();
    void lineColorChanged();
    void secondaryLineColorChanged();
    void fillColorChanged();
    void fontChanged();
    void fontColorChanged();
    void canDrawChanged();

private:
    void handleMeasuresChanged();
    void tryPolish();
    void updateData();

    struct Text {
        Text() {}
        Text(qreal x, qreal y, const QString &text)
            : bottomLeft{x, y}
            , text(text) {}

        QPointF bottomLeft;
        QString text;
    };

    DirtyFlags m_dirty = 0;
    StatsModel *m_statsModel = nullptr;
    int m_arrowTipSize = 5;
    int m_lineWidth = 1;
    QColor m_lineColor = Qt::white;
    QColor m_secondaryLineColor = Qt::darkGray;
    QColor m_fillColor = Qt::gray;
    QColor m_fontColor = Qt::white;
    QFont m_font;
    QVector<QLineF> m_arrows;
    QVector<std::pair<qint64, int>> m_data;
    QVector<QPointF> m_dataPoints;
    QRect m_drawArea;
    struct {
        int maximum = std::numeric_limits<int>::min();
        int minimum = std::numeric_limits<int>::max();
        qint64 last = std::numeric_limits<int>::min();
        qint64 first = std::numeric_limits<int>::max();
    } m_limits;
    QVector<int> m_monthLines;
    QVector<Text> m_texts;
    bool m_canDraw = true;
};

class ScoreGraphDataWorker : public QObject, public QRunnable
{
    Q_OBJECT

public:
    ScoreGraphDataWorker(const QSqlQuery &query);

    void run() override;

signals:
    void updatedData(QVector<std::pair<qint64, int>> data, int minimum, int maximum);

private:
    QSqlQuery m_query;
};

Q_DECLARE_OPERATORS_FOR_FLAGS(ScoreGraph::DirtyFlags)

#endif // SCORETABLE_H