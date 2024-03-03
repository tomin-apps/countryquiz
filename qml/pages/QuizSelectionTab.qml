/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"
import "../helpers.js" as Helpers

Item {
    id: page

    property var presetModel

    function isInitialSection(section) {
        return config.lastChosenQuizType === section
    }

    onPresetModelChanged: if (presetModel !== undefined) config.setLastChosenQuizType(presetModel.type)

    SilicaFlickable {
        anchors.fill: parent

        ExpandingSectionGroup {
            animateToExpandedSection: false
            width: parent.width

            QuizSection {
                expanded: isInitialSection(quizType)
                quizType: "flags"
                title: qsTr("Flag Quiz")

                presets: ListModel {
                    ListElement {
                        name: "easy"
                        count: 15
                        choices: 3
                        region: false
                        time: 30
                    }

                    ListElement {
                        name: "regular"
                        count: 15
                        choices: 4
                        region: false
                        time: 15
                    }

                    ListElement {
                        name: "veteran"
                        count: 15
                        choices: 5
                        region: true
                        time: 15
                    }
                }
            }

            QuizSection {
                expanded: isInitialSection(quizType)
                quizType: "maps"
                title: qsTr("Map Quiz")

                presets: ListModel {
                    ListElement {
                        name: "easy"
                        count: 15
                        choices: 3
                        region: false
                        time: 30
                    }

                    ListElement {
                        name: "regular"
                        count: 15
                        choices: 4
                        region: true
                        time: 30
                    }

                    ListElement {
                        name: "veteran"
                        count: 15
                        choices: 5
                        region: true
                        time: 15
                    }
                }
            }

            QuizSection {
                expanded: isInitialSection(quizType)
                quizType: "capitals"
                title: qsTr("Capital City Quiz")

                presets: ListModel {
                    ListElement {
                        name: "easy"
                        count: 15
                        choices: 3
                        region: false
                        time: 30
                    }

                    ListElement {
                        name: "regular"
                        count: 15
                        choices: 4
                        region: false
                        time: 15
                    }

                    ListElement {
                        name: "veteran"
                        count: 15
                        choices: 5
                        region: true
                        time: 15
                    }
                }
            }
        }

        VerticalScrollDecorator { }
    }

    Binding {
        target: quizTimer
        property: "timeLimit"
        value: presetModel !== undefined ? presetModel.timeToAnswer * 1000 : -1
        when: presetModel !== undefined
    }
}