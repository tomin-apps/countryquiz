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
            PageHeader {
                // TODO: Create some kind of tabbed header to replace this
                id: pageHeader
                title: pageModel.get(paged.currentIndex).title
            }

            PagedView {
                id: paged
                anchors.fill: parent
                contentItem.height: parent.height - pageHeader.height
                contentItem.y: pageHeader.height
                contentItem.width: parent.width
                delegate: Loader {
                    property var _dataModel: dataModel

                    clip: true
                    height: PagedView.contentHeight
                    source: Qt.resolvedUrl(model.url)
                    width: PagedView.contentWidth
                }
                model: pageModel
            }
        }
    }
    cover: Component {
        Cover {
            Label {
                anchors.centerIn: parent
                text: qsTr("Flag Game")
            }
        }
    }

    allowedOrientations: defaultAllowedOrientations

    Data { id: dataModel }

    ListModel {
        id: pageModel

        ListElement {
            title: "Quiz"
            url: "pages/Selection.qml"
        }

        ListElement {
            title: "Flags"
            url: "pages/Flags.qml"
        }
    }
}