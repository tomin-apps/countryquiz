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
    property var model

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
            width: parent.width

            Label {
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeLarge
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("%1 / %2 correct").arg(correctAnswersCount).arg(count)
                width: parent.width
            }

            Item { height: Theme.paddingLarge; width: parent.width }

            Repeater {
                model: correctAnswers

                BackgroundItem {
                    property bool correct: modelData
                    property int current: indices[index]
                    property string name: page.model.get(current).name

                    id: item
                    height: Theme.itemSizeSmall
                    width: parent.width

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        color: highlighted ? Theme.highlightColor : (item.correct ? "green" : "red")
                        font.pixelSize: Theme.fontSizeMedium
                        horizontalAlignment: Text.AlignHCenter
                        text: item.name
                        width: parent.width
                    }

                    onClicked: pageStack.push(Qt.resolvedUrl("Flag.qml"), { index: item.current, model: page.model })
                }
            }

            Item { height: Theme.paddingLarge; width: parent.width }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Play again")

                onClicked: {
                    pageStack.replace(Qt.resolvedUrl("Quiz.qml"), {
                        indices: Helpers.pickRandomIndices(model, count),
                        model: model
                    })
                }
            }
        }

        VerticalScrollDecorator { }
    }
}