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
            }

            QuizSection {
                title: qsTr("Map Quiz")
                quizType: "maps"
            }

            QuizSection {
                title: qsTr("Capital Quiz")
                quizType: "capitals"
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