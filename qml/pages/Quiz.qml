/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import QtQml.Models 2.2
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page

    property int index
    property var indices
    property alias model: delegateModel.model

    SilicaListView {
        anchors.fill: parent
        header: Column {
            bottomPadding: Theme.paddingMedium
            width: parent.width

            PageHeader { title: "Guess the country" }

            Image {
                source: "../../assets/flags/" + model.get(index).flag
                sourceSize.width: parent.width
            }
        }
        model: DelegateModel {
            signal highlightCorrect

            id: delegateModel
            delegate: Component {
                QuizButton {
                    id: button
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: model.name
                    width: parent.width - 2 * Theme.horizontalPageMargin

                    onClicked: {
                        if (model.index !== page.index) {
                            button.color = "red"
                        }
                        delegateModel.highlightCorrect()
                        closeTimer.running = true
                    }

                    Connections {
                        target: delegateModel
                        onHighlightCorrect: if (model.index === page.index) button.color = "green"
                    }
                }
            }
            filterOnGroup: "included"
            groups: [
                DelegateModelGroup {
                    name: "included"
                }
            ]

            Component.onCompleted: {
                for (var i = 0; i < indices.length; ++i) {
                    items.addGroups(indices[i], 1, "included")
                }
            }
        }
        spacing: Theme.paddingMedium
    }

    Timer {
        id: closeTimer
        interval: 1000
        onTriggered: {
            pageStack.pop()
        }
    }
}