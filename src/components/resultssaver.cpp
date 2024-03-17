/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#include <chrono>
#include <QThread>
#include <QThreadPool>
#include <QLoggingCategory>
#include "resultssaver.h"
#include "statsdatabase.h"

Q_LOGGING_CATEGORY(lcResultsSaver, "site.tomin.apps.CountryQuiz.ResultsSaver", QtWarningMsg)

namespace {
    const int MaxScore = 1000;
    const int SecondsInMillisecond = 1000;
} // namespace

ResultsSaver::ResultsSaver(QQuickItem *parent)
    : QQuickItem(parent)
    , m_options(new Options)
    , m_nth(-1)
{
}

Options *ResultsSaver::options() const
{
    return m_options.get();
}

int ResultsSaver::nth() const
{
    return m_nth;
}

void ResultsSaver::save(const QList<bool> &correct, const QList<int> &times)
{
    if (m_nth != -1) {
        m_nth = -1;
        emit nthChanged();
    }
    if (checkResults(correct, times)) {
        qCDebug(lcResultsSaver) << "Saving result";
        auto *worker = new ResultsSaverWorker(*m_options, numberOfCorrect(correct), time(times), calculateScore(correct, times), now());
        connect(worker, &ResultsSaverWorker::updateNth, this, [this](int nth) {
            if (m_nth != nth) {
                m_nth = nth;
                emit nthChanged();
            }
        }, Qt::QueuedConnection);
        worker->setAutoDelete(true);
        QThreadPool::globalInstance()->start(worker, QThread::LowPriority);
    }
}

int ResultsSaver::numberOfCorrect(const QList<bool> &correct)
{
    return std::accumulate(correct.begin(), correct.end(), 0, [](int sum, bool result) {
        return sum + (result ? 1 : 0);
    });
}

int ResultsSaver::time(const QList<int> &times)
{
    return std::accumulate(times.begin(), times.end(), 0, [](int sum, int time) {
        return sum + time;
    });
}

time_t ResultsSaver::now()
{
    const auto now = std::chrono::system_clock::now();
    return std::chrono::system_clock::to_time_t(now);
}

bool ResultsSaver::checkResults(const QList<bool> &correct, const QList<int> &times)
{
    /* Attempt to check for correctness
     * - Options are set to valid values
     * - Both lists are of equal size
     * - Times don't add up to more than timeToAnswer
     * - Times are positive
     */
    if (!m_options->isValid()) {
        qCDebug(lcResultsSaver) << "Options is not valid, not saving";
        return false;
    }

    if (correct.size() != times.size()) {
        qCWarning(lcResultsSaver) << "List of correct answers is not the same size as list of recorded times, not saving";
        return false;
    }

    if (time(times) > times.size() * m_options->timeToAnswer() * SecondsInMillisecond) {
        qCWarning(lcResultsSaver) << "Recorded time is too long, not saving";
        return false;
    }

    return true;
}

int ResultsSaver::calculateScore(const QList<bool> &correct, const QList<int> &times)
{
    int timeLimit = m_options->timeToAnswer() * SecondsInMillisecond;
    double score = 0;
    auto itCorrect = correct.begin();
    auto itTimes = times.begin();
    while (itCorrect != correct.end() && itTimes != times.end()) {
        score += static_cast<double>((*(itCorrect++) ? 1 : 0) * MaxScore) * (1.0 - (static_cast<double>(*(itTimes++)) / timeLimit));
    }
    return score;
}

ResultsSaverWorker::ResultsSaverWorker(const Options &options, int numberOfCorrect, int time, int score, time_t datetime)
    : QObject(nullptr)
    , m_options(options)
    , m_numberOfCorrect(numberOfCorrect)
    , m_time(time)
    , m_score(score)
    , m_datetime(datetime)
{
}

void ResultsSaverWorker::run()
{
    int nth = StatsDatabase::store(&m_options, m_numberOfCorrect, m_time, m_score, m_datetime);
    emit updateNth(nth);
}