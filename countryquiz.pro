TEMPLATE = subdirs
TARGET = harbour-countryquiz
SUBDIRS = assets src

CONFIG += sailfishapp

DISTFILES += \
    COPYING \
    harbour-countryquiz.desktop \
    qml/components/Config.qml \
    qml/components/CountryListDelegateModel.qml \
    qml/components/DataModel.qml \
    qml/components/LanguageModel.qml \
    qml/components/PresetModel.qml \
    qml/components/QuizButton.qml \
    qml/components/QuizSection.qml \
    qml/components/QuizTimer.qml \
    qml/components/SelectableDetailItem.qml \
    qml/components/StatsSection.qml \
    qml/components/Tabs.qml \
    qml/harbour-countryquiz.qml \
    qml/helpers.js \
    qml/pages/CountryListTab.qml \
    qml/pages/CountryPage.qml \
    qml/pages/IntSelectionPage.qml \
    qml/pages/OptionsPage.qml \
    qml/pages/QuizPage.qml \
    qml/pages/QuizSelectionTab.qml \
    qml/pages/ResultsPage.qml \
    qml/pages/StatsTab.qml \
    qml/presets/FlagQuizPresets.qml \
    qml/presets/MapQuizPresets.qml \
    qml/presets/CapitalQuizPresets.qml \
    README.md \
    rpm/harbour-countryquiz.spec \
    translations/*.ts \
    tools/compare_svg.py \
    tools/create_fake_stats.py \
    tools/tile_svg.py \
    tools/yaml2xml.py

# Translations
TS_FILE = $$PWD/translations/harbour-countryquiz.ts
EE_DIR = $$shadowed(translations)
EE_QM = $$shadowed(translations/harbour-countryquiz.qm)

qtPrepareTool(LUPDATE, lupdate)
ts_ee.commands = $$LUPDATE $$PWD/src $$PWD/qml -ts $$TS_FILE
ts_ee.input = $$DISTFILES
ts_ee.output = $$TS_FILE
ts_ee.target = $$TS_FILE
PRE_TARGETDEPS += ts_ee
QMAKE_EXTRA_TARGETS += ts_ee

qtPrepareTool(LRELEASE, lrelease)
qm_ee.commands = mkdir -p $$EE_DIR && $$LRELEASE -idbased $$TS_FILE -qm $$EE_QM
qm_ee.depends = ts_ee
qm_ee.input = $$TS_FILE
qm_ee.output = $$EE_QM
qm_ee.target = $$EE_QM

qm_ee_install.CONFIG = no_check_exist
qm_ee_install.depends = qm_ee
qm_ee_install.files = $$EE_QM
qm_ee_install.path = /usr/share/$$TARGET/translations

QMAKE_CLEAN += $$EE_QM
QMAKE_EXTRA_TARGETS += qm_ee
PRE_TARGETDEPS += qm_ee
INSTALLS += qm_ee_install

CONFIG += sailfishapp_i18n sailfishapp_i18n_idbased
TRANSLATIONS += translations/harbour-countryquiz-fi.ts
for (file, TRANSLATIONS) {
    QMAKE_CLEAN += $$shadowed($$file)
    file ~= s/\.ts/.qm
    QMAKE_CLEAN += $$shadowed($$file)
}

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
    icon_$${size}.target = $$icon_path

    icon_$${size}_install.CONFIG = no_check_exist
    icon_$${size}_install.depends = icon_$${size}
    icon_$${size}_install.files = $$icon_path
    icon_$${size}_install.path = /usr/share/icons/hicolor/$${size}x$${size}/apps

    QMAKE_EXTRA_TARGETS += icon_$${size}
    PRE_TARGETDEPS += icon_$${size}
    QMAKE_CLEAN += $$icon_path
    INSTALLS += icon_$${size}_install
}

static_files.files = COPYING README.md $$ICON_SOURCE
static_files.path = /usr/share/$${TARGET}
INSTALLS += static_files