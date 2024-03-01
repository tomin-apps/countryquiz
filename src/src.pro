TEMPLATE = app
TARGET = harbour-countryquiz
CONFIG += link_pkgconfig sailfishapp
QT += svg

INCLUDEPATH += \
    components/

HEADERS += \
    components/map.h \
    components/mapmodel.h \
    components/maprenderer.h

SOURCES += \
    components/map.cpp \
    components/mapmodel.cpp \
    components/maprenderer.cpp \
    countryquiz.cpp

QMAKE_CLEAN += $$shadowed($$TARGET)