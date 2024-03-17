/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef STATSMODEL_H
#define STATSMODEL_H

#include <memory>
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

public:
    StatsModel(QObject *parent = nullptr);
    void classBegin();
    void componentComplete();

    Options *options() const;

    bool busy() const;
    int maxCount() const;
    void setMaxCount(int maxCount);

    QHash<int, QByteArray> roleNames() const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;

public slots:
    void refresh();

signals:
    void rowCountChanged();
    void busyChanged();
    void maxCountChanged();
    void optionsChanged(); // Never emitted

private:
    std::unique_ptr<Options> m_options;
    int m_maxCount;
    bool m_delayInitialization;
    bool m_busy;
};

class StatsModelWorker : public QObject, public QRunnable
{
    Q_OBJECT

public:
    StatsModelWorker(Options *options, int maxCount);

    void run() override;

signals:
    void queryReady(QSqlQuery query, Options *options, int maxCount);

private:
    Options *m_options;
    int m_maxCount;
};

Q_DECLARE_METATYPE(QSqlQuery);

#endif // STATSMODEL_H