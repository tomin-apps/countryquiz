/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../helpers.js" as Helpers

Item {
    property var dataModel: _dataModel

    id: page

    SilicaFlickable {
        anchors.fill: parent

        // TODO: Add selection for the number of questions
        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Quiz me!")

            onClicked:  {
                pageStack.push(Qt.resolvedUrl("Quiz.qml"), {
                    indices: Helpers.pickRandomIndices(page.dataModel, 15),
                    model: page.dataModel
                })
            }
        }

        VerticalScrollDecorator { }
    }
}