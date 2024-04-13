/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import Nemo.Configuration 1.0
import QtQuick 2.6
import Sailfish.Silica 1.0
import "../helpers.js" as Helpers

ExpandingSection {
    property alias presets: presetModel.presets
    property alias quizType: presetModel.type
    readonly property int maximumLength: dataModel.count > 0 ? dataModel.getIndices(quizType).length : 0
    readonly property int questionCount: selectedCount === -1 ? maximumLength : selectedCount
    property alias selectedCount: selected.count
    readonly property bool presetCount: selectedCount === 15 || selectedCount ===  80 || selectedCount === -1

    id: expandingSection
    content.sourceComponent: Column {
        bottomPadding: Theme.paddingLarge
        width: parent.width

        SelectableDetailItem {
            label: qsTr("Preset")
            menu: ContextMenu {
                Repeater {
                    model: presetModel.presets
                    MenuItem { text: presetModel.getTitleText(model.name) }
                }

                onActivated: presetModel.selectPreset(index)
            }
            value: presetModel.presetTitle
        }

        SelectableDetailItem {
            label: qsTr("Questions")
            menu: ContextMenu {
                MenuItem { text: qsTr("Short") + " - 15" }
                MenuItem { text: qsTr("Long") + " - 80" }
                MenuItem { text: qsTr("All") + " - %1".arg(expandingSection.maximumLength) }
                MenuItem { text: qsTr("Custom value") }

                onActivated: {
                    switch (index) {
                    case 0:
                        expandingSection.selectedCount = 15
                        break
                    case 1:
                        expandingSection.selectedCount = 80
                        break
                    case 2:
                        expandingSection.selectedCount = -1
                        break
                    case 3:
                        var dialog = pageStack.push(Qt.resolvedUrl("../pages/IntSelectionPage.qml"), {
                            value: expandingSection.questionCount,
                            minimum: 1,
                            maximum: expandingSection.maximumLength,
                            title: qsTr("Select number of questions"),
                            description: qsTr("Questions"),
                            tooLowHint: qsTr("You must have at least one question"),
                            tooHighHint: qsTr("You may not have more than %1 questions").arg(expandingSection.maximumLength)
                        })
                        dialog.onAccepted.connect(function() {
                            if (dialog.selectedValue >= expandingSection.maximumLength) {
                                expandingSection.selectedCount = -1
                            } else {
                                expandingSection.selectedCount = dialog.selectedValue
                            }
                        })
                        break
                    }
                }
            }
            value: expandingSection.questionCount
        }

        SelectableDetailItem {
            label: qsTr("Choices")
            menu: ContextMenu {
                MenuItem { text: "3" }
                MenuItem { text: "4" }
                MenuItem { text: "5" }

                onActivated: presetModel.selectedChoices = 3 + index
            }

            value: presetModel.choicesCount
        }

        SelectableDetailItem {
            label: qsTr("Choices from")
            menu: ContextMenu {
                MenuItem { text: qsTr("Everywhere") }
                MenuItem { text: qsTr("Same region") }

                onActivated: presetModel.selectedRegion = index === 1
            }

            value: presetModel.sameRegion ? qsTr("Same region") : qsTr("Everywhere")
        }

        SelectableDetailItem {
            label: qsTr("Time to answer")
            menu: ContextMenu {
                MenuItem { text: "15 s" }
                MenuItem { text: "30 s" }
                MenuItem { text: "60 s" }
                MenuItem { text: qsTr("Custom value") }

                onActivated: {
                    switch (index) {
                    case 0:
                        presetModel.selectedTime = 15
                        break
                    case 1:
                        presetModel.selectedTime = 30
                        break
                    case 2:
                        presetModel.selectedTime = 60
                        break
                    case 3:
                        var minimum = 1
                        var maximum = 600
                        var dialog = pageStack.push(Qt.resolvedUrl("../pages/IntSelectionPage.qml"), {
                            value: presetModel.timeToAnswer,
                            minimum: minimum,
                            maximum: maximum,
                            title: qsTr("Select time to answer"),
                            description: qsTr("Seconds"),
                            tooLowHint: qsTr("You must have at least one second to answer the question"),
                            tooHighHint: qsTr("You may not have more than %1 seconds (%2 minutes) to answer the question").arg(maximum).arg(maximum / 60)
                        })
                        dialog.onAccepted.connect(function() {
                            presetModel.selectedTime = dialog.selectedValue
                        })
                        break
                    }
                }
            }
            value: qsTr("%1 s per question").arg(presetModel.timeToAnswer)
        }

        Item { height: Theme.paddingLarge; width: parent.width }

        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Quiz me!")

            onClicked:  {
                quizTimer.reset()
                pageStack.push(Qt.resolvedUrl("../pages/QuizPage.qml"), {
                                   indices: Helpers.pickRandomIndices(dataModel, dataModel.getIndices(expandingSection.quizType), expandingSection.questionCount),
                                   setup: {
                                       questionCount: expandingSection.questionCount,
                                       choicesCount: presetModel.choicesCount,
                                       sameRegion: presetModel.sameRegion,
                                       timeToAnswer: presetModel.timeToAnswer,
                                       quizType: expandingSection.quizType
                                   }
                               })
            }
        }
    }

    PresetModel { id: presetModel }

    Binding {
        target: page
        property: "presetModel"
        value: presetModel
        when: expandingSection.expanded
    }

    ConfigurationGroup {
        property int count: 15

        id: selected
        path: expandingSection.quizType ? "/site/tomin/apps/CountryQuiz/" + expandingSection.quizType : ""
    }
}