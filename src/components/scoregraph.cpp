/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#include <algorithm>
#include <cmath>
#include <QDateTime>
#include <QFontMetrics>
#include <QLocale>
#include <QLoggingCategory>
#include <QPainter>
#include <QVector>
#include "scoregraph.h"

Q_LOGGING_CATEGORY(lcScoreGraph, "site.tomin.apps.CountryQuiz.ScoreGraph", QtWarningMsg)
Q_LOGGING_CATEGORY(lcScoreGraphData, "site.tomin.apps.CountryQuiz.ScoreGraph.Data", QtWarningMsg)

/*
 * This draws highest scores for each datapoint.
 * The number of datapoints displayed depends on the width of the graph.
 */

namespace {
    const int MaxScore = 1000; // Keep in sync with TimeScore and MinScore
    const int Buckets = 6 * 30;
    const int MinimumDifference = MaxScore / 10;
    const qreal Zero = 0.0;

    QVector<QLineF> getArrow(QPointF tip, QPointF end, int tipSize)
    {
        // NB: Supports only arrows pointing up and right
        QVector<QLineF> lines;
        lines << QLineF(tip, end);
        lines << QLineF(tip, QPointF(tip.x() - tipSize, tip.y() + tipSize));
        if (tip.x() == end.x()) {
            qCDebug(lcScoreGraph) << "Drawing vertical arrow from" << end << "to" << tip;
            lines << QLineF(tip, QPointF(tip.x() + tipSize, tip.y() + tipSize));
        } else {
            qCDebug(lcScoreGraph) << "Drawing horizontal arrow from" << end << "to" << tip;
            lines << QLineF(tip, QPointF(tip.x() - tipSize, tip.y() - tipSize));
        }
        return lines;
    }

    template<typename T> qreal scaled(T value, int min, int max, qreal top, qreal span)
    {
        if (max == min)
            return top;
        return top - static_cast<qreal>(value - min) / (max - min) * span;
    }

    qint64 roundToMidnight(qint64 timestamp, bool before)
    {
        QDateTime dt = QDateTime::fromTime_t(timestamp, Qt::UTC).toLocalTime();
        dt.setTime(before ? QTime() : QTime(23, 59)); // to midnight
        return dt.toTime_t();
    }

    inline int round(int value, int factor)
    {
        return value / factor * factor;
    }
} // namespace

ScoreGraph::ScoreGraph(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    connect(this, &QQuickItem::heightChanged, this, &ScoreGraph::handleMeasuresChanged);
    connect(this, &QQuickItem::widthChanged, this, &ScoreGraph::handleMeasuresChanged);
}

void ScoreGraph::handleMeasuresChanged()
{
    m_dirty |= MeasuresDirty;
    tryPolish();
}

void ScoreGraph::tryPolish()
{
    if (!m_statsModel || !m_statsModel->busy())
        polish();
}

