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

    static void initialize(DatabaseType type);

    StatsDatabase(DatabaseType type);

    static int store(DatabaseType type, Options *options, int numberOfCorrect, int time, int score, time_t datetime, const QString &name);

    static QSqlQuery query(DatabaseType type, Options *options, int maxCount);

private:
    int getPosition(int64_t id);
    void filterRecords(Options *options);
    int64_t insertRecord(Options *options, int numberOfCorrect, int time, int score, time_t datetime, const QString &name);
    void prepareOptions(Options *options);

    QSqlDatabase m_db;
};

#endif // STATSDATABASE_H