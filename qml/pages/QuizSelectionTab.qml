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

    SilicaFlickable {
        anchors.fill: parent

        ExpandingSectionGroup {
            currentIndex: 0
            width: parent.width

            QuizSection {
                title: qsTr("Flag Quiz")
                quizType: "flags"

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
                title: qsTr("Map Quiz")
                quizType: "maps"

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
                title: qsTr("Capital City Quiz")
                quizType: "capitals"

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
        value: page.presetModel !== undefined ? page.presetModel.timeToAnswer * 1000 : -1
    }
}