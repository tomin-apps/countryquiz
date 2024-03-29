/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"
import "../helpers.js" as Helpers
import "../presets"

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
                presets: FlagQuizPresets { }
                quizType: "flags"
                title: qsTr("Flag Quiz")
            }

            QuizSection {
                expanded: isInitialSection(quizType)
                presets: MapQuizPresets { }
                quizType: "maps"
                title: qsTr("Map Quiz")
            }

            QuizSection {
                expanded: isInitialSection(quizType)
                presets: CapitalQuizPresets { }
                quizType: "capitals"
                title: qsTr("Capital City Quiz")
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