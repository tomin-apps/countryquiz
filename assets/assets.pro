TEMPLATE = aux
TARGET = harbour-countryquiz

DISTFILES = \
    $$files(flags/*.svg) \
    map.svg \
    README.md

flags.files = $$files(flags/*.svg)
flags.path = /usr/share/$${TARGET}/assets/flags

map.files = map.svg
map.path = /usr/share/$${TARGET}/assets

INSTALLS += flags map
