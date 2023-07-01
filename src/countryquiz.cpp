/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

#include <QGuiApplication>
#include <QQuickView>
#include <QScopedPointer>
#include <sailfishapp.h>

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

    view->setSource(SailfishApp::pathToMainQml());
    view->show();
    return app->exec();
}
