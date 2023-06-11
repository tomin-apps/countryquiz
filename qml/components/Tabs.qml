/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    property int currentIndex: -1
    property alias model: tabs.model

    readonly property Item _currentItem: currentIndex >= 0 && currentIndex < tabs.count ? tabs.itemAt(currentIndex) : null

    signal changeTab(int index)

    height: Theme.itemSizeLarge

    Row {
        id: tabsRow
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            bottom: parent.bottom
        }

        Repeater {
            id: tabs
            delegate: MouseArea {
                property alias contentWidth: tabLabel.contentWidth

                height: parent.height
                width: contentWidth + Theme.paddingLarge

                Label {
                    id: tabLabel
                    anchors {
                        centerIn: parent
                        verticalCenterOffset: -Theme.paddingMedium
                    }
                    color: model.index === currentIndex ? Theme.highlightColor : Theme.primaryColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                    text: title
                }

                onClicked: changeTab(model.index)
            }
        }
    }

    Rectangle {
        anchors {
            bottom: parent.bottom
            bottomMargin: Theme.paddingLarge
        }
        color: Theme.highlightColor
        x: tabsRow.x + Theme.paddingLarge / 2 + (_currentItem != null ? _currentItem.x : 0)
        height: Math.ceil(Theme.pixelRatio * 2)
        width: _currentItem != null ? _currentItem.contentWidth : 0

        Behavior on x {
            NumberAnimation { }
        }

        Behavior on width {
            NumberAnimation { }
        }
    }
}