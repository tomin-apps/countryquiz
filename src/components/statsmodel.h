/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef STATSMODEL_H
#define STATSMODEL_H

#include <memory>
#include <QDateTime>
#include <QObject>
#include <QQmlParserStatus>
#include <QRunnable>
#include <QSqlQueryModel>
#include "options.h"
#include "statsdatabase.h"

class StatsModel : public QSqlQueryModel, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    Q_PROPERTY(Options *options READ options NOTIFY optionsChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY rowCountChanged)
    Q_PROPERTY(int maxCount READ maxCount WRITE setMaxCount NOTIFY maxCountChanged)
    Q_PROPERTY(QDateTime since READ since WRITE setSince NOTIFY sinceChanged)
    Q_PROPERTY(bool inMemoryDB READ inMemoryDB WRITE setInMemoryDB NOTIFY inMemoryDBChanged)
    Q_PROPERTY(bool orderByDate READ orderByDate WRITE setOrderByDate NOTIFY orderByDateChanged)
    Q_PROPERTY(bool onlyOwnResults READ onlyOwnResults WRITE setOnlyOwnResults NOTIFY onlyOwnResultsChanged)

public:
    enum Roles {
        PositionRole = Qt::UserRole,
        NumberOfCorrectRole,
        TimeRole,
        ScoreRole,
        DateTimeRole,
        NameRole,
        LengthRole,
        TimestampRole,
    };

    StatsModel(QObject *parent = nullptr);
    void classBegin();
    void componentComplete();

    Options *options() const;

    bool busy() const;
    int maxCount() const;
    void setMaxCount(int maxCount);
    QDateTime since() const;
    void setSince(QDateTime since);
    bool inMemoryDB() const;
    void setInMemoryDB(bool inMemoryDB);
    bool orderByDate() const;
    void setOrderByDate(bool orderByDate);
    bool onlyOwnResults() const;
    void setOnlyOwnResults(bool onlyOwnResults);

    QHash<int, QByteArray> roleNames() const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;

public slots:
    void refresh();

signals:
    void rowCountChanged();
    void busyChanged();
    void maxCountChanged();
    void sinceChanged();
    void inMemoryDBChanged();
    void orderByDateChanged();
    void onlyOwnResultsChanged();
    void optionsChanged(); // Never emitted

private:
    std::unique_ptr<Options> m_options;
    int m_maxCount;
    qint64 m_since;
    bool m_delayInitialization : 1;
    bool m_busy : 1;
    bool m_inMemoryDB : 1;
    bool m_orderByDate : 1;
    bool m_onlyOwnResults : 1;
};

class StatsModelWorker : public QObject, public QRunnable
{
    Q_OBJECT

public:
    StatsModelWorker(StatsDatabase::DatabaseType type, Options *options, int maxCount, qint64 since, bool orderByDate, bool onlyOwnResults);

    void run() override;

signals:
    void queryReady(QSqlQuery query, Options *options, int maxCount, qint64 since, bool orderByDate, bool onlyOwnResults);

private:
    StatsDatabase::DatabaseType m_type;
    Options *m_options;
    int m_maxCount;
    qint64 m_since;
    bool m_orderByDate;
    bool m_onlyOwnResults;
};

Q_DECLARE_METATYPE(QSqlQuery);

#endif // STATSMODEL_H