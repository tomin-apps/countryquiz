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

namespace {
    QString databaseLocation()
    {
        QString path = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        if (path.isEmpty()) {
            qCWarning(lcStatsDB) << "Falling back to in memory database! Cannot save resuts!";
            return QStringLiteral(":memory:");
        }
        return QDir::cleanPath(path + "/stats.sqlite");
    }
};

void StatsDatabase::initialize()
{
    qCDebug(lcStatsDB) << "Available drivers:" << QSqlDatabase::drivers();
    auto db = QSqlDatabase::addDatabase("QSQLITE");
    db.setDatabaseName(databaseLocation());
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

StatsDatabase::StatsDatabase()
{
    m_db = QSqlDatabase::database("QSQLITE");
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

int64_t StatsDatabase::insertRecord(Options *options, int numberOfCorrect, int time /* milliseconds */, int score, time_t datetime /* Unix epoch */)
{
    QSqlQuery query(m_db);
    query.prepare("INSERT INTO records (options, number_of_correct, time, score, datetime, name) "
                  "SELECT options.id, :n_correct, :time, :score, :dt, '' FROM options "
                  "WHERE type = :type AND questions = :n_questions AND choices = :n_choices AND choices_from = :choices_from "
                  "AND time_to_answer = :time_to_answer AND language = :lang");
    query.bindValue(":n_correct", numberOfCorrect);
    query.bindValue(":time", time);
    query.bindValue(":score", score);
    query.bindValue(":dt", (quint64)datetime);
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

int StatsDatabase::store(Options *options, int numberOfCorrect, int time, int score, time_t datetime)
{
    StatsDatabase db;
    db.prepareOptions(options);
    int64_t id = db.insertRecord(options, numberOfCorrect, time, score, datetime);
    return db.getPosition(id);
}

QSqlQuery StatsDatabase::query(Options *options, int maxCount /* TODO: Add more options for limiting and ordering */)
{
    auto db = QSqlDatabase::database("QSQLITE");
    QSqlQuery query(db);
    query.prepare("SELECT records.number_of_correct, records.time, records.score, records.datetime, records.name, options.questions "
                  "FROM records INNER JOIN options ON records.options = options.id "
                  "WHERE options.type = :type AND options.questions = :n_questions "
                  "AND options.choices = :n_choices AND options.choices_from = :choices_from "
                  "AND options.time_to_answer = :time_to_answer AND options.language = :lang "
                  "ORDER BY score DESC LIMIT :n_rows");
    query.bindValue(":type", options->quizType());
    query.bindValue(":n_questions", options->numberOfQuestions());
    query.bindValue(":n_choices", options->numberOfChoices());
    query.bindValue(":choices_from", options->choicesFrom());
    query.bindValue(":time_to_answer", options->timeToAnswer());
    query.bindValue(":lang", options->language());
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