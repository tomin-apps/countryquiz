/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../helpers.js" as Helpers

Item {
    id: page

    SilicaListView {
        id: view
        anchors.fill: parent
        delegate: BackgroundItem {
            id: item
            height: Theme.itemSizeLarge
            contentHeight: Theme.itemSizeLarge
            width: ListView.view.width

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.paddingMedium

                Image {
                    source: "../../assets/flags/" + iso + ".svg"
                    sourceSize.height: Theme.itemSizeMedium
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Theme.fontSizeLarge
                    text: pre ? pre + " " + name : name
                    truncationMode: TruncationMode.Fade
                    width: item.width - x - Theme.horizontalPageMargin
                }
            }

            onClicked: pageStack.push(Qt.resolvedUrl("Flag.qml"), { item: view.model.get(index) })
        }
        model: config.hasPlayed ? dataModel : 0

        ViewPlaceholder {
            enabled: !config.hasPlayed
            text: qsTr("Play quiz at least once to see all the flags")
            hintText: qsTr("Swipe to right and press 'Quiz me!'")
        }

        VerticalScrollDecorator { }
    }
}
