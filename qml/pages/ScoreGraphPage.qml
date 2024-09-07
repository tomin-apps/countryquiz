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
    property StatsModel scoreModel
    property alias title: header.title
    property alias subtitle: header.description
    readonly property bool activateEarly: scoreModel && scoreModel.count < 300

    id: page
    allowedOrientations: Orientation.All

    PageHeader {
        id: header
        anchors.top: parent.top
    }

    Loader {
        id: scoreGraphLoader
        anchors {
            top: header.bottom
            bottom: parent.bottom
            bottomMargin: Theme.paddingLarge
        }
        asynchronous: true
        active: activateEarly
        sourceComponent: scoreGraphComponent
        width: parent.width - 2 * Theme.horizontalPageMargin
        x: Theme.horizontalPageMargin
    }

    Component {
        id: scoreGraphComponent

        ScoreGraph {
            arrowTipSize: Screen.width * 0.025
            fillColor: Theme.rgba(palette.highlightColor, Theme.opacityFaint)
            fontColor: palette.highlightColor
            font.pixelSize: Theme.fontSizeTiny
            height: Theme.itemSizeSmall * 4
            lineColor: palette.highlightColor
            lineWidth: 2
            model: scoreModel
            secondaryLineColor: Theme.rgba(palette.highlightColor, Theme.opacityHigh)
            visible: scoreModel
        }
    }

    // TODO: Add busy indicator once score graph doesn't block UI thread
    onStatusChanged: if (page.status === PageStatus.Active) scoreGraphLoader.active = true
    Component.onCompleted: if (page.status === PageStatus.Active) scoreGraphLoader.active = true
}