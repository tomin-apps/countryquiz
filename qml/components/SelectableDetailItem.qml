/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

ListItem {
    property alias label: detailLabel.text
    property alias value: valueLabel.text

    contentHeight: labels.height
    openMenuOnPressAndHold: false
    width: parent.width

    Row {
        id: labels
        height: Theme.itemSizeExtraSmall
        spacing: Theme.paddingMedium
        width: parent.width - 2 * Theme.horizontalPageMargin
        x: Theme.horizontalPageMargin

        Label {
            id: detailLabel
            anchors.verticalCenter: parent.verticalCenter
            color: palette.highlightColor
            horizontalAlignment: Text.AlignRight
            width: (parent.width - parent.spacing) / 2
            wrapMode: Text.Wrap
        }

        Label {
            id: valueLabel
            anchors.verticalCenter: parent.verticalCenter
            color: highlighted ? palette.highlightColor : palette.primaryColor
            horizontalAlignment: Text.AlignLeft
            width: (parent.width - parent.spacing) / 2
            wrapMode: Text.Wrap
        }
    }

    onClicked: openMenu()
}