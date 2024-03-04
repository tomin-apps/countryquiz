/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQml.Models 2.2
import QtQuick 2.6
import Sailfish.Silica 1.0
import "../helpers.js" as Helpers

Item {
    id: page

    SilicaListView {
        id: view
        anchors.fill: parent
        model: loader.item

        ViewPlaceholder {
            enabled: !config.hasPlayed
            text: qsTr("Play a quiz at least once to see all the countries")
            hintText: qsTr("Swipe to left and press 'Quiz me!'")
        }

        VerticalScrollDecorator { }
    }

    Loader {
        id: loader
        asynchronous: true
        source: Qt.resolvedUrl("../components/CountryListDelegateModel.qml")
    }
}