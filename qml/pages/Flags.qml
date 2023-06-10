/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import ".."
import "../helpers.js" as Helpers

Page {
    SilicaListView {
        anchors.fill: parent

        model: Data { id: dataModel }

        delegate: BackgroundItem {
            id: item
            height: Theme.itemSizeLarge
            contentHeight: Theme.itemSizeLarge
            width: ListView.view.width

            Row {
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

            onClicked: pageStack.push(Qt.resolvedUrl("Flag.qml"), { index: index, model: dataModel })
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Quiz me!")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Quiz.qml"), {
                        indices: Helpers.pickRandomIndices(dataModel, 15),
                        model: dataModel
                    })
                }
            }
        }

        VerticalScrollDecorator { }
    }
}