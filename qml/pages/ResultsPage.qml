/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../helpers.js" as Helpers

Page {
    id: page

    property var correctAnswers
    property var indices
    property var setup

    readonly property int count: indices.length
    readonly property int correctAnswersCount: {
        var count = 0
        for (var i = 0; i < correctAnswers.length; ++i) {
            if (correctAnswers[i]) {
                ++count
            }
        }
        return count
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: header.height + column.height
        contentWidth: width

        PageHeader {
            id: header
            title: qsTr("Results")
        }

        Column {
            id: column
            anchors.top: header.bottom
            bottomPadding: Theme.paddingLarge
            spacing: Theme.paddingLarge
            width: parent.width

            Label {
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeLarge
                horizontalAlignment: Text.AlignHCenter
                text: {
                    if (count === 1 && correctAnswersCount === 0) {
                        return qsTr("It's like flipping a coin, sometimes you just have bad luck!")
                    }
                    if (count >= 10 && correctAnswersCount === count) {
                        return qsTr("Perfect work! You clearly know your flags!")
                    }
                    var portion = correctAnswersCount / count
                    if (portion >= 0.9) {
                        return qsTr("Excellent!")
                    } if (portion > 0.5) {
                        return qsTr("Very good!")
                    } if (portion >= 0.2) {
                        return qsTr("You could use more practice.")
                    }
                    return qsTr("Did you try to avoid the right answers?")
                }
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
            }

            Label {
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeLarge
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("%1 / %2 correct").arg(correctAnswersCount).arg(count)
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
            }

            Label {
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeLarge
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("in %1").arg(quizTimer.getTotalTimeText())
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
            }

            ExpandingSectionGroup {
                ExpandingSection {
                    content.sourceComponent: Component {
                        ColumnView {
                            delegate: BackgroundItem {
                                property bool correct: modelData
                                property int current: indices[index]
                                property string name: dataModel.get(current).name

                                id: item
                                height: Theme.itemSizeSmall
                                width: parent.width

                                Label {
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: highlighted ? Theme.highlightColor : (item.correct ? "green" : "red")
                                    font.pixelSize: Theme.fontSizeMedium
                                    horizontalAlignment: Text.AlignHCenter
                                    text: item.name
                                    truncationMode: TruncationMode.Fade
                                    width: parent.width - 2 * Theme.horizontalPageMargin
                                    x: Theme.horizontalPageMargin
                                }

                                onClicked: pageStack.push(Qt.resolvedUrl("CountryPage.qml"), { item: dataModel.get(current) })
                            }
                            itemHeight: Theme.itemSizeSmall
                            model: correctAnswers
                        }
                    }
                    title: qsTr("Your answers")
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Play again")

                onClicked: {
                    quizTimer.reset()
                    pageStack.replace(Qt.resolvedUrl("QuizPage.qml"), {
                        indices: Helpers.pickRandomIndices(dataModel, page.setup.questionCount),
                        setup: page.setup
                    })
                }
            }
        }

        VerticalScrollDecorator { }
    }
}