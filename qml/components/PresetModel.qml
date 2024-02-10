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
    property bool selectedRegion: _currentItem !== null ? _currentItem.region : false
    property int selectedTime: _currentItem !== null ? _currentItem.time: 0

    readonly property int currentIndex: _currentIndex
    readonly property bool presetSelected: _currentIndex >= 0 && _currentItem !== null
    readonly property string presetTitle: getTitleText(presetSelected ? _currentItem.name : "none")
    readonly property int questionCount: _questionCount < 0 ? dataModel.count : _questionCount
    readonly property int choicesCount: presetSelected ? _currentItem.choices : selectedChoices
    readonly property bool sameRegion: presetSelected ? _currentItem.region : selectedRegion
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
        } if (prop === "region") {
            return preset.region === selectedRegion
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
                        && selectedRegion === preset.region
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
        selectedRegion = preset.region
        selectedTime = preset.time
        _currentIndex = index
    }

    function invalidatePreset() {
        _currentIndex = -1
    }


    function getTitleText(name) {
        if (name === "easy") {
            return qsTr("Easy")
        } if (name === "regular") {
            return qsTr("Regular")
        } if (name === "veteran") {
            return qsTr("Veteran")
        }
        return qsTr("None")
    }

    id: presetModel

    ListElement {
        name: "easy"
        count: 15
        choices: 3
        region: false
        time: 30
    }

    ListElement {
        name: "regular"
        count: 15
        choices: 4
        region: false
        time: 15
    }

    ListElement {
        name: "veteran"
        count: 15
        choices: 5
        region: true
        time: 15
    }

    onSelectedCountChanged: checkProp("count")
    onSelectedChoicesChanged: checkProp("choices")
    onSelectedRegionChanged: checkProp("region")
    onSelectedTimeChanged: checkProp("time")
}