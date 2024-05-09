/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import CountryQuiz 1.0
import QtQuick 2.6
import Sailfish.Silica 1.0
import ".."
import "../helpers.js" as Helpers

Page {
    property var item
    property string countryName: item !== undefined && item !== null ? (item.pre ? item.pre + " " + item.name : item.name) : ""
    property string time
    property int score: -1

    id: page

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height
        contentWidth: width

        Column {
            id: content
            width: parent.width

            PageHeader {
                id: header
                title: countryName
                leftMargin: Theme.horizontalPageMargin + Theme.paddingLarge
            }

            Image {
                id: flag
                anchors.horizontalCenter: parent.horizontalCenter
                source: "../../assets/flags/" + item.iso + ".svg"
                sourceSize: Qt.size(parent.width, page.height / 4)
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
                            //% "Capital: %1"
                            return qsTrId("countryquiz-la-signle_capital").arg(capitals[0])
                        case 2:
                            //% "Capitals: %1 and %2"
                            return qsTrId("countryquiz-la-two_capitals").arg(capitals[0]).arg(capitals[1])
                        case 3:
                            //% "Capitals: %1, %2 and %3"
                            return qsTrId("countryquiz-la-three_capitals").arg(capitals[0]).arg(capitals[1]).arg(capitals[2])
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
                    //% "Region: %1"
                    text: qsTrId("countryquiz-la-region").arg(item.region)
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: palette.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeMedium
                    horizontalAlignment: Text.AlignHCenter
                    //% "Time: %1"
                    text: qsTrId("countryquiz-la-time").arg(Helpers.timeAsString(page.time))
                    visible: page.time != ""
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: palette.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeMedium
                    horizontalAlignment: Text.AlignHCenter
                    //% "Score: %L1 points"
                    text: qsTrId("countryquiz-la-score").arg(page.score)
                    visible: page.score >= 0
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                }

                Item { height: Theme.paddingLarge; width: parent.width }
            }

            Item {
                readonly property int fill: page.height - header.height - flag.height - textContent.height - map.height
                height: Math.max(fill, 0)
                width: parent.width
            }

            Map {
                id: map
                anchors.horizontalCenter: parent.horizontalCenter
                code: item.iso
                invertedColors: palette.colorScheme === Theme.DarkOnLight
                model: parent.width !== 0 ? mapModel : null
                overlayColor: Theme.rgba(Theme.highlightColor, Theme.opacityLow)
                sourceSize: Qt.size(parent.width, parent.width)
            }
        }

        VerticalScrollDecorator { }
    }
}
