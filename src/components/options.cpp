/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#include "options.h"

Options::Options(QObject *parent)
    : QObject(parent)
    , m_numberOfQuestions(0)
    , m_numberOfChoices(-1)
    , m_timeToAnswer(0)
{
}

Options::Options(const Options &other, QObject *parent)
    : QObject(parent)
    , m_quizType(other.m_quizType)
    , m_numberOfQuestions(other.m_numberOfQuestions)
    , m_numberOfChoices(other.m_numberOfChoices)
    , m_choicesFrom(other.m_choicesFrom)
    , m_timeToAnswer(other.m_timeToAnswer)
    , m_language(other.m_language)
{
}

bool Options::isValid() const
{
    return !m_quizType.isEmpty()
        &&  m_numberOfQuestions > 0
        &&  m_numberOfChoices >= 0
        && !m_choicesFrom.isEmpty()
        &&  m_timeToAnswer > 0
        && !m_language.isEmpty();
}

bool Options::operator==(const Options &other)
{
    return m_quizType == other.m_quizType
        && m_numberOfQuestions == other.m_numberOfQuestions
        && m_numberOfChoices == other.m_numberOfChoices
        && m_choicesFrom == other.m_choicesFrom
        && m_timeToAnswer == other.m_timeToAnswer
        && m_language == other.m_language;
}

QString Options::quizType() const
{
    return m_quizType;
}

void Options::setQuizType(const QString &type)
{
    if (m_quizType != type) {
        m_quizType = type;
        emit quizTypeChanged();
    }
}

int Options::numberOfQuestions() const
{
    return m_numberOfQuestions;
}

void Options::setNumberOfQuestions(int numberOfQuestions)
{
    if (m_numberOfQuestions != numberOfQuestions) {
        m_numberOfQuestions = numberOfQuestions;
        emit numberOfQuestionsChanged();
    }
}

int Options::numberOfChoices() const
{
    return m_numberOfChoices;
}

void Options::setNumberOfChoices(int numberOfChoices)
{
    if (m_numberOfChoices != numberOfChoices) {
        m_numberOfChoices = numberOfChoices;
        emit numberOfChoicesChanged();
    }
}

QString Options::choicesFrom() const
{
    return m_choicesFrom;
}

void Options::setChoicesFrom(const QString &choicesFrom)
{
    if (m_choicesFrom != choicesFrom) {
        m_choicesFrom = choicesFrom;
        emit choicesFromChanged();
    }
}

int Options::timeToAnswer() const
{
    return m_timeToAnswer;
}

void Options::setTimeToAnswer(int timeToAnswer)
{
    if (m_timeToAnswer != timeToAnswer) {
        m_timeToAnswer = timeToAnswer;
        emit timeToAnswerChanged();
    }
}

QString Options::language() const
{
    return m_language;
}

void Options::setLanguage(const QString &language)
{
    if (m_language != language) {
        m_language = language;
        emit languageChanged();
    }
}