/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQml.Models 2.2
import QtQuick 2.6
import Sailfish.Silica 1.0
import "../helpers.js" as Helpers

DelegateModel {
    property Timer insertTimer: Timer {
        interval: 0
        onTriggered: insertUnsorted()
    }

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
            unsortedCountries.setGroups(0, 1, ["items"])
            items.move(items.length - 1, index, 1)
        }
    }

    id: countryListDelegateModel
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

        onClicked: pageStack.push(Qt.resolvedUrl("../pages/CountryPage.qml"), { item: countryListDelegateModel.model.get(index) })
    }
    groups: DelegateModelGroup {
        id: unsortedCountries
        name: "unsorted"
        includeByDefault: true
        onCountChanged: if (count > 0) insertTimer.start()
    }
    items.includeByDefault: false
    model: config.hasPlayed && dataModel.ready ? dataModel : 0
    Component.onCompleted: insertTimer.start()
}