TEMPLATE = app
TARGET = harbour-countryquiz
CONFIG += link_pkgconfig sailfishapp
QT += sql svg

INCLUDEPATH += \
    components/

HEADERS += \
    components/map.h \
    components/mapmodel.h \
    components/maprenderer.h \
    components/options.h \
    components/resultssaver.h \
    components/scoregraph.h \
    components/statsdatabase.h \
    components/statsmodel.h \
    components/stringhelper.h

SOURCES += \
    components/map.cpp \
    components/mapmodel.cpp \
    components/maprenderer.cpp \
    components/options.cpp \
    components/resultssaver.cpp \
    components/scoregraph.cpp \
    components/statsdatabase.cpp \
    components/statsmodel.cpp \
    components/stringhelper.cpp \
    countryquiz.cpp

QMAKE_CLEAN += $$shadowed($$TARGET)