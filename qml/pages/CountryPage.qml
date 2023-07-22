/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import CountryQuiz 1.0
import QtQuick 2.6
import Sailfish.Silica 1.0
import ".."

Page {
    property var item

    id: page

    PageHeader { id: header }

    SilicaFlickable {
        contentHeight: content.height
        contentWidth: width
        height: parent.height - header.height
        width: parent.width
        y: header.height

        Column {
            id: content
            width: parent.width

            Image {
                id: flag
                anchors.horizontalCenter: parent.horizontalCenter
                source: "../../assets/flags/" + item.iso + ".svg"
                sourceSize: Qt.size(parent.width, (page.height - header.height - textContent.height - Theme.paddingLarge) / 2)
            }

            Column {
                id: textContent
                width: parent.width

                Item { height: Theme.paddingLarge; width: parent.width }

                Label {
                    id: nameLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                    horizontalAlignment: Text.AlignHCenter
                    text: item.pre ? item.pre + " " + item.name : item.name
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                }

                Item { height: Theme.paddingSmall; width: parent.width }

                Label {
                    id: altNameLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeLarge
                    horizontalAlignment: Text.AlignHCenter
                    text: item.alt || ""
                    visible: text !== ""
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                }

                Item { height: Theme.paddingLarge; width: parent.width }
            }

            Map {
                anchors.horizontalCenter: parent.horizontalCenter
                code: item.iso
                load: parent.width !== 0 && flag.height !== 0 && textContent.height !== 0
                sourceSize: Qt.size(parent.width, page.height - header.height - flag.height - textContent.height - Theme.paddingLarge)
            }
        }

        VerticalScrollDecorator { }
    }
}