void ScoreGraph::updatePolish()
{
    QQuickPaintedItem::updatePolish();

    if (!m_statsModel)
        return;

    int count = m_statsModel->rowCount();
    if (count <= 0)
        return;

    if (m_dirty & DataDirty) {
        // TODO: Do this in background threads instead?
        // Assumes that data is sorted descending based on timestamp
        const qint64 bucketStart = roundToMidnight(
                    m_statsModel->data(m_statsModel->index(m_statsModel->rowCount() - 1, 0), StatsModel::TimestampRole).toLongLong(), true);
        const qint64 bucketEnd = roundToMidnight(
                    m_statsModel->data(m_statsModel->index(0, 0), StatsModel::TimestampRole).toLongLong(), false);
        const qreal timePerBucket = static_cast<qreal>(bucketEnd - bucketStart) / Buckets;
        qCDebug(lcScoreGraph).nospace() << "Bucket size: " << timePerBucket << ", start: " << bucketStart << ", end: " << bucketEnd;
        // Squashed data
        QVector<std::pair<qint64, int>> data;
        if (timePerBucket < 600 && count < Buckets) {
            qCDebug(lcScoreGraph) << "Only few results and little time covered, using all" << count << "data points";
            data.reserve(count);
            for (int row = 0; row < count; ++row) {
                const auto index = m_statsModel->index(row, 0);
                const qint64 ts = m_statsModel->data(index, StatsModel::TimestampRole).toLongLong();
                const int score = m_statsModel->data(index, StatsModel::ScoreRole).toReal();
                qCDebug(lcScoreGraphData) << "Adding datapoint" << ts << "->" << score;
                data << std::pair<qint64, int>(ts, score);
            }
        } else {
            qCDebug(lcScoreGraph) << "Reading" << count << "rows from stats model," << timePerBucket << "s of time per bucket";
            int lastBucket = Buckets;
            int lastScore = 0;
            data.reserve(Buckets);
            for (int row = 0; row < count; ++row) {
                const auto index = m_statsModel->index(row, 0);
                const qint64 ts = m_statsModel->data(index, StatsModel::TimestampRole).toLongLong();
                const int score = m_statsModel->data(index, StatsModel::ScoreRole).toReal();
                const int bucket = (ts - bucketStart) / timePerBucket;
                if (bucket != lastBucket) {
                    qCDebug(lcScoreGraphData) << "Adding datapoint" << ts << "->" << score;
                    data << std::pair<qint64, int>(ts, score);
                    lastBucket = bucket;
                    lastScore = score;
                } else if (score > lastScore /* && bucket == lastBucket */) {
                    qCDebug(lcScoreGraphData) << "Replacing last datapoint" << ts << "->" << score;
                    data[data.length() - 1] = std::pair<qint64, int>(ts, score);
                    lastScore = score;
                } // else bucket == lastBucket && score <= lastScore
            }
            data.squeeze();
            qCDebug(lcScoreGraph) << "Squashed data into" << data.length() << "buckets";
        }

        // Limits for values
        int maximum = std::numeric_limits<int>::min();
        int minimum = std::numeric_limits<int>::max();
        for (const std::pair<qint64, int> &pair : data) {
            const int score = pair.second;
            if (maximum < score)
                maximum = score;
            if (minimum > score)
                minimum = score;
        }
        m_data.swap(data);
        m_dirty &= ~DataDirty;

        // Ensure that maximum and minimum aren't too close
        if (maximum - minimum < MinimumDifference)
            maximum = round(minimum, MinimumDifference) + MinimumDifference;

        const qint64 last = m_data[0].first;
        const qint64 first = m_data[m_data.length() - 1].first;

        if (m_limits.maximum != maximum || m_limits.minimum != minimum || m_limits.last != last || m_limits.first != first) {
            m_limits.maximum = maximum;
            m_limits.minimum = minimum;
            m_limits.last = last;
            m_limits.first = first;
            m_dirty |= MeasuresDirty | TextsDirty | PointsDirty;
        }
    }

    // Limits for labels on x-axis
    const qint64 last = m_limits.last;
    const qint64 first = m_limits.first;

    // Limits for labels on y-axis
    const int maximum = m_limits.maximum;
    const int scaleFactor = std::max(static_cast<int>(pow(10, static_cast<int>(log10(maximum - m_limits.minimum)) - 1)), MinimumDifference);
    const int high = round(maximum, scaleFactor);
    const int low = round(m_limits.minimum, scaleFactor);
    qCDebug(lcScoreGraph).nospace() << "Limits: max: " << maximum << ", min: " << m_limits.minimum
                                    << ", scale factor: " << scaleFactor << ", high: " << high << ", low: " << low;

    QFontMetrics metrics(m_font);
    QLocale locale;

    if (m_dirty & MeasuresDirty) {
        // Assumes that the largest value has the most width
        const int textWidth = metrics.width(locale.toString(high) + QChar(' '));
        // Calculate draw area boundaries
        const int margin = 1.25 * m_arrowTipSize;
        const int bottom = height() - std::max(m_arrowTipSize, metrics.height());
        const int top = std::max(
                    static_cast<int>(scaled(maximum, low, high, bottom, bottom - m_arrowTipSize - metrics.ascent())),
                    margin);
        // Full draw area for texts
        QRect drawArea {
            textWidth,
            top,
            static_cast<int>(width() - margin) - textWidth,
            bottom - top
        };
        if (m_drawArea != drawArea) {
            m_drawArea = drawArea;
            m_dirty |= ArrowsDirty | TextsDirty | PointsDirty;
        }
        qCDebug(lcScoreGraph) << "Draw area:" << m_drawArea.x() << m_drawArea.y() << m_drawArea.width() << m_drawArea.height();

        m_dirty &= ~MeasuresDirty;
    }

    const int left = m_drawArea.x();
    const int bottom = m_drawArea.y() + m_drawArea.height();

    if (m_dirty & ArrowsDirty) {
        m_arrows = getArrow(QPointF(left, 0), QPointF(left, bottom), m_arrowTipSize)
                 + getArrow(QPointF(width(), bottom), QPointF(left, bottom), m_arrowTipSize);
        m_dirty &= ~ArrowsDirty;
    }

    if (m_dirty & TextsDirty) {
        // TODO: Update only if texts change and use QStaticText
        QVector<Text> texts;
        const int scaleFactor = pow(10, static_cast<int>(log10(high - low)) - 1);
        int division = (high - low) / scaleFactor / static_cast<int>(height() / metrics.height() / 3) * scaleFactor;
        if (division <= 0)
            division = 1;
        qCDebug(lcScoreGraph) << "Using division of" << division << "for values between" << low << "and" << high;
        int score = high;
        while (score >= low) {
            QString text = locale.toString(score) + QChar(' ');
            texts << Text(left - metrics.width(text), scaled(score, low, maximum, bottom, m_drawArea.height()), text);
            score -= division;
        }
        qCDebug(lcScoreGraph) << "Added" << texts.length() << "labels to y-axis";
        QDateTime month = QDateTime::fromTime_t(last, Qt::UTC).toLocalTime();
        month.setTime(QTime()); // to midnight
        month = month.addDays(-month.date().day() + 1); // to first day of the month
        const qint64 span = last - first;
        int lastPos = width();
        int pos = m_drawArea.x() + std::max(Zero, m_drawArea.width() * ((static_cast<qreal>(month.toTime_t()) - first) / span));
        QVector<int> monthLines;
        while (pos >= m_drawArea.x()) {
            monthLines << pos;
            QString name = QDate::shortMonthName(month.date().month(), QDate::StandaloneFormat);
            const qreal width = metrics.width(name);
            if (0 < pos && pos + width < lastPos) {
                texts << Text(pos, height() - metrics.descent(), name);
                lastPos = pos;
            }
            month = month.addMonths(-1);
            pos = m_drawArea.x() + (m_drawArea.width() * ((static_cast<qreal>(month.toTime_t()) - first) / span));
        }
        qCDebug(lcScoreGraph) << "Added" << monthLines.length() << "month lines to x-axis";
        m_monthLines.swap(monthLines);
        m_texts.swap(texts);
        m_dirty &= ~TextsDirty;
    }

    if (m_dirty & PointsDirty) {
        qCDebug(lcScoreGraph) << "Fitting" << m_data.length() << "data points to the graph";
        QVector<QPointF> dataPoints;
        for (const std::pair<qint64, int> &pair : m_data) {
            const qint64 ts = pair.first;
            const int score = pair.second;
            QPointF point(scaled(ts, last, first, m_drawArea.x() + m_drawArea.width(), m_drawArea.width()),
                          scaled(score, low, maximum, bottom, m_drawArea.height()));
            qCDebug(lcScoreGraphData) << "Adding data point" << point << "with ts:" << ts << "and score:" << score;
            dataPoints << point;
        }
        m_dataPoints.swap(dataPoints);
        m_dirty &= ~PointsDirty;
    }

    update();
}

