/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

SilicaControl {
    property alias text: label.text
    property alias altText: altLabel.text
    property color color: highlighted ? palette.highlightColor : palette.primaryColor

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
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: altLabel.visible ? -(font.pixelSize + Theme.paddingSmall) / 2 : 0
            }
            horizontalAlignment: width > implicitWidth ? Text.AlignHCenter : Text.AlignLeft
            truncationMode: TruncationMode.Fade
            width: parent.width - parent.height / 2
        }

        Label {
            id: altLabel
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: (font.pixelSize + Theme.paddingSmall) / 2
            }
            color: highlighted ? palette.secondaryHighlightColor : palette.secondaryColor
            horizontalAlignment: width > implicitWidth ? Text.AlignHCenter : Text.AlignLeft
            truncationMode: TruncationMode.Fade
            visible: text !== ""
            width: parent.width - parent.height / 2
        }

        onClicked: button.clicked()
    }
}