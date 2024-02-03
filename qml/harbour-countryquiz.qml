/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import "components"
import "pages"

ApplicationWindow {
    property alias config: config
    property alias dataModel: dataModel
    property alias quizTimer: quizTimer

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
                currentIndex: 1
                delegate: Loader {
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
                text: qsTr("Country Quiz")
            }
        }
    }

    allowedOrientations: defaultAllowedOrientations

    QuizTimer { id: quizTimer }

    Data { id: dataModel }

    Config { id: config }

    ListModel {
        id: pageModel

        ListElement {
            title: qsTr("Countries")
            url: "pages/CountryListTab.qml"
        }

        ListElement {
            title: qsTr("Quiz")
            url: "pages/QuizSelectionTab.qml"
        }
    }
}