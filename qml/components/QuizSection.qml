/*
 * Copyright (c) 2024 - 2025 Tomi Leppänen
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
    readonly property int maximumLength: {dataModel.ready; return dataModel.count > 0 ? dataModel.getIndices(quizType).length : 0}
    readonly property int questionCount: selectedCount === -1 ? maximumLength : selectedCount
    property alias selectedCount: selected.count
    readonly property bool presetCount: selectedCount === 15 || selectedCount ===  80 || selectedCount === -1

    id: expandingSection
    content.sourceComponent: Column {
        bottomPadding: Theme.paddingLarge
        width: parent.width

        SelectableDetailItem {
            //% "Preset"
            label: qsTrId("countryquiz-la-preset")
            menu: ContextMenu {
                Repeater {
                    model: presetModel.presets
                    MenuItem { text: Helpers.getPresetTitleText(model.name) }
                }

                onActivated: presetModel.selectPreset(index)
            }
            value: presetModel.presetTitle
        }

        SelectableDetailItem {
            //: Menu for the number of questions to be asked
            //% "Questions"
            label: qsTrId("countryquiz-la-questions")
            menu: ContextMenu {
                MenuItem { text: Helpers.getLengthTitleText("short") + " - 15" }
                MenuItem { text: Helpers.getLengthTitleText("long") + " - 80" }
                MenuItem { text: Helpers.getLengthTitleText("all") + " - %1".arg(expandingSection.maximumLength) }
                //% "Custom value"
                MenuItem { text: qsTrId("countryquiz-me-custom_value") }

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
                            //% "Select number of questions"
                            title: qsTrId("countryquiz-he-select-number-of-questions"),
                            //: Header for page to select the number of questions
                            //% "Questions"
                            description: qsTrId("countryquiz-he-questions"),
                            //% "You must have at least one question"
                            tooLowHint: qsTrId("countryquiz-la-at_least_one_question_hint"),
                            //% "You may not have more than %1 questions"
                            tooHighHint: qsTrId("countryquiz-la-not_more_than_questions_hint").arg(expandingSection.maximumLength)
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
            //: Menu for number of choices to choose from
            //% "Choices"
            label: qsTrId("countryquiz-la-choices")
            menu: ContextMenu {
                MenuItem { text: "3" }
                MenuItem { text: "4" }
                MenuItem { text: "5" }

                onActivated: presetModel.selectedChoices = 3 + index
            }

            value: presetModel.choicesCount
        }

        SelectableDetailItem {
            //: Menu to select area of choices
            //% "Choices from"
            label: qsTrId("countryquiz-la-choices_from")
            menu: ContextMenu {
                //: Choices from anywhere on Earth
                //% "Everywhere"
                MenuItem { text: qsTrId("countryquiz-me-everywhere") }
                //: Choices from sama region as the right answer
                //% "Same region"
                MenuItem { text: qsTrId("countryquiz-me-same_region") }

                onActivated: presetModel.selectedRegion = index === 1
            }

            value: presetModel.sameRegion
                   ? //% "Same region"
                     qsTrId("countryquiz-me-same_region")
                   : //% "Everywhere"
                     qsTrId("countryquiz-me-everywhere")
        }

        SelectableDetailItem {
            //: Menu to select time to answer the question
            //% "Time to answer"
            label: qsTrId("countryquiz-la-time_to_answer")
            menu: ContextMenu {
                MenuItem { text: "15 s" }
                MenuItem { text: "30 s" }
                MenuItem { text: "60 s" }
                //: Menu item to select some other value for time to answer
                //% "Custom value"
                MenuItem { text: qsTrId("countryquiz-me-custom_value") }

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
                            //% "Select time to answer"
                            title: qsTrId("countryquiz-la-select_time_to_answer"),
                            //% "Seconds"
                            description: qsTrId("countryquiz-la-seconds"),
                            //% "You must have at least one second to answer the question"
                            tooLowHint: qsTrId("countryquiz-la-at_least_second_hint"),
                            //% "You may not have more than %1 seconds (%2 minutes) to answer the question"
                            tooHighHint: qsTrId("countryquiz-la-not_more_than_seconds_hint").arg(maximum).arg(maximum / 60)
                        })
                        dialog.onAccepted.connect(function() {
                            presetModel.selectedTime = dialog.selectedValue
                        })
                        break
                    }
                }
            }
            //% "%1 s per question"
            value: qsTrId("countryquiz-la-seconds_per_question").arg(presetModel.timeToAnswer)
        }

        Item { height: Theme.paddingLarge; width: parent.width }

        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            //: Button to start quiz
            //% "Quiz me!"
            text: qsTrId("countryquiz-bt-quiz_me")

            onClicked:  {
                quizTimer.reset()
                appWindow.progress = 0
                appWindow.total = expandingSection.questionCount
                appWindow.quizType = expandingSection.quizType
                pageStack.push(Qt.resolvedUrl("../pages/QuizPage.qml"), {
                                   indices: Helpers.pickRandomIndices(dataModel, dataModel.getIndices(expandingSection.quizType), expandingSection.questionCount),
                                   setup: {
                                       questionCount: expandingSection.questionCount,
                                       choicesCount: presetModel.choicesCount,
                                       sameRegion: presetModel.sameRegion,
                                       timeToAnswer: presetModel.timeToAnswer,
                                       quizType: expandingSection.quizType,
                                       isPreset: presetModel.presetSelected && expandingSection.presetCount
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