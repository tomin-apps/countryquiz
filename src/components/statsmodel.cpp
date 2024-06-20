/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#include <QDateTime>
#include <QLoggingCategory>
#include <QSqlError>
#include <QThread>
#include <QThreadPool>
#include "statsdatabase.h"
#include "statsmodel.h"

Q_LOGGING_CATEGORY(lcStatsModel, "site.tomin.apps.CountryQuiz.StatsModel", QtWarningMsg)

StatsModel::StatsModel(QObject *parent)
    : QSqlQueryModel(parent)
    , m_options(new Options)
    , m_maxCount(10)
    , m_delayInitialization(false)
    , m_busy(false)
    , m_inMemoryDB(false)
{
    qRegisterMetaType<QSqlQuery>();
    connect(options(), &Options::quizTypeChanged, this, &StatsModel::refresh);
    connect(options(), &Options::numberOfQuestionsChanged, this, &StatsModel::refresh);
    connect(options(), &Options::numberOfChoicesChanged, this, &StatsModel::refresh);
    connect(options(), &Options::choicesFromChanged, this, &StatsModel::refresh);
    connect(options(), &Options::timeToAnswerChanged, this, &StatsModel::refresh);
    connect(options(), &Options::languageChanged, this, &StatsModel::refresh);
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

void StatsModel::refresh()
{
    if (!m_delayInitialization && m_options->isValid()) {
        if (!m_busy) {
            m_busy = true;
            emit busyChanged();
        }
        auto *worker = new StatsModelWorker(m_inMemoryDB ? StatsDatabase::InMemoryType : StatsDatabase::OnDiskType,
                                            new Options(*m_options), m_maxCount);
        connect(worker, &StatsModelWorker::queryReady, this, [this](const QSqlQuery &query, Options *options, int maxCount) {
            if (*m_options == *options && m_maxCount == maxCount) {
                int rows = rowCount();
                if (!query.isActive())
                    qCWarning(lcStatsModel) << "Query is not active";
                if (query.isForwardOnly())
                    qCWarning(lcStatsModel) << "Query is forward only";
                setQuery(query);
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

QHash<int, QByteArray> StatsModel::roleNames() const
{
    return QHash<int, QByteArray> {
        { Qt::UserRole + 0, "position" },
        { Qt::UserRole + 1, "number_of_correct" },
        { Qt::UserRole + 2, "time" },
        { Qt::UserRole + 3, "score" },
        { Qt::UserRole + 4, "datetime" },
        { Qt::UserRole + 5, "name" },
        { Qt::UserRole + 6, "length" },
    };
}

QVariant StatsModel::data(const QModelIndex &index, int role) const
{
    if (role < Qt::UserRole)
        return QSqlQueryModel::data(index, role);

    if (index.row() < 0 || index.row() >= rowCount())
        return QVariant();

    switch (role) {
        case Qt::UserRole:
            return QString("#%1").arg(index.row() + 1);
        case Qt::UserRole + 1:
            return QSqlQueryModel::data(QSqlQueryModel::index(index.row(), 0, QModelIndex()));
        case Qt::UserRole + 2:
            return QSqlQueryModel::data(QSqlQueryModel::index(index.row(), 1, QModelIndex()));
        case Qt::UserRole + 3:
            return QSqlQueryModel::data(QSqlQueryModel::index(index.row(), 2, QModelIndex()));
        case Qt::UserRole + 4:
            return QDateTime::fromMSecsSinceEpoch(
                    QSqlQueryModel::data(QSqlQueryModel::index(index.row(), 3, QModelIndex())).toLongLong() * 1000,
                    Qt::UTC);
        case Qt::UserRole + 5:
            return QSqlQueryModel::data(QSqlQueryModel::index(index.row(), 4, QModelIndex()));
        case Qt::UserRole + 6:
            return QSqlQueryModel::data(QSqlQueryModel::index(index.row(), 5, QModelIndex()));
    }

    return QVariant();
}

StatsModelWorker::StatsModelWorker(StatsDatabase::DatabaseType type, Options *options, int maxCount)
    : QObject(nullptr)
    , m_options(options)
    , m_maxCount(maxCount)
    , m_type(type)
{
}

void StatsModelWorker::run()
{
    QSqlQuery query = StatsDatabase::query(m_type, m_options, m_maxCount);
    emit queryReady(query, m_options, m_maxCount);
}