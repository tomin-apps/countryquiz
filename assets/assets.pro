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

tiles.CONFIG = no_check_exist
tiles.depends = $$PWD/map.svg $$PWD/map.svg.txt.in $$PWD/../tools/tile_svg.py
tiles.input = map.svg map.svg.txt.in
tiles.output = $$shadowed(map.svg.txt)
tiles.commands = python3 $$PWD/../tools/tile_svg.py $$PWD/map.svg.txt.in -o $$shadowed('.')
tiles.files = $$shadowed(map.svg.txt)
tiles.path = /usr/share/$${TARGET}/assets
tiles.extra = -$(INSTALL_FILE) $$shadowed(map_*.png) $(INSTALL_ROOT)$$tiles.path/
QMAKE_CLEAN += $$tiles.files $$files($$shadowed(map_*.png))

QMAKE_EXTRA_TARGETS += tiles
PRE_TARGETDEPS += tiles
INSTALLS += flags map tiles