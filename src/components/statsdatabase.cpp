/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#include <QDir>
#include <QLoggingCategory>
#include <QSqlError>
#include <QSqlQuery>
#include <QSqlRecord>
#include <QStandardPaths>
#include "options.h"
#include "statsdatabase.h"

Q_LOGGING_CATEGORY(lcStatsDB, "site.tomin.apps.CountryQuiz.StatsDatabase", QtWarningMsg)

#define IN_MEMORY "memory"
#define ON_DISK "disk"

namespace {
    const auto InMemoryLocation = QStringLiteral(":memory:");

    QString databaseLocation()
    {
        QString path = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        if (path.isEmpty()) {
            qCWarning(lcStatsDB) << "Falling back to in memory database! Cannot save resuts!";
            return InMemoryLocation;
        }
        return QDir::cleanPath(path + "/stats.sqlite");
    }

    QString getNameFromType(StatsDatabase::DatabaseType type)
    {
        if (type == StatsDatabase::InMemoryType)
            return IN_MEMORY;
        return ON_DISK;
    }

    QString ensureEmpty(const QString &text)
    {
        return text.isEmpty() ? "" : text;
    }
};

void StatsDatabase::initialize(DatabaseType type)
{
    qCDebug(lcStatsDB) << "Available drivers:" << QSqlDatabase::drivers();
    auto db = QSqlDatabase::addDatabase("QSQLITE", getNameFromType(type));
    db.setDatabaseName(type == InMemoryType ? InMemoryLocation : databaseLocation());
    if (!db.open()) {
        qCCritical(lcStatsDB) << "Could not open stats database! Results cannot be read or saved!" << db.lastError().text();
        return;
    }

    QSqlQuery query(db);
    query.exec("PRAGMA foreign_keys = ON");
    if (query.isActive()) {
        qCDebug(lcStatsDB) << "Set foreign keys on";
        query.exec("CREATE TABLE IF NOT EXISTS options ("
                   "id INTEGER PRIMARY KEY, "
                   "type TEXT, "
                   "questions INTEGER, "
                   "choices INTEGER, "
                   "choices_from TEXT, "
                   "time_to_answer INTEGER, "
                   "language TEXT, "
                   "UNIQUE ( type, questions, choices, choices_from, time_to_answer, language ) ON CONFLICT IGNORE )");
    }
    if (query.isActive()) {
        qCDebug(lcStatsDB) << "Created options table";
        query.exec("CREATE TABLE IF NOT EXISTS records ("
                   "id INTEGER PRIMARY KEY, "
                   "options INTEGER REFERENCES options, "
                   "number_of_correct INTEGER, "
                   "time INTEGER, "
                   "score INTEGER, "
                   "datetime INTEGER, "
                   "name TEXT " // Reserved for later use, leave empty
                   ")");
    }
    if (query.isActive()) {
        qCDebug(lcStatsDB) << "Created records table";
    } else {
        qCCritical(lcStatsDB) << "Failed to setup database!" << query.lastError().text();
        db.close();
    }
}

StatsDatabase::StatsDatabase(DatabaseType type)
{
    m_db = QSqlDatabase::database(getNameFromType(type));
}

void StatsDatabase::prepareOptions(Options *options)
{
    QSqlQuery query(m_db);
    query.prepare("INSERT INTO options (type, questions, choices, choices_from, time_to_answer, language) "
                  "VALUES (:type, :n_questions, :n_choices, :choices_from, :time_to_answer, :lang)");
    query.bindValue(":type", options->quizType());
    query.bindValue(":n_questions", options->numberOfQuestions());
    query.bindValue(":n_choices", options->numberOfChoices());
    query.bindValue(":choices_from", options->choicesFrom());
    query.bindValue(":time_to_answer", options->timeToAnswer());
    query.bindValue(":lang", options->language());
    query.exec();
    if (!query.isActive())
        qCCritical(lcStatsDB) << "Failed to store options row";
}

