/*
 * Copyright (c) 2023-2025 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

SilicaControl {
    property alias text: label.text
    property alias altText: altLabel.text
    property color color: highlighted ? palette.highlightColor : palette.primaryColor
    property var radius

    signal clicked

    id: button
    highlighted: mouseArea.containsPress

    MouseArea {
        id: mouseArea
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            radius: button.radius === undefined ? height / 2 : button.radius
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
            font.pixelSize: button.height >= Theme.itemSizeMedium ? Theme.fontSizeMedium : Theme.fontSizeSmall
            horizontalAlignment: width > implicitWidth ? Text.AlignHCenter : Text.AlignLeft
            truncationMode: TruncationMode.Fade
            visible: text !== ""
            width: parent.width - parent.height / 2
        }

        onClicked: button.clicked()
    }
}