/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import CountryQuiz 1.0
import "../helpers.js" as Helpers

Page {
    id: page

    property var correctAnswers
    property var times
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

    readonly property int totalScore: {
        var total = 0
        for (var i = 0; i < times.length; ++i) {
            total += calculateScore(correctAnswers[i] ? 1 : 0, times[i], quizTimer.timeLimit)
        }
        return total
    }

    function calculateScore(result, time, timeLimit) {
        return result * 1000 * (1 - time / timeLimit)
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
                color: palette.highlightColor
                font.pixelSize: Theme.fontSizeLarge
                horizontalAlignment: Text.AlignHCenter
                text: {
                    if (count === 1 && correctAnswersCount === 0) {
                        return qsTr("It's like flipping a coin, sometimes you just have bad luck!")
                    }
                    if (count >= 10 && correctAnswersCount === count) {
                        if (setup.quizType === "flags") {
                            return qsTr("Perfect work! You clearly know the flags!")
                        } if (setup.quizType === "maps") {
                            return qsTr("Perfect work! You clearly know maps!")
                        } if (setup.quizType === "capitals") {
                            return qsTr("Perfect work! You clearly know the capitals!")
                        }
                    }
                    var portion = correctAnswersCount / count
                    if (portion >= 0.9) {
                        return qsTr("Excellent!")
                    } if (portion > 0.7) {
                        return qsTr("Very good!")
                    } if (portion > 0.5) {
                        return qsTr("You did well!!")
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
                color: palette.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeLarge
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("%1 / %2 correct").arg(correctAnswersCount).arg(count)
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
            }

            Label {
                color: palette.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeLarge
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("in %1").arg(quizTimer.getTotalTimeText())
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
            }

            Label {
                color: palette.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeLarge
                horizontalAlignment: Text.AlignHCenter
                text: {
                    if (resultsSaver.nth === -1) {
                        return qsTr("Score %L1 points").arg(totalScore)
                    }
                    return qsTr("Score %L1 points (#%2)").arg(totalScore).arg(resultsSaver.nth)
                }
                width: Math.min(contentWidth, parent.width - 2 * Theme.horizontalPageMargin)
                x: Theme.horizontalPageMargin + Math.max(0, ((parent.width - 2 * Theme.horizontalPageMargin) - contentWidth)) / 2

                Behavior on x {
                    NumberAnimation { }
                }
            }

            ExpandingSectionGroup {
                animateToExpandedSection: false

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
                                    color: highlighted ? palette.highlightColor : (item.correct ? "green" : "red")
                                    font.pixelSize: Theme.fontSizeMedium
                                    horizontalAlignment: Text.AlignHCenter
                                    text: item.name
                                    truncationMode: TruncationMode.Fade
                                    width: parent.width - 2 * Theme.horizontalPageMargin
                                    x: Theme.horizontalPageMargin
                                }

                                onClicked: pageStack.push(Qt.resolvedUrl("CountryPage.qml"), {
                                    item: dataModel.get(current),
                                    score: calculateScore(correct ? 1 : 0, page.times[index], quizTimer.timeLimit),
                                    time: page.times[index],
                                })
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
                        indices: Helpers.pickRandomIndices(dataModel, dataModel.getIndices(page.setup.quizType), page.setup.questionCount),
                        setup: page.setup
                    })
                }
            }
        }

        VerticalScrollDecorator { }
    }

    ResultsSaver {
        property bool valid: setup && setup.isPreset

        id: resultsSaver
        options {
            quizType: valid ? setup.quizType : ""
            numberOfQuestions: valid ? setup.questionCount : 0
            numberOfChoices: valid ? setup.choicesCount : 0
            choicesFrom: valid ? (setup.sameRegion ? "same region" : "everywhere") : ""
            timeToAnswer: valid ? setup.timeToAnswer : 0
            language: valid ? "en" : ""
        }
        onNthChanged: signaler.resultSaved()
    }

    Component.onCompleted: resultsSaver.save(correctAnswers, times)
}