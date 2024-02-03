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
        model: countryListDelegateModel

        ViewPlaceholder {
            enabled: !config.hasPlayed
            text: qsTr("Play quiz at least once to see all the countries")
            hintText: qsTr("Swipe to left and press 'Quiz me!'")
        }

        VerticalScrollDecorator { }
    }

    DelegateModel {
        id: countryListDelegateModel

        function indexBefore(item) {
            /* textbook binary search for finding the leftmost suitable position */
            var left = 0
            var right = items.count
            while (left < right) {
                var middle = Math.floor((left + right) / 2)
                var middleItem = items.get(middle)
                if (middleItem.model.name < item.model.name) {
                    left = middle + 1
                } else {
                    right = middle
                }
            }
            return left
        }

        function insertUnsorted() {
            while (unsortedCountries.count > 0) {
                var item = unsortedCountries.get(0)
                var index = indexBefore(item)
                item.groups = "items"
                items.move(item.itemsIndex, index)
            }
        }

        delegate: BackgroundItem {
            id: item
            height: Theme.itemSizeLarge
            contentHeight: Theme.itemSizeLarge
            width: ListView.view.width

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.paddingMedium

                Image {
                    source: "../../assets/flags/" + iso + ".svg"
                    sourceSize.height: Theme.itemSizeMedium
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Theme.fontSizeLarge
                    text: pre ? pre + " " + name : name
                    truncationMode: TruncationMode.Fade
                    width: item.width - x - Theme.horizontalPageMargin
                }
            }

            onClicked: pageStack.push(Qt.resolvedUrl("CountryPage.qml"), { item: countryListDelegateModel.model.get(index) })
        }
        groups: DelegateModelGroup {
            id: unsortedCountries
            name: "unsorted"
            includeByDefault: true
            onChanged: countryListDelegateModel.insertUnsorted()
        }
        items.includeByDefault: false
        model: config.hasPlayed ? dataModel : 0
    }
}