void ScoreGraph::paint(QPainter *painter)
{
    qCDebug(lcScoreGraph) << "Painting score table";

    painter->setCompositionMode(QPainter::CompositionMode_Source);
    painter->setRenderHint(QPainter::Antialiasing);
    painter->setPen(QPen(m_fillColor, m_lineWidth));
    painter->setBrush(m_fillColor);
    painter->setFont(m_font);

    if (!m_dataPoints.empty()) {
        QVector<QPointF> polygon(m_dataPoints);
        if (polygon.length() == 1)
            polygon << QPointF(m_drawArea.x(), m_dataPoints[0].y());
        const int bottom = m_drawArea.y() + m_drawArea.height();
        polygon << QPointF(m_drawArea.x(), bottom)
                << QPointF(m_dataPoints[0].x(), bottom);
        painter->drawPolygon(polygon.constData(), polygon.length());
    }

    painter->setPen(QPen(m_secondaryLineColor, m_lineWidth));
    // Assumes that texts (lines) are drawn from top to bottom
    for (const auto &text : m_texts) {
        if (text.bottomLeft.y() > m_drawArea.bottom())
            break;
        painter->drawLine(m_drawArea.x(), text.bottomLeft.y(), m_drawArea.x() + m_drawArea.width(), text.bottomLeft.y());
    }
    for (const auto &pos : m_monthLines) {
        painter->drawLine(pos, m_drawArea.y(), pos, m_drawArea.y() + m_drawArea.height());
    }

    painter->setPen(QPen(m_fontColor, m_lineWidth));
    for (const auto &text : m_texts) {
        painter->drawText(text.bottomLeft, text.text);
    }

    painter->setPen(QPen(m_lineColor, m_lineWidth));
    painter->drawLines(m_arrows);
    painter->drawPoints(m_dataPoints.constData(), m_dataPoints.length());
}

