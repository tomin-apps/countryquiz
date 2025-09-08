/*
 * Copyright (c) 2025 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef STRINGHELPER_H
#define STRINGHELPER_H

#include <QObject>
#include <QQmlEngine>
#include <QString>

class StringHelper : public QObject
{
    Q_OBJECT
public:
    static QObject *instance(QQmlEngine *, QJSEngine *);

    Q_INVOKABLE QString cleanup(const QString &text);

    Q_INVOKABLE int levenshtein(const QString &a, const QString &b);
};

#endif // STRINGHELPER_H
