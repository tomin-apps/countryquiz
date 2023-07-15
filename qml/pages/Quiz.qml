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

    property int current: 1
    property var indices
    property var setup
    property var correctAnswers: new Array

    readonly property int count: indices.length
    readonly property int index: indices[current - 1]
    readonly property bool finished: closeTimer.running

    function closeInSecond(index) {
        if (!finished) {
            closeTimer.wasCorrect = index === page.index
            closeTimer.running = true
        }
    }

    SilicaListView {
        anchors.fill: parent
        header: Column {
            readonly property int choicesHeight: (Theme.itemSizeMedium + Theme.paddingMedium) * setup.choicesCount
            readonly property int otherHeight: header.height + label.height + timeLeft.height + 2 * Theme.paddingSmall

            bottomPadding: Theme.paddingMedium
            width: parent.width

            PageHeader {
                id: header
                title: qsTr("Quiz (%1 / %2)").arg(page.current).arg(page.count)
            }

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source: "../../assets/flags/" + dataModel.get(index).iso + ".svg"
                sourceSize.height: page.height - otherHeight - choicesHeight
                sourceSize.width: parent.width
            }

            Item { height: Theme.paddingSmall; width: parent.width }

            Label {
                id: label
                color: Theme.highlightColor
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Guess which country this flag belongs to")
                width: parent.width
            }

            Item { height: Theme.paddingSmall; width: parent.width }

            Label {
                id: timeLeft
                color: Theme.highlightColor
                horizontalAlignment: Text.AlignHCenter
                text: quizTimer.timeAsString(quizTimer.timeLimit)
                width: parent.width

                Connections {
                    target: quizTimer.limit
                    onTriggered: timeLeft.color = "red"
                }

                Connections {
                    target: quizTimer.tick
                    onTriggered: timeLeft.text = quizTimer.getTimeLeftText()
                }
            }
        }
        model: DelegateModel {
            signal highlightCorrect
            signal highlightAllWrong

            id: delegateModel
            delegate: Component {
                QuizButton {
                    id: button
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: model.pre ? model.pre + " " + model.name : model.name
                    altText: model.alt || ""
                    width: parent.width - 2 * Theme.horizontalPageMargin

                    onClicked: {
                        if (!page.finished) {
                            quizTimer.stop()
                            if (model.index !== page.index) {
                                button.color = "red"
                            }
                            delegateModel.highlightCorrect()
                            page.closeInSecond(model.index)
                        }
                    }

                    Connections {
                        target: delegateModel
                        onHighlightCorrect: if (model.index === page.index) button.color = "green"
                        onHighlightAllWrong: button.color = (model.index === page.index) ? "green" : "red"
                    }
                }
            }
            filterOnGroup: "included"
            model: dataModel
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
                    correctAnswers: correctAnswers,
                    setup: page.setup
                })
                config.hasPlayed = true
            } else {
                pageStack.replace(Qt.resolvedUrl("Quiz.qml"), {
                    indices: page.indices,
                    current: page.current + 1,
                    correctAnswers: correctAnswers,
                    setup: page.setup
                })
            }
        }
    }

    Connections {
        target: quizTimer.limit
        onTriggered: {
            delegateModel.highlightAllWrong()
            closeInSecond(-1)
        }
    }

    Component.onCompleted: {
        var choices = Helpers.getIndexArray(dataModel)
        choices.swap(0, index)
        for (var i = 1; i < setup.choicesCount; ++i) {
            choices.swap(i, i + Math.floor(Math.random() * (dataModel.count - i)))
        }
        for (i = 0; i < setup.choicesCount; ++i) {
            delegateModel.items.addGroups(choices[i], 1, "included")
        }
        for (i = 0; i < includedGroup.count - 1; ++i) {
            includedGroup.move(i, i + Math.floor(Math.random() * (includedGroup.count - i)), 1)
        }
        quizTimer.start()
    }
}
