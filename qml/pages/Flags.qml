/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../helpers.js" as Helpers

Item {
    property var dataModel: _dataModel

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
                    source: "../../assets/flags/" + flag
                    sourceSize.height: Theme.itemSizeMedium
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Theme.fontSizeLarge
                    text: name
                    truncationMode: TruncationMode.Fade
                    width: item.width - x - Theme.horizontalPageMargin
                }
            }

            onClicked: pageStack.push(Qt.resolvedUrl("Flag.qml"), { index: index, model: model })
        }
        model: page.dataModel

        VerticalScrollDecorator { }
    }
}