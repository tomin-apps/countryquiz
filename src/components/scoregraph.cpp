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
#include <QSqlDriver>
#include <QSqlError>
#include <QThread>
#include <QThreadPool>
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

    inline int roundTruncate(int value, int factor)
    {
        return value / factor * factor;
    }

    inline int roundUp(int value, int factor)
    {
        return static_cast<int>(ceil(static_cast<qreal>(value) / factor)) * factor;
    }

    inline int getDivision(int high, int low, int space)
    {
        const int span = high - low;
        const int scaleFactor = pow(10, static_cast<int>(log10(span)) - 1);
        return std::max(1, static_cast<int>(static_cast<qreal>(span) / scaleFactor / space)) * scaleFactor;
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

void ScoreGraph::updateData()
{
    if (!m_statsModel || m_statsModel->busy())
        return;

    if (m_statsModel->rowCount() <= 0) {
        qCDebug(lcScoreGraph) << "Stats model is empty";
        if (!m_data.empty()) {
            m_data.clear();
            tryPolish();
        }
        return;
    }

    auto query = m_statsModel->query();
    if (!query.isActive() || !query.isSelect() || query.isForwardOnly()) {
        qCDebug(lcScoreGraph) << "Query is not active, is not select or is forward only";
        return;
    }

    qCDebug(lcScoreGraph) << "Sending data to background process";
    auto *worker = new ScoreGraphDataWorker(query);
    connect(worker, &ScoreGraphDataWorker::updatedData, this, [this](QVector<std::pair<qint64, int>> data, int minimum, int maximum) {
        qCDebug(lcScoreGraph) << "Got updated data back";
        m_data.swap(data);

        const qint64 last = m_data[0].first;
        const qint64 first = m_data[m_data.length() - 1].first;

        if (m_limits.maximum != maximum || m_limits.minimum != minimum || m_limits.last != last || m_limits.first != first) {
            m_limits.maximum = maximum;
            m_limits.minimum = minimum;
            m_limits.last = last;
            m_limits.first = first;
            m_dirty |= MeasuresDirty | TextsDirty | PointsDirty;
        }

        tryPolish();
    }, Qt::QueuedConnection);
    worker->setAutoDelete(true);
    QThreadPool::globalInstance()->start(worker, QThread::LowPriority);
}

void ScoreGraph::tryPolish()
{
    if (!m_statsModel || !m_statsModel->busy())
        polish();
}

void ScoreGraph::updatePolish()
{
    QQuickPaintedItem::updatePolish();

    if (!m_statsModel || m_data.empty())
        return;

    // Limits for labels on x-axis
    const qint64 last = m_limits.last;
    const qint64 first = m_limits.first;

    QFontMetrics metrics(m_font);

    // Limits for labels on y-axis
    const int maximum = m_limits.maximum;
    const int scaleFactor = std::max(static_cast<int>(pow(10, static_cast<int>(log10(maximum - m_limits.minimum)) - 1)), MinimumDifference);
    const int low = roundTruncate(m_limits.minimum, scaleFactor);
    const int division = getDivision(roundUp(maximum, scaleFactor), low, static_cast<int>(height() / metrics.height() / 3));
    const int high = roundUp(maximum, division);
    qCDebug(lcScoreGraph).nospace() << "Limits: max: " << maximum << ", min: " << m_limits.minimum
                                    << ", scale factor: " << scaleFactor << ", division: " << division
                                    << ", high: " << high << ", low: " << low;
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

    if (m_canDraw && (m_dirty & PointsDirty)) {
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

    if (m_canDraw)
        update();
}

void ScoreGraph::paint(QPainter *painter)
{
    if (!m_canDraw)
        return;

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
    const int monthLineTop = 1.25 * m_arrowTipSize;
    for (const auto &pos : m_monthLines) {
        painter->drawLine(pos, monthLineTop, pos, m_drawArea.y() + m_drawArea.height());
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
                updateData();
                if (m_dirty)
                    tryPolish();
            });
            connect(m_statsModel, &StatsModel::modelReset, this, [this] {
                qCDebug(lcScoreGraph) << "Model data changed, refreshing graph";
                updateData();
            });
            updateData();
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

bool ScoreGraph::canDraw() const
{
    return m_canDraw;
}

void ScoreGraph::setCanDraw(bool canDraw)
{
    if (m_canDraw != canDraw) {
        m_canDraw = canDraw;
        emit canDrawChanged();
        if (m_canDraw)
            tryPolish();
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

ScoreGraphDataWorker::ScoreGraphDataWorker(const QSqlQuery &query)
    : QObject(nullptr)
    , m_query(query)
{
}

void ScoreGraphDataWorker::run()
{
    // Assumes that data is sorted descending based on timestamp
    Q_ASSERT(m_query.last());
    const qint64 bucketStart = roundToMidnight(m_query.value(3).toLongLong(), true);
    Q_ASSERT(m_query.first());
    const qint64 bucketEnd = roundToMidnight(m_query.value(3).toLongLong(), false);
    const qreal timePerBucket = static_cast<qreal>(bucketEnd - bucketStart) / Buckets;
    qCDebug(lcScoreGraph).nospace() << "Bucket size: " << timePerBucket << ", start: " << bucketStart << ", end: " << bucketEnd;

    // Squashed data
    QVector<std::pair<qint64, int>> data;
    int count = 0;
    if (timePerBucket < 600) {
        qCDebug(lcScoreGraph) << "Little time covered, trying to use all data points";
        do {
            ++count;
            const auto index = m_query.value(0);
            const qint64 ts = m_query.value(3).toLongLong();
            const int score = m_query.value(2).toReal();
            qCDebug(lcScoreGraphData) << "Adding datapoint" << ts << "->" << score;
            data << std::pair<qint64, int>(ts, score);
            if (count >= Buckets) {
                qCDebug(lcScoreGraph) << "Too many results, falling back to buckets";
                data.clear();
                break;
            }
        } while (m_query.next());
    }
    Q_ASSERT(m_query.first());
    if (timePerBucket >= 600 || count >= Buckets) {
        qCDebug(lcScoreGraph) << "Reading stats model," << timePerBucket << "s of time per bucket";
        int lastBucket = Buckets;
        int lastScore = 0;
        data.reserve(Buckets);
        do {
            const auto index = m_query.value(0);
            const qint64 ts = m_query.value(3).toLongLong();
            const int score = m_query.value(2).toReal();
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
        } while (m_query.next());
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

    // Ensure that maximum and minimum aren't too close
    if (maximum - minimum < MinimumDifference)
        maximum = roundTruncate(minimum, MinimumDifference) + MinimumDifference;

    emit updatedData(data, minimum, maximum);
}