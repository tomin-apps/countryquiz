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

tiles_1.depends = $$PWD/map.svg
tiles_1.input = map.svg
tiles_1.commands = python3 $$PWD/../tools/tile_svg.py $$PWD/map.svg 10 5 $$shadowed(map_1_{x}_{y}.png) -s 1.0

tiles_2.depends = $$PWD/map.svg
tiles_2.input = map.svg
tiles_2.commands = python3 $$PWD/../tools/tile_svg.py $$PWD/map.svg 10 5 $$shadowed(map_2_{x}_{y}.png) -s 2.0

tiles_4.depends = $$PWD/map.svg
tiles_4.input = map.svg
tiles_4.commands = python3 $$PWD/../tools/tile_svg.py $$PWD/map.svg 20 10 $$shadowed(map_4_{x}_{y}.png) -s 4.0

tiles_install.CONFIG = no_check_exist
tiles_install.depends = tiles_1 tiles_2 tiles_4
tiles_install.path = /usr/share/$${TARGET}/assets

TILES_HORIZONTAL = $$system("seq 0 9", lines)
TILES_VERTICAL = $$system("seq 0 4", lines)
for (x, TILES_HORIZONTAL) {
    for (y, TILES_VERTICAL) {
        file = $$shadowed(map_1_$${x}_$${y}.png)
        tiles_1.output += $$file
        tiles_install.depends += $$file
        tiles_install.files += $$file
    }
}

TILES_HORIZONTAL = $$system("seq 0 9", lines)
TILES_VERTICAL = $$system("seq 0 4", lines)
for (x, TILES_HORIZONTAL) {
    for (y, TILES_VERTICAL) {
        file = $$shadowed(map_2_$${x}_$${y}.png)
        tiles_2.output += $$file
        tiles_install.depends += $$file
        tiles_install.files += $$file
    }
}

TILES_HORIZONTAL = $$system("seq 0 19", lines)
TILES_VERTICAL = $$system("seq 0 9", lines)
for (x, TILES_HORIZONTAL) {
    for (y, TILES_VERTICAL) {
        file = $$shadowed(map_4_$${x}_$${y}.png)
        tiles_4.output += $$file
        tiles_install.depends += $$file
        tiles_install.files += $$file
    }
}

tiles_txt.commands = echo -e '"map_1_%1_%2.png;1;10;5\nmap_2_%1_%2.png;2;10;5\nmap_4_%1_%2.png;4;20;10"' > $$shadowed(map.svg.txt)
tiles_txt.output = $$shadowed(map.svg.txt)

tiles_txt_install.CONFIG = no_check_exist
tiles_txt_install.depends = tiles_txt
tiles_txt_install.files = $$shadowed(map.svg.txt)
tiles_txt_install.path = /usr/share/$${TARGET}/assets

QMAKE_EXTRA_TARGETS += tiles_1 tiles_2 tiles_4 tiles_txt
INSTALLS += flags map tiles_install tiles_txt_install
