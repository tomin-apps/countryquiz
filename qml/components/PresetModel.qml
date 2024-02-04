/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

ListModel {
    property int selectedCount: _currentItem !== null ? _currentItem.count : 0
    property int selectedChoices: _currentItem !== null ? _currentItem.choices : 0
    property int selectedTime: _currentItem !== null ? _currentItem.time: 0

    readonly property int currentIndex: _currentIndex
    readonly property bool presetSelected: _currentIndex >= 0 && _currentItem !== null
    readonly property string presetTitle: presetSelected ? _currentItem.title : qsTr("None")
    readonly property int questionCount: _questionCount < 0 ? dataModel.count : _questionCount
    readonly property int choicesCount: presetSelected ? _currentItem.choices : selectedChoices
    readonly property int timeToAnswer: presetSelected ? _currentItem.time : selectedTime

    property int _currentIndex
    readonly property var _currentItem: currentIndex >= 0 && currentIndex < count ? get(currentIndex) : null
    readonly property int _questionCount: presetSelected ? _currentItem.count : selectedCount

    function checkPropInPreset(index, prop) {
        var preset = get(index)
        if (prop === "count") {
            return preset.count === selectedCount
        } if (prop === "choices") {
            return preset.choices === selectedChoices
        } if (prop === "time") {
            return preset.time === selectedTime
        }
        return false
    }

    function checkProp(changedProp) {
        for (var i = 0; i < count; ++i) {
            if (checkPropInPreset(i, changedProp)) {
                var preset = get(i)
                if (selectedCount === preset.count
                        && selectedChoices === preset.choices
                        && selectedTime === preset.time) {
                    selectPreset(i)
                    return
                }
            }
        }
        invalidatePreset()
    }

    function selectPreset(index) {
        var preset = get(index)
        selectedCount = preset.count
        selectedChoices = preset.choices
        selectedTime = preset.time
        _currentIndex = index
    }

    function invalidatePreset() {
        _currentIndex = -1
    }

    id: presetModel

    ListElement {
        title: "Normal"
        count: 15
        choices: 4
        time: 15
    }

    ListElement {
        title: "Long"
        count: 80
        choices: 4
        time: 15
    }

    ListElement {
        title: "All"
        count: -1
        choices: 4
        time: 15
    }

    onSelectedCountChanged: checkProp("count")
    onSelectedChoicesChanged: checkProp("choices")
    onSelectedTimeChanged: checkProp("time")
}