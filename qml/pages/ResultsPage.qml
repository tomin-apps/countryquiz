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
            //% "Results"
            title: qsTrId("countryquiz-he-results")
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
                        //% "It's like flipping a coin, sometimes you just have bad luck!"
                        return qsTrId("countryquiz-la-result_zero")
                    }
                    if (count >= 10 && correctAnswersCount === count) {
                        if (setup.quizType === "flags") {
                            //% "Perfect work! You clearly know the flags!"
                            return qsTrId("countryquiz-la-result_maximum_flags")
                        } if (setup.quizType === "maps") {
                            //% "Perfect work! You clearly know maps!"
                            return qsTrId("countryquiz-la-result_maximum_maps")
                        } if (setup.quizType === "capitals") {
                            //% "Perfect work! You clearly know the capitals!"
                            return qsTrId("countryquiz-la-result_maximum_capitals")
                        }
                    }
                    var portion = correctAnswersCount / count
                    if (portion >= 0.9) {
                        //% "Excellent!"
                        return qsTrId("countryquiz-la-result_awesome")
                    } if (portion > 0.7) {
                        //% "Very good!"
                        return qsTrId("countryquiz-la-result_great")
                    } if (portion > 0.5) {
                        //% "You did well!!"
                        return qsTrId("countryquiz-la-result_good")
                    } if (portion >= 0.2) {
                        //% "You could use more practice."
                        return qsTrId("countryquiz-la-result_poor")
                    }
                    //% "Did you try to avoid the right answers?"
                    return qsTrId("countryquiz-la-result_bad")
                }
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
            }

            Label {
                color: palette.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeLarge
                horizontalAlignment: Text.AlignHCenter
                //% "%1 / %2 correct"
                text: qsTrId("countryquiz-la-correct_answers_count").arg(correctAnswersCount).arg(count)
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
            }

            Label {
                color: palette.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeLarge
                horizontalAlignment: Text.AlignHCenter
                //% "in %1"
                text: qsTrId("countryquiz-la-in_time").arg(quizTimer.getTotalTimeText())
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
            }

            Label {
                color: palette.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeLarge
                horizontalAlignment: Text.AlignHCenter
                text: {
                    if (resultsSaver.nth === -1) {
                        //% "Score %L1 points"
                        return qsTrId("countryquiz-la-score_n_points").arg(totalScore)
                    }
                    //% "Score %L1 points (#%2)"
                    return qsTrId("countryquiz-la-score_n_points_with_ranking").arg(totalScore).arg(resultsSaver.nth)
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
                    //% "Your answers"
                    title: qsTrId("countryquiz-se-your_answers")
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                //% "Play again"
                text: qsTrId("countryquiz-bt-play_again")

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
            language: valid ? dataModel.language : ""
        }
        onNthChanged: signaler.resultSaved()
    }

    Component.onCompleted: resultsSaver.save(correctAnswers, times)
}