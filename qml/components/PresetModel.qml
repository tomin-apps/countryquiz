/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    property ListModel presets

    property int selectedCount: _currentItem !== null ? _currentItem.count : 0
    property int selectedChoices: _currentItem !== null ? _currentItem.choices : 0
    property bool selectedRegion: _currentItem !== null ? _currentItem.region : false
    property int selectedTime: _currentItem !== null ? _currentItem.time: 0

    readonly property int currentIndex: _currentIndex
    readonly property bool presetSelected: _currentIndex >= 0 && _currentItem !== null
    readonly property string presetTitle: getTitleText(presetSelected ? _currentItem.name : "none")
    readonly property int questionCount: _questionCount < 0 ? maximumLength : _questionCount
    readonly property int choicesCount: presetSelected ? _currentItem.choices : selectedChoices
    readonly property bool sameRegion: presetSelected ? _currentItem.region : selectedRegion
    readonly property int timeToAnswer: presetSelected ? _currentItem.time : selectedTime

    property int _currentIndex
    readonly property var _currentItem: presets && currentIndex >= 0 && currentIndex < presets.count ? presets.get(currentIndex) : null
    readonly property int _questionCount: presetSelected ? _currentItem.count : selectedCount

    function checkPropInPreset(index, prop) {
        if (presets) {
            var preset = presets.get(index)
            if (prop === "count") {
                return preset.count === selectedCount
            } if (prop === "choices") {
                return preset.choices === selectedChoices
            } if (prop === "region") {
                return preset.region === selectedRegion
            } if (prop === "time") {
                return preset.time === selectedTime
            }
        }
        return false
    }

    function checkProp(changedProp) {
        if (presets) {
            for (var i = 0; i < presets.count; ++i) {
                if (checkPropInPreset(i, changedProp)) {
                    var preset = presets.get(i)
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
    }

    function selectPreset(index) {
        if (presets) {
            var preset = presets.get(index)
            selectedCount = preset.count
            selectedChoices = preset.choices
            selectedRegion = preset.region
            selectedTime = preset.time
            _currentIndex = index
        }
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

    onSelectedCountChanged: checkProp("count")
    onSelectedChoicesChanged: checkProp("choices")
    onSelectedRegionChanged: checkProp("region")
    onSelectedTimeChanged: checkProp("time")
}