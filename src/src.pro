TEMPLATE = app
TARGET = harbour-countryquiz
CONFIG += link_pkgconfig sailfishapp
QT += svg

INCLUDEPATH += \
    components/

HEADERS += \
    components/map.h \
    components/maprenderer.h

SOURCES += \
    components/map.cpp \
    components/maprenderer.cpp \
    countryquiz.cpp