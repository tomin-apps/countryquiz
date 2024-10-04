/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import CountryQuiz 1.0
import Nemo.Configuration 1.0
import QtQuick 2.6
import Sailfish.Silica 1.0
import "../helpers.js" as Helpers

ExpandingSection {
    property ListModel presets
    property string quizType
    property alias statsModel: statsModelLoader.item
    property alias scoreModel: scoreModelLoader.item

    function updatePreset(index) {
        if (presets) {
            var preset = presets.get(index)
            if (statsModelLoader.status === Loader.Ready) {
                statsModel.options.numberOfChoices = preset.choices
                statsModel.options.choicesFrom = preset.region ? "same region" : "everywhere"
                statsModel.options.timeToAnswer = preset.time
                statsModel.options.language = dataModel.language
            }
            if (scoreModelLoader.status === Loader.Ready) {
                scoreModel.options.numberOfChoices = preset.choices
                scoreModel.options.choicesFrom = preset.region ? "same region" : "everywhere"
                scoreModel.options.timeToAnswer = preset.time
                scoreModel.options.language = dataModel.language
            }
        }
    }

    id: statsSection
    content.sourceComponent: Column {
        bottomPadding: placeholder.visible ? Theme.paddingLarge : Theme.paddingMedium
        states: [
            State {
                name: "default"
            },
            State {
                name: "busy"
                when: statsModelLoader.status !== Loader.Ready || statsModel.busy || scoreModelLoader.status !== Loader.Ready || scoreModel.busy

                PropertyChanges {
                    target: presetSelection
                    enabled: false
                    opacity: Theme.opacityLow
                }

                PropertyChanges {
                    target: lengthSelection
                    enabled: false
                    opacity: Theme.opacityLow
                }

                PropertyChanges {
                    target: stats
                    visible: false
                }

                PropertyChanges {
                    target: scoreGraph
                    visible: false
                }

                PropertyChanges {
                    target: indicator
                    running: true
                    visible: true
                }

                PropertyChanges {
                    target: placeholder
                    visible: false
                }
            }
        ]

        SelectableDetailItem {
            id: presetSelection
            //% "Preset"
            label: qsTrId("countryquiz-la-preset")
            menu: ContextMenu {
                Repeater {
                    model: presets
                    MenuItem { text: Helpers.getPresetTitleText(model.name) }
                }

                onActivated: {
                    selected.preset = index
                    updatePreset(index)
                }
            }
            value: presets ? Helpers.getPresetTitleText(presets.get(selected.preset).name) : ""
        }

        SelectableDetailItem {
            id: lengthSelection
            //% "Length"
            label: qsTrId("countryquiz-la-length")
            menu: ContextMenu {
                MenuItem { text: Helpers.getLengthTitleText("short") }
                MenuItem { text: Helpers.getLengthTitleText("long") }
                MenuItem { text: Helpers.getLengthTitleText("all") }

                onActivated: {
                    switch (index) {
                    case 0:
                        selected.numberOfQuestions = 15
                        lengthSelection.value = Helpers.getLengthTitleText("short")
                        break
                    case 1:
                        selected.numberOfQuestions = 80
                        lengthSelection.value = Helpers.getLengthTitleText("long")
                        break
                    case 2:
                        selected.numberOfQuestions = -1
                        lengthSelection.value = Helpers.getLengthTitleText("all")
                        break
                    }
                }
            }
            value: {
                switch (selected.numberOfQuestions) {
                case 15:
                    return Helpers.getLengthTitleText("short")
                case 80:
                    return Helpers.getLengthTitleText("long")
                case -1:
                    return Helpers.getLengthTitleText("all")
                }
                return "-"
            }

        }

        Item {
            height: Theme.paddingMedium
            width: parent.width
        }

        StatsList {
            id: stats
            model: statsModel && config.mode !== "anonymous" ? statsModel : 0
            visible: config.mode !== "anonymous"
            width: parent.width

            MouseArea {
                anchors.fill: parent
                onClicked: pageStack.push(Qt.resolvedUrl("../pages/StatsListPage.qml"), {
                    quizType: statsModel.options.quizType,
                    numberOfQuestions: statsModel.options.numberOfQuestions,
                    numberOfChoices: statsModel.options.numberOfChoices,
                    choicesFrom: statsModel.options.choicesFrom,
                    timeToAnswer: statsModel.options.timeToAnswer,
                    language: statsModel.options.language,
                    onlyOwnResults: statsModel.onlyOwnResults,
                    maxCount: 10,
                    inMemoryDB: statsModel.inMemoryDB,
                    title: statsSection.title,
                    subtitle: "%1 %2".arg(lengthSelection.value).arg(presetSelection.value)
                })
            }
        }

        Item {
            height: Theme.paddingMedium
            width: parent.width
            visible: stats.height !== 0
        }

        ScoreGraph {
            id: scoreGraph
            arrowTipSize: Screen.width * 0.025
            fillColor: Theme.rgba(palette.secondaryColor, Theme.opacityFaint)
            fontColor: palette.primaryColor
            font.pixelSize: Theme.fontSizeTiny
            height: Theme.itemSizeSmall * 4
            lineColor: palette.primaryColor
            lineWidth: 2
            model: scoreModel && config.mode === "solo" ? scoreModel : null
            secondaryLineColor: Theme.rgba(palette.secondaryColor, Theme.opacityHigh)
            visible: scoreModel && scoreModel.count > 0 && config.mode === "solo"
            width: parent.width - 2 * Theme.horizontalPageMargin
            x: Theme.horizontalPageMargin

            MouseArea {
                anchors.fill: parent
                onClicked: pageStack.push(Qt.resolvedUrl("../pages/ScoreGraphPage.qml"), {
                    scoreModel: scoreModel,
                    title: statsSection.title,
                    //% "%1 %2"
                    //: This is subtitle for stats list page, meant to say, e.g. Short Easy
                    //: %1 is length and %2 is preset name, you may swap them if that's more natural in your language
                    subtitle: qsTrId("countryquiz-la-length_and_preset").arg(lengthSelection.value).arg(presetSelection.value)
                })
            }
        }

        BusyIndicator {
            id: indicator
            anchors.horizontalCenter: parent.horizontalCenter
            size: BusyIndicatorSize.Large
            visible: false
        }

        Label {
            id: placeholder
            color: palette.secondaryHighlightColor
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeExtraLarge
            text: config.mode === "anonymous"
                //% "Stats are disabled in anonymous mode"
                ? qsTrId("countryquiz-la-stats_are_disabled_anonymous_mode")
                //% "This quiz has not been played yet"
                : qsTrId("countryquiz-la-has_not_been_played_yet")
            visible: (statsModel && statsModel.count === 0) || config.mode === "anonymous"
            wrapMode: Text.Wrap
            width: parent.width - 2 * Theme.horizontalPageMargin
            x: Theme.horizontalPageMargin
        }
    }

    Loader {
        id: statsModelLoader
        active: false
        asynchronous: true
        sourceComponent: Component {
            StatsModel {
                // @disable-check M17
                options.numberOfQuestions: selected.numberOfQuestions !== -1 ? selected.numberOfQuestions : dataModel.getIndices(quizType).length
                onlyOwnResults: config.mode === "solo"
                maxCount: config.mode === "solo" ? 5 : 10
                inMemoryDB: config.mode === "party"
            }
        }
        onStatusChanged: {
            if (status === Loader.Ready) {
                statsModel.options.quizType = quizType
                updatePreset(selected.preset)
            }
        }
    }

    Loader {
        id: scoreModelLoader
        active: statsModelLoader.active
        asynchronous: true
        sourceComponent: Component {
            StatsModel {
                inMemoryDB: config.mode === "party"
                maxCount: -1
                // @disable-check M17
                options.numberOfQuestions: selected.numberOfQuestions !== -1 ? selected.numberOfQuestions : dataModel.getIndices(quizType).length
                onlyOwnResults: true
                orderByDate: true
                since: StatsHelper.getDateSixMonthsAgo()
            }
        }
        onStatusChanged: {
            if (status === Loader.Ready) {
                scoreModel.options.quizType = quizType
                updatePreset(selected.preset)
            }
        }
    }

    Connections {
        target: signaler
        onResultSaved: {
            if (expanded) {
                if (statsModelLoader.status === Loader.Ready) {
                    statsModel.refresh()
                }
                if (scoreModelLoader.status === Loader.Ready) {
                    scoreModel.refresh()
                }
            } else {
                statsModelLoader.active = false
            }
        }
    }

    Connections {
        target: dataModel
        onLanguageChanged: updatePreset(selected.preset)
    }

    Binding {
        target: statsTab
        property: "openedSection"
        value: quizType
        when: expanded
    }

    ConfigurationGroup {
        property int preset: 0
        property int numberOfQuestions: 15

        id: selected
        path: "/site/tomin/apps/CountryQuiz/" + quizType + "/stats"
    }

    Component.onCompleted: statsModelLoader.active = expanded
    onPresetsChanged: updatePreset(selected.preset)
    onQuizTypeChanged: {
        if (statsModelLoader.status === Loader.Ready) {
            statsModel.options.quizType = quizType
        }
        if (scoreModelLoader.status === Loader.Ready) {
            scoreModel.options.quizType = quizType
        }
    }
    onExpandedChanged: statsModelLoader.active = true
}