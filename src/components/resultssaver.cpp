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
    const int TimeScore = 800;
    const int MinScore = 200;
    const int SecondsInMillisecond = 1000;
} // namespace

ResultsSaver::ResultsSaver(QQuickItem *parent)
    : QQuickItem(parent)
    , m_options(new Options)
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

int ResultsSaver::count() const
{
    return m_count;
}

QString ResultsSaver::gameMode() const
{
    return m_gameMode;
}

void ResultsSaver::setGameMode(const QString &gameMode)
{
    if (m_gameMode != gameMode) {
        m_gameMode = gameMode;
        emit gameModeChanged();
    }
}

StatsDatabase::DatabaseType ResultsSaver::getType() const
{
    if (m_gameMode == "party")
        return StatsDatabase::InMemoryType;
    return StatsDatabase::OnDiskType;
}

void ResultsSaver::save(const QList<bool> &correct, const QList<int> &times, const QString &name)
{
    if (m_nth != -1) {
        m_nth = -1;
        emit nthChanged();
    }
    if (m_count != 0) {
        m_count = 0;
        emit countChanged();
    }
    if (checkResults(correct, times)) {
        qCDebug(lcResultsSaver) << "Saving result";
        auto *worker = new ResultsSaverWorker(getType(), *m_options, numberOfCorrect(correct), time(times), calculateScore(correct, times), now(), name);
        connect(worker, &ResultsSaverWorker::updateNth, this, [this](int nth, int count) {
            if (m_nth != nth) {
                m_nth = nth;
                emit nthChanged();
            }
            if (m_count != count) {
                m_count = count;
                emit countChanged();
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
    if (m_gameMode.isEmpty()) {
        qCWarning(lcResultsSaver) << "Game mode is empty, not saving";
        return false;
    }

    if (m_gameMode == "anonymous") {
        qCDebug(lcResultsSaver) << "Game mode is anonymous, not saving";
        return false;
    }

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
        double correct = *(itCorrect++) ? 1 : 0;
        double time = *(itTimes++);
        score += correct * (static_cast<double>(TimeScore) * (1.0 - time / timeLimit) + MinScore);
    }
    return score;
}

ResultsSaverWorker::ResultsSaverWorker(StatsDatabase::DatabaseType type, const Options &options, int numberOfCorrect, int time, int score, time_t datetime, const QString &name)
    : QObject(nullptr)
    , m_options(options)
    , m_numberOfCorrect(numberOfCorrect)
    , m_time(time)
    , m_score(score)
    , m_datetime(datetime)
    , m_name(name)
    , m_type(type)
{
}

void ResultsSaverWorker::run()
{
    auto pair = StatsDatabase::store(m_type, &m_options, m_numberOfCorrect, m_time, m_score, m_datetime, m_name);
    emit updateNth(pair.first, pair.second);
}