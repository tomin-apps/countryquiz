/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import CountryQuiz 1.0
import QtQuick 2.6
import Sailfish.Silica 1.0
import ".."

Page {
    property var item
    property string countryName: item !== undefined && item !== null ? (item.pre ? item.pre + " " + item.name : item.name) : ""

    id: page

    PageHeader {
        id: header
        title: countryName
        leftMargin: Theme.horizontalPageMargin + Theme.paddingLarge
    }

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
                sourceSize: Qt.size(parent.width, Math.min(page.height / 4, (page.height - header.height - textContent.height) / 2))
            }

            Column {
                id: textContent
                width: parent.width

                Item { height: Theme.paddingLarge; width: parent.width }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: palette.primaryColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                    horizontalAlignment: Text.AlignHCenter
                    text: item.alt || countryName
                    visible: text !== ""
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Qt.openUrlExternally("https://en.wikipedia.org/wiki/" + item.name.replace(/ /g, "_"))
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: palette.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeMedium
                    horizontalAlignment: Text.AlignHCenter
                    text: {
                        var capitals = item.capital.split(';')
                        switch (capitals.length) {
                        case 1:
                            return qsTr("Capital: %1").arg(capitals[0])
                        case 2:
                            return qsTr("Capitals: %1 and %2").arg(capitals[0]).arg(capitals[1])
                        case 3:
                            return qsTr("Capitals: %1, %2 and %3").arg(capitals[0]).arg(capitals[1]).arg(capitals[2])
                        }
                        console.warn("UNIMPLEMENTD: Bad number of capitals", capitals.length)
                        return ""
                    }
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: palette.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeMedium
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Region: %1").arg(item.region)
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                }

                Item { height: Theme.paddingLarge; width: parent.width }
            }

            Item {
                height: page.height - header.height - flag.height - textContent.height - map.height
                width: parent.width
            }

            Map {
                id: map
                anchors.horizontalCenter: parent.horizontalCenter
                code: item.iso
                model: parent.width !== 0 && flag.height !== 0 && textContent.height !== 0 ? mapModel : null
                sourceSize: Qt.size(parent.width, Math.min(parent.width, page.height - header.height - flag.height - textContent.height))
            }
        }

        VerticalScrollDecorator { }
    }

    // Break some weird signal issue that crashes the app when leaving the page
    Component.onCompleted: page.countryName = countryName
}
