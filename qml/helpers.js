/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

.pragma library

Array.prototype.swap = function(a, b) {
    var tmp = this[b]
    this[b] = this[a]
    this[a] = tmp
}

function getIndexArray(model) {
    var indices = []
    for (var i = 0; i < model.count; ++i) {
        indices[i] = i
    }
    return indices
}

function filterIndexArray(model, array, test) {
    var indices = []
    for (var i = 0; i < model.count; ++i) {
        if (test(model.get(array[i]))) {
            indices[indices.length] = array[i]
        }
    }
    return indices
}

function pickRandomIndices(model, indices, count) {
    for (var i = 0; i < count; ++i) {
        var index = i + Math.floor(Math.random() * (indices.length - i))
        indices.swap(i, index)
    }
    return indices.splice(0, count)
}

function getPresetTitleText(name) {
    if (name === "easy") {
        return qsTr("Easy")
    } if (name === "regular") {
        return qsTr("Regular")
    } if (name === "veteran") {
        return qsTr("Veteran")
    }
    return qsTr("None")
}

function getLengthTitleText(name) {
    if (name === "short") {
        return qsTr("Short")
    } if (name === "long") {
        return qsTr("Long")
    } if (name === "all") {
        return qsTr("All")
    }
    return ""
}

function _digits(value) {
    return (Math.floor(value / 10)).toString() + (value % 10).toString()
}

function timeAsString(time) {
    if (time < 0)
        time = 0
    var tenths = Math.floor(time / 100) % 10
    var seconds = Math.floor(time / 1000) % 60
    var minutes = Math.floor(time / 60000) % 60
    var hours = Math.floor(time / 3600000)
    return (hours === 0 ? minutes.toString()
                        : (hours.toString() + ":" + _digits(minutes.toString())))
            + ":" + _digits(seconds.toString()) + "." + tenths.toString()
}