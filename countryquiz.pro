TEMPLATE = subdirs
TARGET = harbour-countryquiz
SUBDIRS = assets src

CONFIG += sailfishapp

DISTFILES += \
    harbour-countryquiz.desktop \
    qml/components/Config.qml \
    qml/components/QuizButton.qml \
    qml/components/QuizTimer.qml \
    qml/components/SelectableDetailItem.qml \
    qml/components/Tabs.qml \
    qml/Data.qml \
    qml/harbour-countryquiz.qml \
    qml/helpers.js \
    qml/pages/Flags.qml \
    qml/pages/Flag.qml \
    qml/pages/IntSelection.qml \
    qml/pages/Quiz.qml \
    qml/pages/Results.qml \
    qml/pages/Selection.qml \
    rpm/harbour-countryquiz.spec \
    translations/*.ts

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += sailfishapp_i18n
TRANSLATIONS += translations/harbour-countryquiz-fi.ts

ICON_SIZES = 86 108 128 172
ICON_SOURCE = $$PWD/harbour-countryquiz.svg
for (size, ICON_SIZES) {
    icon_dir = $$shadowed(icons/$${size}x$${size})
    icon_path = $${icon_dir}/$${TARGET}.png

    icon_$${size}.commands = mkdir -p $$icon_dir $$escape_expand(\n\t)
    icon_$${size}.commands += rsvg-convert --width=$${size} --height=$${size} \
            --output $$icon_path $$ICON_SOURCE $$escape_expand(\n\t)
    icon_$${size}.depends = $$ICON_SOURCE
    icon_$${size}.output = $$icon_path

    icon_$${size}_install.CONFIG = no_check_exist
    icon_$${size}_install.depends = icon_$${size}
    icon_$${size}_install.files = $$icon_path
    icon_$${size}_install.path = /usr/share/icons/hicolor/$${size}x$${size}/apps

    QMAKE_EXTRA_TARGETS += icon_$${size}
    PRE_TARGETDEPS += icon_$${size}
    INSTALLS += icon_$${size}_install
}