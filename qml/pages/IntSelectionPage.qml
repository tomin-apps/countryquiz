/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

Dialog {
    property int value
    property int minimum
    property int maximum
    property alias title: header.title
    property alias description: textField.label
    property string tooLowHint: invalidHint
    property string tooHighHint: invalidHint
    property string invalidHint: qsTr("You must specify an integer between %1 and %2").arg(minimum).arg(maximum)

    readonly property var selectedValue: textField.text.length > 0 ? parseInt(textField.text) : NaN

    id: dialog
    acceptDestinationAction: PageStackAction.Pop
    canAccept: textField.acceptableInput

    DialogHeader {
        id: header
    }

    TextField {
        id: textField
        acceptableInput: !isNaN(selectedValue) && minimum <= selectedValue && selectedValue <= maximum
        anchors.top: header.bottom
        focus: true
        inputMethodHints: Qt.ImhDigitsOnly
        text: dialog.value
        width: parent.width

        EnterKey.enabled: canAccept
        EnterKey.iconSource: "image://theme/icon-m-enter-accept"
        EnterKey.onClicked: if (canAccept) accept()
    }

    Label {
        anchors.top: textField.bottom
        color: palette.secondaryHighlightColor
        text: {
            if (isNaN(selectedValue)) {
                return invalidHint
            } if (selectedValue < minimum) {
                return tooLowHint
            } if (selectedValue > maximum) {
                return tooHighHint
            }
            return ""
        }
        visible: text.length > 0
        width: parent.width - 2 * Theme.horizontalPageMargin
        wrapMode: Text.Wrap
        x: Theme.horizontalPageMargin
    }
}