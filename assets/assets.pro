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

tiles.depends = $$PWD/map.svg
tiles.input = map.svg
tiles.commands = python3 $$PWD/../tools/tile_svg.py $$PWD/map.svg 20 10 $$shadowed(map_{x}_{y}.png) -s 4.0

tiles_install.CONFIG = no_check_exist
tiles_install.depends = tiles
tiles_install.path = /usr/share/$${TARGET}/assets

TILES_HORIZONTAL = $$system("seq 0 19", lines)
TILES_VERTICAL = $$system("seq 0 9", lines)
for (x, TILES_HORIZONTAL) {
    for (y, TILES_VERTICAL) {
        file = $$shadowed(map_$${x}_$${y}.png)
        tiles.output += $$file
        tiles_install.depends += $$file
        tiles_install.files += $$file
    }
}

tiles_txt.commands = echo '"map_%1_%2.png;20;10"' > $$shadowed(map.svg.txt)
tiles_txt.output = $$shadowed(map.svg.txt)

tiles_txt_install.CONFIG = no_check_exist
tiles_txt_install.depends = tiles_txt
tiles_txt_install.files = $$shadowed(map.svg.txt)
tiles_txt_install.path = /usr/share/$${TARGET}/assets

QMAKE_EXTRA_TARGETS += tiles tiles_txt
INSTALLS += flags map tiles_install tiles_txt_install
