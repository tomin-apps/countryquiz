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

    function updatePreset(index) {
        if (!presets || statsModelLoader.status !== Loader.Ready) {
            return
        }
        var preset = presets.get(index)
        statsModel.options.numberOfChoices = preset.choices
        statsModel.options.choicesFrom = preset.region ? "same region" : "everywhere"
        statsModel.options.timeToAnswer = preset.time
        statsModel.options.language = dataModel.language
    }

    content.sourceComponent: Column {
        bottomPadding: Theme.paddingMedium
        states: [
            State {
                name: "default"
            },
            State {
                name: "busy"
                when: statsModelLoader.status !== Loader.Ready || statsModel.busy

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
            height: Theme.paddingSmall
            width: parent.width
        }

        ListView {
            id: stats
            boundsBehavior: Flickable.StopAtBounds
            height: (statsModel ? statsModel.count : 0) * Theme.itemSizeSmall
            delegate: Item {
                height: Theme.itemSizeSmall
                width: ListView.view.width

                Label {
                    id: positionLabel
                    anchors {
                        left: parent.left
                        leftMargin: Theme.paddingMedium
                        verticalCenter: parent.verticalCenter
                    }
                    color: palette.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeLarge
                    text: model.position
                }

                Label {
                    anchors {
                        left: positionLabel.right
                        leftMargin: Theme.paddingMedium
                        top: parent.top
                    }
                    color: palette.highlightColor
                    //% "You"
                    text: model.name || qsTrId("countryquiz-la-you")
                    truncationMode: TruncationMode.Fade
                    width: parent.width - positionLabel.width - scoreLabel.width - Theme.paddingMedium * 4
                }

                Label {
                    anchors {
                        left: positionLabel.right
                        leftMargin: Theme.paddingMedium
                        bottom: parent.bottom
                    }
                    color: palette.secondaryHighlightColor
                    //: %1 is the date when the game was played, try to keep this short
                    //% "On %1"
                    text: qsTrId("countryquiz-la-on_date").arg(model.datetime.toLocaleString(Qt.locale(), Locale.ShortFormat))
                }

                Label {
                    id: scoreLabel
                    anchors {
                        right: parent.right
                        rightMargin: Theme.paddingMedium
                        top: parent.top
                    }
                    color: palette.highlightColor
                    //: %1 is number of right answers out of %2 total answer to reward %3 points, try to keep this short
                    //% "%1 / %2 for %3 p"
                    text: qsTrId("countryquiz-la-questions_out_of_questions_for_points")
                            .arg(model.number_of_correct)
                            .arg(model.length)
                            .arg(model.score)
                }

                Label {
                    anchors {
                        right: parent.right
                        rightMargin: Theme.paddingMedium
                        bottom: parent.bottom
                    }
                    color: palette.secondaryHighlightColor
                    //: %1 is time that it took to finish the quiz, try to keep this short
                    //% "In %1"
                    text: qsTrId("countryquiz-la-in_time_as_sentence").arg(Helpers.timeAsString(model.time))
                }
            }
            model: statsModel && config.mode !== "anonymous" ? statsModel : 0
            visible: config.mode !== "anonymous"
            width: parent.width
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
                maxCount: 10
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

    Connections {
        target: signaler
        onResultSaved: {
            if (expanded) {
                if (statsModelLoader.status === Loader.Ready) {
                    statsModel.refresh()
                }
            } else {
                statsModelLoader.active = false
            }
        }
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
    onQuizTypeChanged: if (statsModelLoader.status === Loader.Ready) statsModel.options.quizType = quizType
    onExpandedChanged: statsModelLoader.active = true
}