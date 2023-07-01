TEMPLATE = aux
TARGET = harbour-countryquiz

DISTFILES = \
    $$files(flags/*.svg) \
    README.md

flags.files = $$files(flags/*.svg)
flags.path = /usr/share/$${TARGET}/assets/flags
INSTALLS += flags
