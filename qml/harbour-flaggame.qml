/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import "components"
import "pages"

ApplicationWindow {
    initialPage: Component {
        Page {
            Tabs {
                id: tabs
                currentIndex: paged.currentIndex
                model: pageModel
                width: parent.width
                z: 1

                onChangeTab: paged.currentIndex = index
            }

            PagedView {
                id: paged
                anchors.fill: parent
                contentItem.height: parent.height - tabs.height
                contentItem.y: tabs.height
                contentItem.width: parent.width
                delegate: Loader {
                    property var _dataModel: dataModel
                    property var _config: config

                    clip: true
                    height: PagedView.contentHeight
                    source: Qt.resolvedUrl(model.url)
                    width: PagedView.contentWidth
                }
                model: pageModel

                onCurrentIndexChanged: tabs.currentIndex = currentIndex
            }
        }
    }
    cover: Component {
        CoverBackground {
            Label {
                anchors.centerIn: parent
                text: qsTr("Flag Game")
            }
        }
    }

    allowedOrientations: defaultAllowedOrientations

    Data { id: dataModel }

    Config { id: config }

    ListModel {
        id: pageModel

        ListElement {
            title: qsTr("Quiz")
            url: "pages/Selection.qml"
        }

        ListElement {
            title: qsTr("Flags")
            url: "pages/Flags.qml"
        }
    }
}