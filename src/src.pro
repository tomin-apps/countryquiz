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
    components/statsdatabase.h \
    components/statsmodel.h

SOURCES += \
    components/map.cpp \
    components/mapmodel.cpp \
    components/maprenderer.cpp \
    components/options.cpp \
    components/resultssaver.cpp \
    components/statsdatabase.cpp \
    components/statsmodel.cpp \
    countryquiz.cpp

QMAKE_CLEAN += $$shadowed($$TARGET)