/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import ".."

Page {
    property var item

    PageHeader { id: header }

    Column {
        anchors.top: header.bottom
        spacing: Theme.paddingLarge
        width: parent.width

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "../../assets/flags/" + item.iso + ".svg"
            sourceSize.width: parent.width
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeExtraLarge
            horizontalAlignment: Text.AlignHCenter
            text: item.pre ? item.pre + " " + item.name : item.name
            width: parent.width - 2 * Theme.horizontalPageMargin
            wrapMode: Text.Wrap
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.secondaryHighlightColor
            font.pixelSize: Theme.fontSizeLarge
            horizontalAlignment: Text.AlignHCenter
            text: item.alt || ""
            visible: text !== ""
            width: parent.width - 2 * Theme.horizontalPageMargin
            wrapMode: Text.Wrap
        }
    }
}
