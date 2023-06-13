/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"
import "../helpers.js" as Helpers

Item {
    property var config: _config
    property var dataModel: _dataModel

    id: page

    SilicaFlickable {
        anchors.fill: parent

        Column {
            width: parent.width

            SelectableDetailItem {
                label: qsTr("Preset")
                menu: ContextMenu {
                    Repeater {
                        model: presetModel
                        MenuItem { text: model.title }
                    }

                    onActivated: presetModel.selectPreset(index)
                }
                value: presetModel.presetTitle
            }

            SelectableDetailItem {
                label: qsTr("Questions")
                menu: ContextMenu {
                    MenuItem { text: "15" }
                    MenuItem { text: "80" }
                    MenuItem { text: "%1".arg(dataModel.count) }
                    MenuItem { text: qsTr("Custom value") }

                    onActivated: {
                        switch (index) {
                        case 0:
                            presetModel.selectedCount = 15
                            break
                        case 1:
                            presetModel.selectedCount = 80
                            break
                        case 2:
                            presetModel.selectedCount = -1
                            break
                        case 3:
                            var dialog = pageStack.push(Qt.resolvedUrl("IntSelection.qml"), {
                                value: presetModel.questionCount,
                                minimum: 1,
                                maximum: dataModel.count,
                                title: qsTr("Select number of questions"),
                                description: qsTr("Questions"),
                                tooLowHint: qsTr("You must have at least one question"),
                                tooHighHint: qsTr("You may not have more than %1 questions").arg(dataModel.count)
                            })
                            dialog.onAccepted.connect(function() {
                                if (dialog.selectedValue === dataModel.count) {
                                    presetModel.selectedCount = -1
                                } else {
                                    presetModel.selectedCount = dialog.selectedValue
                                }
                            })
                            break
                        }
                    }
                }
                value: presetModel.questionCount
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
                            var dialog = pageStack.push(Qt.resolvedUrl("IntSelection.qml"), {
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
                    pageStack.push(Qt.resolvedUrl("Quiz.qml"), {
                                       config: page.config,
                                       indices: Helpers.pickRandomIndices(page.dataModel, presetModel.questionCount),
                                       model: page.dataModel,
                                       setup: {
                                           questionCount: presetModel.questionCount,
                                           choicesCount: presetModel.choicesCount,
                                           timeToAnswer: presetModel.timeToAnswer
                                       }
                                   })
                }
            }
        }

        VerticalScrollDecorator { }
    }

    ListModel {
        property int selectedCount: _currentItem !== null ? _currentItem.count : 0
        property int selectedChoices: _currentItem !== null ? _currentItem.choices : 0
        property int selectedTime: _currentItem !== null ? _currentItem.time: 0

        readonly property int currentIndex: _currentIndex
        readonly property bool presetSelected: _currentIndex >= 0 && _currentItem !== null
        readonly property string presetTitle: presetSelected ? _currentItem.title : qsTr("None")
        readonly property int questionCount: _questionCount < 0 ? dataModel.count : _questionCount
        readonly property int choicesCount: presetSelected ? _currentItem.choices : selectedChoices
        readonly property int timeToAnswer: presetSelected ? _currentItem.time : selectedTime

        property int _currentIndex
        readonly property var _currentItem: currentIndex >= 0 && currentIndex < count ? get(currentIndex) : null
        readonly property int _questionCount: presetSelected ? _currentItem.count : selectedCount

        function checkPropInPreset(index, prop) {
            var preset = get(index)
            if (prop === "count") {
                return preset.count === selectedCount
            } if (prop === "choices") {
                return preset.choices === selectedChoices
            } if (prop === "time") {
                return preset.time === selectedTime
            }
            return false
        }

        function checkProp(changedProp) {
            for (var i = 0; i < count; ++i) {
                if (checkPropInPreset(i, changedProp)) {
                    var preset = get(i)
                    if (selectedCount === preset.count
                            && selectedChoices === preset.choices
                            && selectedTime === preset.time) {
                        selectPreset(i)
                        return
                    }
                }
            }
            invalidatePreset()
        }

        function selectPreset(index) {
            var preset = get(index)
            selectedCount = preset.count
            selectedChoices = preset.choices
            selectedTime = preset.time
            _currentIndex = index
        }

        function invalidatePreset() {
            _currentIndex = -1
        }

        id: presetModel

        ListElement {
            title: "Normal"
            count: 15
            choices: 4
            time: 15
        }

        ListElement {
            title: "Long"
            count: 80
            choices: 4
            time: 15
        }

        ListElement {
            title: "All"
            count: -1
            choices: 4
            time: 15
        }

        onSelectedCountChanged: checkProp("count")
        onSelectedChoicesChanged: checkProp("choices")
        onSelectedTimeChanged: checkProp("time")
    }
}