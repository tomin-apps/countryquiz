/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef OPTIONS_H
#define OPTIONS_H

#include <QObject>

class Options : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString quizType READ quizType WRITE setQuizType NOTIFY quizTypeChanged)
    Q_PROPERTY(int numberOfQuestions READ numberOfQuestions WRITE setNumberOfQuestions NOTIFY numberOfQuestionsChanged)
    Q_PROPERTY(int numberOfChoices READ numberOfChoices WRITE setNumberOfChoices NOTIFY numberOfChoicesChanged)
    Q_PROPERTY(QString choicesFrom READ choicesFrom WRITE setChoicesFrom NOTIFY choicesFromChanged)
    Q_PROPERTY(int timeToAnswer READ timeToAnswer WRITE setTimeToAnswer NOTIFY timeToAnswerChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)

public:
    explicit Options(QObject *parent = nullptr);
    explicit Options(const Options &options, QObject *parent = nullptr);

    bool isValid() const;

    QString quizType() const;
    void setQuizType(const QString &quizType);
    int numberOfQuestions() const;
    void setNumberOfQuestions(int numberOfQuestions);
    int numberOfChoices() const;
    void setNumberOfChoices(int numberOfChoices);
    QString choicesFrom() const;
    void setChoicesFrom(const QString &choicesFrom);
    int timeToAnswer() const;
    void setTimeToAnswer(int timeToAnswer);
    QString language() const;
    void setLanguage(const QString &language);

    bool operator==(const Options &other);

signals:
    void quizTypeChanged();
    void numberOfQuestionsChanged();
    void numberOfChoicesChanged();
    void choicesFromChanged();
    void timeToAnswerChanged();
    void languageChanged();

private:
    QString m_quizType;
    int m_numberOfQuestions;
    int m_numberOfChoices;
    QString m_choicesFrom;
    int m_timeToAnswer;
    QString m_language;
};

#endif // OPTIONS_H