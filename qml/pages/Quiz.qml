/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import QtQml.Models 2.2
import Sailfish.Silica 1.0
import "../components"
import "../helpers.js" as Helpers

Page {
    id: page

    property var config
    property int current: 1
    property var indices
    property alias model: delegateModel.model
    property var correctAnswers: new Array

    readonly property int count: indices.length
    readonly property int index: indices[current - 1]

    function closeInSecond(correctAnswerGiven) {
        closeTimer.wasCorrect = correctAnswerGiven
        closeTimer.running = true
    }

    SilicaListView {
        anchors.fill: parent
        header: Column {
            bottomPadding: Theme.paddingMedium
            width: parent.width

            PageHeader { title: qsTr("Quiz (%1 / %2)").arg(page.current).arg(page.count) }

            Image {
                source: "../../assets/flags/" + model.get(index).flag
                sourceSize.width: parent.width
                // TODO: Adjust height if other content can't fit the page without scrolling
            }

            Item { height: Theme.paddingMedium; width: parent.width }

            Label {
                color: Theme.highlightColor
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Guess which country this flag belongs to")
                width: parent.width
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
                        page.closeInSecond(model.index === page.index)
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
                    id: includedGroup
                    name: "included"
                }
            ]
        }
        spacing: Theme.paddingMedium
    }

    Timer {
        property bool wasCorrect

        id: closeTimer
        interval: 1000
        onTriggered: {
            var correctAnswers = page.correctAnswers
            correctAnswers.push(wasCorrect)
            if (current >= count) {
                pageStack.replace(Qt.resolvedUrl("Results.qml"), {
                    indices: page.indices,
                    model: page.model,
                    correctAnswers: correctAnswers
                })
            } else {
                pageStack.replace(Qt.resolvedUrl("Quiz.qml"), {
                    config: page.config,
                    indices: page.indices,
                    model: page.model,
                    current: page.current + 1,
                    correctAnswers: correctAnswers
                })
                page.config.hasPlayed = true
            }
        }
    }

    Component.onCompleted: {
        var count = 4
        var choices = Helpers.getIndexArray(model)
        choices.swap(0, index)
        for (var i = 1; i < count; ++i) {
            choices.swap(i, i + Math.floor(Math.random() * (model.count - i)))
        }
        for (i = 0; i < count; ++i) {
            delegateModel.items.addGroups(choices[i], 1, "included")
        }
        for (i = 0; i < includedGroup.count - 1; ++i) {
            includedGroup.move(i, i + Math.floor(Math.random() * (includedGroup.count - i)), 1)
        }
    }
}