TEMPLATE = aux
TARGET = harbour-countryquiz

DISTFILES = \
    $$files(data_*.yaml) \
    $$files(flags/*.svg) \
    data.xml \
    map.svg \
    COPYING-CC-BY-SA-4.0.txt \
    README.md

LANGUAGES = en-GB fi-FI
for (lang, LANGUAGES) {
    INPUT_YAML = $$PWD/data_$${lang}.yaml
    OUTPUT_XML = $$shadowed(data_$${lang}.xml)
    data_$${lang}.CONFIG = no_check_exist
    data_$${lang}.depends = $$INPUT_YAML
    data_$${lang}.input = data_$${lang}.yaml
    data_$${lang}.output = $$OUTPUT_XML
    data_$${lang}.commands = python3 $$PWD/../tools/yaml2xml.py $$INPUT_YAML $$OUTPUT_XML
    data_$${lang}.files = $$OUTPUT_XML
    data_$${lang}.path = /usr/share/$${TARGET}/assets
    QMAKE_CLEAN += $$OUTPUT_XML
    QMAKE_EXTRA_TARGETS += data_$${lang}
    PRE_TARGETDEPS += data_$${lang}
    INSTALLS += data_$${lang}
}

data_xml.CONFIG = no_check_exist
data_xml.input = data.yaml
data_xml.output = $$shadowed(data.xml)
data_xml.commands = python3 $$PWD/../tools/yaml2xml.py --languages $$PWD/data.yaml $$shadowed(data.xml)
data_xml.files = $$shadowed(data.xml)
data_xml.path = /usr/share/$${TARGET}/assets
QMAKE_CLEAN += $$data_xml.files

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
tiles.extra = -cp -r $$shadowed(map_*) $(INSTALL_ROOT)$$tiles.path/
QMAKE_CLEAN += $$tiles.files $$files($$shadowed(map_*/*.png))

copying.files = COPYING.CC-BY-SA-4.0.txt
copying.path = /usr/share/$${TARGET}/assets

readme.files = README.md
readme.path = /usr/share/$${TARGET}/assets

QMAKE_EXTRA_TARGETS += data_xml tiles
PRE_TARGETDEPS += data_xml tiles
INSTALLS += copying data_xml flags map readme tiles