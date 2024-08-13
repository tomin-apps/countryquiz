/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#include <QGuiApplication>
#include <QQuickView>
#include <QScopedPointer>
#include <QTranslator>
#include <sailfishapp.h>

#include "map.h"
#include "mapmodel.h"
#include "options.h"
#include "resultssaver.h"
#include "scoregraph.h"
#include "statsdatabase.h"
#include "statsmodel.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    QTranslator eeTranslator;
    if (eeTranslator.load("harbour-countryquiz", SailfishApp::pathTo("translations").toLocalFile(), ".qm"))
        app->installTranslator(&eeTranslator);
    QTranslator translator;
    if (translator.load(QLocale::system(), "harbour-countryquiz", "-", SailfishApp::pathTo("translations").toLocalFile(), ".qm"))
        app->installTranslator(&translator);

    StatsDatabase::initialize(StatsDatabase::OnDiskType);
    StatsDatabase::initialize(StatsDatabase::InMemoryType);
    qmlRegisterType<Map>("CountryQuiz", 1, 0, "Map");
    qmlRegisterType<MapModel>("CountryQuiz", 1, 0, "MapModel");
    qmlRegisterType<Options>();
    qmlRegisterType<ResultsSaver>("CountryQuiz", 1, 0, "ResultsSaver");
    qmlRegisterType<ScoreGraph>("CountryQuiz", 1, 0, "ScoreGraph");
    qmlRegisterSingletonType<StatsHelper>("CountryQuiz", 1, 0, "StatsHelper", &StatsHelper::instance);
    qmlRegisterType<StatsModel>("CountryQuiz", 1, 0, "StatsModel");
    view->setSource(SailfishApp::pathToMainQml());
    view->show();
    return app->exec();
}