int64_t StatsDatabase::insertRecord(Options *options, int numberOfCorrect, int time /* milliseconds */, int score, time_t datetime /* Unix epoch */, const QString &name)
{
    QSqlQuery query(m_db);
    query.prepare("INSERT INTO records (options, number_of_correct, time, score, datetime, name) "
                  "SELECT options.id, :n_correct, :time, :score, :dt, :name FROM options "
                  "WHERE type = :type AND questions = :n_questions AND choices = :n_choices AND choices_from = :choices_from "
                  "AND time_to_answer = :time_to_answer AND language = :lang");
    query.bindValue(":n_correct", numberOfCorrect);
    query.bindValue(":time", time);
    query.bindValue(":score", score);
    query.bindValue(":dt", (quint64)datetime);
    query.bindValue(":name", ensureEmpty(name));
    query.bindValue(":type", options->quizType());
    query.bindValue(":n_questions", options->numberOfQuestions());
    query.bindValue(":n_choices", options->numberOfChoices());
    query.bindValue(":choices_from", options->choicesFrom());
    query.bindValue(":time_to_answer", options->timeToAnswer());
    query.bindValue(":lang", options->language());
    query.exec();
    if (!query.isActive()) {
        qCCritical(lcStatsDB) << "Failed to store records row";
        return -1;
    }
    return query.lastInsertId().toLongLong();
}

int StatsDatabase::store(DatabaseType type, Options *options, int numberOfCorrect, int time, int score, time_t datetime, const QString &name)
{
    StatsDatabase db(type);
    db.prepareOptions(options);
    int64_t id = db.insertRecord(options, numberOfCorrect, time, score, datetime, name);
    return db.getPosition(id);
}

QSqlQuery StatsDatabase::query(DatabaseType type, Options *options, int maxCount, int64_t since, OrderBy order, bool filtered, const QString &name)
{
    auto db = QSqlDatabase::database(getNameFromType(type));
    QSqlQuery query(db);
    QString queryText("SELECT records.number_of_correct, records.time, records.score, records.datetime, records.name, options.questions "
                  "FROM records INNER JOIN options ON records.options = options.id WHERE ");
    if (filtered)
        queryText.append("records.name = :name AND ");
    if (since >= 0)
        queryText.append("records.datetime >= :since AND ");
    queryText.append("options.type = :type AND options.questions = :n_questions "
                  "AND options.choices = :n_choices AND options.choices_from = :choices_from "
                  "AND options.time_to_answer = :time_to_answer AND options.language = :lang ");
    if (order == MostScore)
        queryText.append("ORDER BY records.score DESC ");
    else if (order == MostRecent)
        queryText.append("ORDER BY records.datetime DESC ");
    if (maxCount >= 0)
        queryText.append("LIMIT :n_rows");
    query.prepare(queryText);
    query.bindValue(":type", options->quizType());
    query.bindValue(":n_questions", options->numberOfQuestions());
    query.bindValue(":n_choices", options->numberOfChoices());
    query.bindValue(":choices_from", options->choicesFrom());
    query.bindValue(":time_to_answer", options->timeToAnswer());
    query.bindValue(":lang", options->language());
    if (filtered)
        query.bindValue(":name", ensureEmpty(name));
    if (since >= 0)
        query.bindValue(":since", (qlonglong)since);
    if (maxCount >= 0)
        query.bindValue(":n_rows", maxCount);
    query.exec();
    return query;
}

int StatsDatabase::getPosition(int64_t id)
{
    QSqlQuery query(m_db);
    query.prepare("SELECT COUNT(records.id) FROM records "
                  "INNER JOIN records AS this ON records.options = this.options AND records.score > this.score "
                  "WHERE this.id = :id");
    query.bindValue(":id", (qlonglong)id);
    query.exec();
    if (!query.first()) {
        qCWarning(lcStatsDB) << "Could not fetch count!";
        return -1;
    }
    return query.value(0).toInt() + 1;
}