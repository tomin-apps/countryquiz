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
                //% "Flag Quiz"
                title: qsTrId("countryquiz-se-flag_quiz")
            }

            QuizSection {
                expanded: isInitialSection(quizType)
                presets: MapQuizPresets { }
                quizType: "maps"
                //% "Map Quiz"
                title: qsTrId("countryquiz-se-map_quiz")
            }

            QuizSection {
                expanded: isInitialSection(quizType)
                presets: CapitalQuizPresets { }
                quizType: "capitals"
                //% "Capital City Quiz"
                title: qsTrId("countryquiz-se-capital_quiz")
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