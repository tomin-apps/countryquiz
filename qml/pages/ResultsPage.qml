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
    property var selectedAnswers
    property var times
    property var indices
    property var setup
    property string nextCoverState

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
        return result * (800 * (1 - time / timeLimit) + 200)
    }

    function playAgain() {
        nextCoverState = setup.quizType
        quizTimer.reset()
        pageStack.replace(Qt.resolvedUrl("QuizPage.qml"), {
            indices: Helpers.pickRandomIndices(dataModel, dataModel.getIndices(setup.quizType), setup.questionCount),
            setup: setup
        })
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

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                color: palette.primaryColor
                source: {
                    switch (resultsSaver.count < 5 ? -1 : resultsSaver.nth) {
                    case 1:
                        return "../../assets/icons/big-trophy.svg"
                    case 2:
                        return "../../assets/icons/trophy.svg"
                    case 3:
                        return "../../assets/icons/medal.svg"
                    default:
                        return "../../assets/icons/%1.svg".arg(setup.quizType)
                    }
                }
                sourceSize: Qt.size(parent.width / 2, parent.width / 2)
            }

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
                //% "Time: %1"
                text: qsTrId("countryquiz-la-time").arg(quizTimer.getTotalTimeText())
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
            }

            Label {
                color: palette.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeLarge
                horizontalAlignment: Text.AlignHCenter
                text: {
                    if (resultsSaver.nth === -1) {
                        //% "Score: %L1 points"
                        return qsTrId("countryquiz-la-score_n_points").arg(totalScore)
                    }
                    //% "Score: %L1 points (#%2)"
                    return qsTrId("countryquiz-la-score_n_points_with_ranking").arg(totalScore).arg(resultsSaver.nth)
                }
                width: Math.min(contentWidth, parent.width - 2 * Theme.horizontalPageMargin)
                x: Theme.horizontalPageMargin + Math.max(0, ((parent.width - 2 * Theme.horizontalPageMargin) - contentWidth)) / 2

                Behavior on x {
                    NumberAnimation { }
                }
            }

            Loader {
                active: resultsSaver.valid && (config.mode === "party" || config.mode === "shared")
                sourceComponent: nameInput
                width: parent.width
            }

            ExpandingSectionGroup {
                animateToExpandedSection: false

                ExpandingSection {
                    id: expandingSection
                    content.sourceComponent: Component {
                        ColumnView {
                            delegate: BackgroundItem {
                                readonly property bool correct: modelData
                                readonly property int current: indices[index]
                                readonly property string name: dataModel.get(current).name
                                readonly property int selected: selectedAnswers[index]
                                readonly property string selectedName: dataModel.get(selectedAnswers[index]).name

                                id: item
                                enabled: expandingSection.expanded
                                height: Theme.itemSizeSmall
                                width: parent.width

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width

                                    Label {
                                        color: highlighted ? palette.highlightColor : (item.correct ? "green" : "red")
                                        font.pixelSize: Theme.fontSizeMedium
                                        horizontalAlignment: Text.AlignHCenter
                                        text: item.name
                                        truncationMode: TruncationMode.Fade
                                        width: parent.width - 2 * Theme.horizontalPageMargin
                                        x: Theme.horizontalPageMargin
                                    }

                                    Label {
                                        color: palette.secondaryColor
                                        font.pixelSize: Theme.fontSizeExtraSmall
                                        horizontalAlignment: Text.AlignHCenter
                                        //% "Your answer: %1"
                                        text: qsTrId("countryquiz-la-your_answer").arg(item.selectedName)
                                        truncationMode: TruncationMode.Fade
                                        visible: item.current !== item.selected
                                        width: parent.width - 2 * Theme.horizontalPageMargin
                                        x: Theme.horizontalPageMargin
                                    }
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
                id: playAgainButton
                anchors.horizontalCenter: parent.horizontalCenter
                //% "Play again"
                text: qsTrId("countryquiz-bt-play_again")
                enabled: !resultsSaver.valid || config.mode === "solo" || config.mode === "anonymous"

                onClicked: playAgain()
            }
        }

        VerticalScrollDecorator { }
    }

    Component {
        id: nameInput

        Column {
            width: parent.width

            TextField {
                id: nameInputField
                acceptableInput: text.length > 0
                enabled: resultsSaver.nth === -1
                //% "Enter your name to save results"
                label: qsTrId("countryquiz-la-enter_name")
                rightItem: IconButton {
                    height: icon.height
                    icon.source: "image://theme/icon-m-input-clear"
                    opacity: nameInputField.text.length > 0 ? 1.0 : 0.0
                    width: icon.width

                    onClicked: nameInputField.text = ""

                    Behavior on opacity { FadeAnimation {} }
                }
                // TODO: Custom suggestions?

                EnterKey.enabled: acceptableInput
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: resultsSaver.save(correctAnswers, times, nameInputField.text)

                Component.onCompleted: nameInputField.forceActiveFocus()
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: nameInputField.acceptableInput && resultsSaver.nth === -1
                //% "Save result"
                text: qsTrId("countryquiz-bt-save_result")
                onClicked: if (enabled) resultsSaver.save(correctAnswers, times, nameInputField.text)
            }
        }
    }

    ResultsSaver {
        property bool valid: setup && setup.isPreset && config.mode !== "anonymous"

        id: resultsSaver
        options {
            quizType: valid ? setup.quizType : ""
            numberOfQuestions: valid ? setup.questionCount : 0
            numberOfChoices: valid ? setup.choicesCount : 0
            choicesFrom: valid ? (setup.sameRegion ? "same region" : "everywhere") : ""
            timeToAnswer: valid ? setup.timeToAnswer : 0
            language: valid ? dataModel.language : ""
        }
        gameMode: config.mode
        onNthChanged: signaler.resultSaved()
    }

    Connections {
        target: signaler
        onResultSaved: {
            appWindow.progress = -1
            playAgainButton.enabled = true
        }
        onPlayAgain: {
            appWindow.activate()
            page.playAgain()
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Deactivating) {
            appWindow.progress = 1
            appWindow.total = setup.questionCount
            appWindow.quizType = nextCoverState
        }
    }

    Component.onCompleted: {
        if (playAgainButton.enabled) appWindow.progress = -1
        if (config.mode === "solo") resultsSaver.save(correctAnswers, times, "")
    }
}