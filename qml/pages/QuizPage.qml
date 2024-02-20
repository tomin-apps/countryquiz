/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import CountryQuiz 1.0
import Nemo.KeepAlive 1.2
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

    onStatusChanged: if (status === PageStatus.Active) choices.opacity = 1.0

    Column {
        readonly property int otherHeight: header.height + label.height + timeLeft.height
        readonly property bool otherReady: header.height !== 0 && label.height !== 0 && timeLeft.height !== 0
        id: column
        width: parent.width

        PageHeader {
            id: header
            title: qsTr("Quiz (%1 / %2)").arg(page.current).arg(page.count)
        }

        Loader {
            property int maximumHeight: Math.min(parent.width, page.height - column.otherHeight - choices.minimumHeight)
            property int maximumWidth: parent.width
            property bool ready: parent.width !== 0 && page.height !== 0 && column.otherReady && choices.minimumHeight !== 0

            anchors.horizontalCenter: parent.horizontalCenter
            sourceComponent: setup.quizType === "flags" ? flagComponent : setup.quizType === "maps" ? mapComponent : setup.quizType === "capitals" ? capitalComponent : null
        }

        Label {
            id: label
            color: palette.highlightColor
            font.pixelSize: Theme.fontSizeSmall
            horizontalAlignment: Text.AlignHCenter
            text: {
                if (setup.quizType === "flags") {
                    return qsTr("Guess which country this flag belongs to")
                }
                if (setup.quizType === "maps") {
                    return qsTr("Guess which country is highlighted on the map")
                }
                if (setup.quizType === "capitals") {
                    if (dataModel.get(index).capital.indexOf(';') === -1) {
                        return qsTr("Guess which country's capital is this")
                    } else {
                        return qsTr("Guess which country's capitals are these")
                    }
                }
                return ""
            }
            width: parent.width
            wrapMode: Text.Wrap
        }

        Item {
            readonly property int smallFontSize: Theme.fontSizeLarge
            readonly property int largeFontSize: Theme.fontSizeExtraLarge

            id: timerItem
            height: timeLeft.height
            width: parent.width

            Icon {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: Theme.paddingSmall / 2
                }
                color: palette.highlightColor
                source: "image://theme/icon-s-duration"

                Component.onCompleted: {
                    var change = (timerItem.largeFontSize / timerItem.smallFontSize - 1) * timeLeft.contentWidth
                    anchors.horizontalCenterOffset = -timeLeft.width / 2 - Theme.paddingMedium - change
                }
            }

            Label {
                id: timeLeft
                anchors.horizontalCenter: parent.horizontalCenter
                color: palette.highlightColor
                font.pixelSize: timerItem.smallFontSize
                height: timerItem.largeFontSize + Theme.paddingMedium
                text: quizTimer.timeAsString(quizTimer.timeLimit)
                verticalAlignment: Text.AlignVCenter

                states: [
                    State {
                        name: "enlarged"

                        PropertyChanges {
                            scale: timerItem.largeFontSize / timerItem.smallFontSize
                            target: timeLeft
                        }
                    },
                    State {
                        name: "alerted"
                        extend: "enlarged"

                        PropertyChanges {
                            color: "red"
                            target: timeLeft
                        }
                    }

                ]

                transitions: Transition {
                    ScaleAnimator {
                        duration: 500
                        easing.type: Easing.InOutQuad
                    }

                    ColorAnimation {
                        duration: 500
                        easing.type: Easing.InOutQuad
                        property: "color"
                    }
                }

                Connections {
                    target: quizTimer.tick
                    onTriggered: {
                        var left = quizTimer.timeLeft
                        timeLeft.text = quizTimer.timeAsString(left)
                        if (quizTimer.running) {
                            timeLeft.state = left % 1000 >= 500 ? left < 5000 ? "alerted" : "enlarged" : ""
                        }
                    }
                }
            }
        }
    }

    ListView {
        readonly property int maximumHeight: Math.min(Math.min(page.width, page.height / 2), (Theme.itemSizeLarge + Theme.paddingLarge) * setup.choicesCount)
        readonly property int minimumHeight: Math.min((Theme.itemSizeSmall + Theme.paddingSmall) * 5, maximumHeight)
        readonly property bool smallItems: height / setup.choicesCount < Theme.itemSizeMedium + Theme.paddingMedium

        id: choices
        anchors.bottom: parent.bottom
        boundsBehavior: Flickable.StopAtBounds
        height: Math.min(maximumHeight, Math.max(minimumHeight, page.height - column.height))
        model: DelegateModel {
            signal highlightCorrect
            signal highlightAllWrong

            id: delegateModel
            delegate: Component {
                QuizButton {
                    id: button
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: (choices.height / setup.choicesCount) - choices.spacing
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
        opacity: 0.0
        spacing: smallItems ? Theme.paddingSmall : Theme.paddingMedium
        width: parent.width

        Behavior on opacity {
            FadeAnimator {
                id: fadeIn
                duration: 300
                onRunningChanged: if (!running && !closeTimer.running) quizTimer.start()
            }
        }
    }

    Timer {
        property bool wasCorrect

        id: closeTimer
        interval: 1500
        onTriggered: {
            var correctAnswers = page.correctAnswers
            correctAnswers.push(wasCorrect)
            if (current >= count) {
                pageStack.replace(Qt.resolvedUrl("ResultsPage.qml"), {
                    indices: page.indices,
                    correctAnswers: correctAnswers,
                    setup: page.setup
                })
                config.hasPlayed = true
            } else {
                pageStack.replace(Qt.resolvedUrl("QuizPage.qml"), {
                    indices: page.indices,
                    current: page.current + 1,
                    correctAnswers: correctAnswers,
                    setup: page.setup
                })
            }
        }
    }

    Component {
        id: flagComponent

        Image {
            source: "../../assets/flags/" + dataModel.get(index).iso + ".svg"
            sourceSize.height: maximumHeight
            sourceSize.width: maximumWidth
        }
    }

    Component {
        id: mapComponent

        Map {
            code: dataModel.get(index).iso
            model: ready ? mapModel : null
            sourceSize: {
                var size = Math.min(maximumWidth, maximumHeight)
                return Qt.size(size, size)
            }
        }
    }

    Component {
        id: capitalComponent

        Item {
            height: capitalsLabel.contentHeight + 2 * Theme.paddingLarge
            width: maximumWidth

            Label {
                id: capitalsLabel

                color: palette.highlightColor
                font.pixelSize: Theme.fontSizeLarge
                horizontalAlignment: Text.AlignHCenter
                text: {
                    var capitals = dataModel.get(index).capital.split(';')
                    switch (capitals.length) {
                    case 1:
                        return qsTr("%1").arg(capitals[0])
                    case 2:
                        return qsTr("%1 and %2").arg(capitals[0]).arg(capitals[1])
                    case 3:
                        return qsTr("%1, %2 and %3").arg(capitals[0]).arg(capitals[1]).arg(capitals[2])
                    }
                    console.warn("UNIMPLEMENTD: Bad number of capitals", capitals.length)
                    return ""
                }
                width: parent.width
                wrapMode: Text.Wrap
            }
        }
    }

    KeepAlive { enabled: true }

    Connections {
        target: quizTimer
        onTriggered: {
            timeLeft.state = "alerted"
            delegateModel.highlightAllWrong()
            closeInSecond(-1)
        }
    }

    Component.onCompleted: {
        var choices = Helpers.getIndexArray(dataModel)
        choices.swap(0, index)
        if (setup.sameRegion) {
            var region = dataModel.get(index).region
            choices = Helpers.filterIndexArray(dataModel, choices, function(item) {
                return item.region === region
            })
        }
        for (var i = 1; i < setup.choicesCount; ++i) {
            choices.swap(i, i + Math.floor(Math.random() * (choices.length - i)))
        }
        for (i = 0; i < setup.choicesCount; ++i) {
            delegateModel.items.addGroups(choices[i], 1, "included")
        }
        for (i = 0; i < includedGroup.count - 1; ++i) {
            includedGroup.move(i, i + Math.floor(Math.random() * (includedGroup.count - i)), 1)
        }
    }
}