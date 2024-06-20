/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef RESULTSSAVER_H
#define RESULTSSAVER_H

#include <memory>
#include <QObject>
#include <QQuickItem>
#include <QRunnable>
#include "options.h"
#include "statsdatabase.h"

class ResultsSaver : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(Options *options READ options)
    Q_PROPERTY(int nth READ nth NOTIFY nthChanged)
    Q_PROPERTY(QString gameMode READ gameMode WRITE setGameMode NOTIFY gameModeChanged)

public:
    ResultsSaver(QQuickItem *parent = nullptr);

    Options *options() const;
    int nth() const;
    QString gameMode() const;
    void setGameMode(const QString &mode);

public slots:
    void save(const QList<bool> &correct, const QList<int> &times, const QString &name);

signals:
    void nthChanged();
    void gameModeChanged();

private:
    static int numberOfCorrect(const QList<bool> &correct);
    static int time(const QList<int> &times);
    static time_t now();

    int calculateScore(const QList<bool> &correct, const QList<int> &times);
    bool checkResults(const QList<bool> &correct, const QList<int> &times);
    StatsDatabase::DatabaseType getType() const;

    std::unique_ptr<Options> m_options;
    int m_nth;
    QString m_gameMode;
};

class ResultsSaverWorker : public QObject, public QRunnable
{
    Q_OBJECT

public:
    ResultsSaverWorker(StatsDatabase::DatabaseType type, const Options &options, int numberOfCorrect, int time, int score, time_t datetime, const QString &name);

    void run() override;

signals:
    void updateNth(int nth);

private:
    Options m_options;
    int m_numberOfCorrect;
    int m_time;
    int m_score;
    time_t m_datetime;
    QString m_name;
    StatsDatabase::DatabaseType m_type;
};

#endif // RESULTSSAVER_H