/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

SilicaControl {
    property alias text: label.text
    property color color: highlighted ? Theme.highlightColor : Theme.primaryColor

    signal clicked

    id: button
    height: Theme.itemSizeMedium
    highlighted: mouseArea.containsPress

    MouseArea {
        id: mouseArea
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Theme.highlightBackgroundFromColor(button.color, Theme.colorScheme)
            opacity: Theme.highlightBackgroundOpacity
        }

        Label {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
        }

        onClicked: button.clicked()
    }
}