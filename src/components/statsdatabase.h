/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef STATSDATABASE_H
#define STATSDATABASE_H

#include <QSqlDatabase>
#include <QSqlQuery>

class Options;
class StatsDatabase
{
public:
    enum DatabaseType {
        InMemoryType,
        OnDiskType,
    };

    enum OrderBy {
        MostScore,
        MostRecent,
    };

    static void initialize(DatabaseType type);

    StatsDatabase(DatabaseType type);

    static std::pair<int, int> store(DatabaseType type, Options *options, int numberOfCorrect, int time, int score, time_t datetime, const QString &name);

    static QSqlQuery query(DatabaseType type, Options *options, int maxCount, int64_t since, OrderBy order, bool filtered = false, const QString &name = QString());

private:
    int getPosition(int64_t id, bool filtered);
    int getCount(int64_t id, bool filtered);
    void filterRecords(Options *options);
    int64_t insertRecord(Options *options, int numberOfCorrect, int time, int score, time_t datetime, const QString &name);
    void prepareOptions(Options *options);

    QSqlDatabase m_db;
};

#endif // STATSDATABASE_H