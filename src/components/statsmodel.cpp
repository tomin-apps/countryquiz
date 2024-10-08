/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#include <QDateTime>
#include <QLoggingCategory>
#include <QQmlEngine>
#include <QSqlError>
#include <QThread>
#include <QThreadPool>
#include "statsdatabase.h"
#include "statsmodel.h"

Q_LOGGING_CATEGORY(lcStatsModel, "site.tomin.apps.CountryQuiz.StatsModel", QtWarningMsg)

StatsModel::StatsModel(QObject *parent)
    : QSqlQueryModel(parent)
    , m_options(new Options)
    , m_delayInitialization(false)
    , m_busy(false)
    , m_inMemoryDB(false)
    , m_orderByDate(false)
    , m_onlyOwnResults(false)
    , m_fetchAgain(false)
{
    qRegisterMetaType<QSqlQuery>();
    qRegisterMetaType<std::shared_ptr<Options>>();
    connect(options(), &Options::quizTypeChanged, this, [this] { refresh(); });
    connect(options(), &Options::numberOfQuestionsChanged, this, [this] { refresh(); });
    connect(options(), &Options::numberOfChoicesChanged, this, [this] { refresh(); });
    connect(options(), &Options::choicesFromChanged, this, [this] { refresh(); });
    connect(options(), &Options::timeToAnswerChanged, this, [this] { refresh(); });
    connect(options(), &Options::languageChanged, this, [this] { refresh(); });
}

void StatsModel::classBegin()
{
    m_delayInitialization = true;
}

void StatsModel::componentComplete()
{
    m_delayInitialization = false;
    refresh();
}

void StatsModel::refresh(bool force)
{
    if (!m_delayInitialization && m_options->isValid()) {
        if (!m_busy) {
            m_busy = true;
            emit busyChanged();
        } else if (!force) {
            qCDebug(lcStatsModel) << "Marking StatsModel to be fetched again later";
            m_fetchAgain = true;
            return;
        }
        auto *worker = new StatsModelWorker(m_inMemoryDB ? StatsDatabase::InMemoryType : StatsDatabase::OnDiskType,
                                            std::make_shared<Options>(*m_options), m_maxCount, m_since, m_orderByDate, m_onlyOwnResults);
        connect(worker, &StatsModelWorker::queryReady, this, [this](const QSqlQuery &query, std::shared_ptr<Options> options, int maxCount, qint64 since, bool orderByDate, bool onlyOwnResults) {
            if (*m_options == *options && m_maxCount == maxCount && m_since == since && m_orderByDate == orderByDate && m_onlyOwnResults == onlyOwnResults) {
                int rows = rowCount();
                if (!query.isActive())
                    qCWarning(lcStatsModel) << "Query is not active";
                if (query.isForwardOnly())
                    qCWarning(lcStatsModel) << "Query is forward only";
                setQuery(query);
                while (canFetchMore())
                    fetchMore();
                if (lastError().isValid())
                    qCWarning(lcStatsModel) << "Could not fetch rows from database" << lastError().text();
                else
                    qCDebug(lcStatsModel) << "Fetched" << rowCount() << "rows from database";
                if (rows != rowCount())
                    emit rowCountChanged();
                if (m_busy) {
                    m_busy = false;
                    emit busyChanged();
                }
            }
            if (m_fetchAgain) {
                m_fetchAgain = false;
                refresh(true);
            }
            options->deleteLater();
        }, Qt::QueuedConnection);
        worker->setAutoDelete(true);
        QThreadPool::globalInstance()->start(worker, QThread::LowPriority);
    }
}

Options *StatsModel::options() const
{
    return m_options.get();
}

bool StatsModel::busy() const
{
    return m_busy;
}

int StatsModel::maxCount() const
{
    return m_maxCount;
}

void StatsModel::setMaxCount(int maxCount)
{
    if (m_maxCount != maxCount) {
        m_maxCount = maxCount;
        emit maxCountChanged();
        refresh();
    }
}

QDateTime StatsModel::since() const
{
    return m_since != -1 ? QDateTime::fromTime_t(m_since) : QDateTime();
}

