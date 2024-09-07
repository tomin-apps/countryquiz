/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import CountryQuiz 1.0
import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

Page {
    property alias title: header.title
    property alias subtitle: header.description
    property alias onlyOwnResults: statsModel.onlyOwnResults
    property alias maxCount: statsModel.maxCount
    property alias inMemoryDB: statsModel.inMemoryDB
    property string quizType
    property int numberOfQuestions
    property int numberOfChoices
    property string choicesFrom
    property int timeToAnswer
    property string language

    id: page
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content
            bottomPadding: Theme.paddingLarge
            width: parent.width

            PageHeader {
                id: header
            }

            StatsList {
                horizontalMargin: page.isLandscape ? Theme.horizontalPageMargin : Theme.paddingMedium
                model: statsModel
                primaryTextColor: palette.highlightColor
                secondaryTextColor: palette.secondaryHighlightColor
                width: parent.width
            }
        }
    }

    StatsModel {
        id: statsModel
        // @disable-check M17
        options.quizType: page.quizType
        // @disable-check M17
        options.numberOfQuestions: page.numberOfQuestions
        // @disable-check M17
        options.numberOfChoices: page.numberOfChoices
        // @disable-check M17
        options.choicesFrom: page.choicesFrom
        // @disable-check M17
        options.timeToAnswer: page.timeToAnswer
        // @disable-check M17
        options.language: page.language
    }
}