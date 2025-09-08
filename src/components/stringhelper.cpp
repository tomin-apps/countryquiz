/*
 * Copyright (c) 2025 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#include <QVector>
#include "stringhelper.h"

QObject *StringHelper::instance(QQmlEngine *, QJSEngine *)
{
    return new StringHelper;
}

QString StringHelper::cleanup(const QString &text)
{
    QString result;
    QString str = text.simplified().normalized(QString::NormalizationForm_KD);
    result.reserve(str.length());
    for (auto it = str.begin(); it != str.end(); ++it) {
        auto category = it->category();
        if (category != QChar::Mark_NonSpacing && category != QChar::Mark_SpacingCombining && category != QChar::Mark_Enclosing) {
            result += *it;
        }
    }
    return result.toLower();
}

// Levenshtein distance algorihm from Wikipedia
// https://en.wikipedia.org/wiki/Levenshtein_distance#Iterative_with_two_matrix_rows
int StringHelper::levenshtein(const QString &s, const QString &t)
{
    QVector<int> v0(t.length() + 1);
    QVector<int> v1(t.length() + 1);

    for (int i = 0; i <= t.length(); ++i) {
        v0[i] = i;
    }

    for (int i = 0; i < s.length(); ++i) {
        v1[0] = i + 1;
        for (int j = 0; j < t.length(); ++j) {
            int deletionCost = v0[j + 1] + 1;
            int insertionCost = v1[j] + 1;
            int substitutionCost = (s[i] == t[j]) ? v0[j] : (v0[j] + 1);
            v1[j + 1] = std::min(deletionCost, std::min(insertionCost, substitutionCost));
        }
        v0.swap(v1);
    }

    return v0[t.length()];
}