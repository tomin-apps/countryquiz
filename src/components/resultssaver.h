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

class ResultsSaver : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(Options *options READ options)
    Q_PROPERTY(int nth READ nth NOTIFY nthChanged)

public:
    ResultsSaver(QQuickItem *parent = nullptr);

    Options *options() const;
    int nth() const;

public slots:
    void save(const QList<bool> &correct, const QList<int> &times);

signals:
    void nthChanged();

private:
    static int numberOfCorrect(const QList<bool> &correct);
    static int time(const QList<int> &times);
    static time_t now();

    int calculateScore(const QList<bool> &correct, const QList<int> &times);
    bool checkResults(const QList<bool> &correct, const QList<int> &times);

    std::unique_ptr<Options> m_options;
    int m_nth;
};

class ResultsSaverWorker : public QObject, public QRunnable
{
    Q_OBJECT

public:
    ResultsSaverWorker(const Options &options, int numberOfCorrect, int time, int score, time_t datetime);

    void run() override;

signals:
    void updateNth(int nth);

private:
    Options m_options;
    int m_numberOfCorrect;
    int m_time;
    int m_score;
    time_t m_datetime;
};

#endif // RESULTSSAVER_H