void StatsModel::setSince(QDateTime since)
{
    qint64 newSince = since.isValid() ? since.toTime_t() : -1;
    if (m_since != newSince) {
        m_since = newSince;
        emit sinceChanged();
        refresh();
    }
}

bool StatsModel::inMemoryDB() const
{
    return m_inMemoryDB;
}

void StatsModel::setInMemoryDB(bool inMemoryDB)
{
    if (m_inMemoryDB != inMemoryDB) {
        m_inMemoryDB = inMemoryDB;
        emit inMemoryDBChanged();
        refresh();
    }
}

bool StatsModel::orderByDate() const
{
    return m_orderByDate;
}

void StatsModel::setOrderByDate(bool orderByDate)
{
    if (m_orderByDate != orderByDate) {
        m_orderByDate = orderByDate;
        emit orderByDateChanged();
        refresh();
    }
}

bool StatsModel::onlyOwnResults() const
{
    return m_onlyOwnResults;
}

void StatsModel::setOnlyOwnResults(bool onlyOwnResults)
{
    if (m_onlyOwnResults != onlyOwnResults) {
        m_onlyOwnResults = onlyOwnResults;
        emit onlyOwnResultsChanged();
        refresh();
    }
}

QHash<int, QByteArray> StatsModel::roleNames() const
{
    return QHash<int, QByteArray> {
        { PositionRole, "position" },
        { NumberOfCorrectRole, "number_of_correct" },
        { TimeRole, "time" },
        { ScoreRole, "score" },
        { DateTimeRole, "datetime" },
        { NameRole, "name" },
        { LengthRole, "length" },
    };
}

QVariant StatsModel::data(const QModelIndex &index, int role) const
{
    if (role < Qt::UserRole)
        return QSqlQueryModel::data(index, role);

    if (index.row() < 0 || index.row() >= rowCount())
        return QVariant();

    switch (role) {
        case PositionRole:
            return QString("#%1").arg(index.row() + 1);
        case NumberOfCorrectRole:
            return QSqlQueryModel::data(QSqlQueryModel::index(index.row(), 0, QModelIndex()));
        case TimeRole:
            return QSqlQueryModel::data(QSqlQueryModel::index(index.row(), 1, QModelIndex()));
        case ScoreRole:
            return QSqlQueryModel::data(QSqlQueryModel::index(index.row(), 2, QModelIndex()));
        case DateTimeRole:
            return QDateTime::fromTime_t(
                    QSqlQueryModel::data(QSqlQueryModel::index(index.row(), 3, QModelIndex())).toLongLong(),
                    Qt::UTC);
        case NameRole:
            return QSqlQueryModel::data(QSqlQueryModel::index(index.row(), 4, QModelIndex()));
        case LengthRole:
            return QSqlQueryModel::data(QSqlQueryModel::index(index.row(), 5, QModelIndex()));
        case TimestampRole:
            return QSqlQueryModel::data(QSqlQueryModel::index(index.row(), 3, QModelIndex()));
    }

    return QVariant();
}

StatsModelWorker::StatsModelWorker(StatsDatabase::DatabaseType type, std::shared_ptr<Options> options, int maxCount, qint64 since, bool orderByDate, bool onlyOwnResults)
    : QObject(nullptr)
    , m_type(type)
    , m_options(options)
    , m_maxCount(maxCount)
    , m_since(since)
    , m_orderByDate(orderByDate)
    , m_onlyOwnResults(onlyOwnResults)
{
}

void StatsModelWorker::run()
{
    QSqlQuery query = StatsDatabase::query(m_type, m_options.get(), m_maxCount, m_since, m_orderByDate ? StatsDatabase::MostRecent : StatsDatabase::MostScore, m_onlyOwnResults);
    emit queryReady(query, m_options, m_maxCount, m_since, m_orderByDate, m_onlyOwnResults);
}


QObject *StatsHelper::instance(QQmlEngine *, QJSEngine *)
{
    return new StatsHelper;
}

QDateTime StatsHelper::getDateSixMonthsAgo() const
{
    return QDateTime::currentDateTimeUtc().addMonths(-6);
}