StatsModel *ScoreGraph::model() const
{
    return m_statsModel;
}

void ScoreGraph::setModel(StatsModel *model)
{
    if (m_statsModel != model) {
        if (m_statsModel) {
            qCDebug(lcScoreGraph) << "Disconnecting old model from score graph";
            m_statsModel->disconnect(this);
        }
        m_statsModel = model;
        emit modelChanged();
        if (m_statsModel) {
            qCDebug(lcScoreGraph) << "Connecting new model to score graph";
            connect(m_statsModel, &StatsModel::busyChanged, this, [this] {
                if (m_dirty)
                    tryPolish();
            });
            connect(m_statsModel, &StatsModel::modelReset, this, [this] {
                qCDebug(lcScoreGraph) << "Model data changed, refreshing graph";
                m_dirty |= DataDirty;
                tryPolish();
            });
            m_dirty |= DataDirty;
            tryPolish();
        }
    }
}

int ScoreGraph::lineWidth() const
{
    return m_lineWidth;
}

void ScoreGraph::setLineWidth(int lineWidth)
{
    if (m_lineWidth != lineWidth) {
        m_lineWidth = lineWidth;
        emit lineWidthChanged();
        update();
    }
}

QColor ScoreGraph::lineColor() const
{
    return m_lineColor;
}

void ScoreGraph::setLineColor(QColor lineColor)
{
    if (m_lineColor != lineColor) {
        m_lineColor = lineColor;
        emit lineColorChanged();
        update();
    }
}

QColor ScoreGraph::secondaryLineColor() const
{
    return m_secondaryLineColor;
}

void ScoreGraph::setSecondaryLineColor(QColor secondaryLineColor)
{
    if (m_secondaryLineColor != secondaryLineColor) {
        m_secondaryLineColor = secondaryLineColor;
        emit secondaryLineColorChanged();
        update();
    }
}

QColor ScoreGraph::fillColor() const
{
    return m_fillColor;
}

void ScoreGraph::setFillColor(QColor fillColor)
{
    if (m_fillColor != fillColor) {
        m_fillColor = fillColor;
        emit fillColorChanged();
        update();
    }
}

QFont ScoreGraph::font() const
{
    return m_font;
}

void ScoreGraph::setFont(QFont font)
{
    if (m_font != font) {
        m_font = font;
        emit fontChanged();
        m_dirty |= MeasuresDirty;
        tryPolish();
    }
}

QColor ScoreGraph::fontColor() const
{
    return m_fontColor;
}

void ScoreGraph::setFontColor(QColor fontColor)
{
    if (m_fontColor != fontColor) {
        m_fontColor = fontColor;
        emit fontColorChanged();
        update();
    }
}

int ScoreGraph::arrowTipSize() const
{
    return m_arrowTipSize;
}

void ScoreGraph::setArrowTipSize(int arrowTipSize)
{
    if (m_arrowTipSize != arrowTipSize) {
        m_arrowTipSize = arrowTipSize;
        emit arrowTipSizeChanged();
        m_dirty |= ArrowsDirty;
        tryPolish();
    }
}