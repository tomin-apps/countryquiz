/*
 * Copyright (c) 2023-2025 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

.pragma library

Array.prototype.swap = function(a, b) {
    var tmp = this[b]
    this[b] = this[a]
    this[a] = tmp
}

Array.prototype.extend = function(other) {
    for (var i = 0; i < other.length; ++i) {
        this.push(other[i])
    }
}

String.prototype.startsWith = function(text) {
    for (var i = 0; i < text.length; ++i) {
        if (this[i] !== text[i])
            return false;
    }
    return true;
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
        //% "Easy"
        return qsTrId("countryquiz-la-easy")
    } if (name === "regular") {
        //% "Regular"
        return qsTrId("countryquiz-la-regular")
    } if (name === "veteran") {
        //% "Veteran"
        return qsTrId("countryquiz-la-veteran")
    } if (name === "expert") {
        //% "Expert"
        return qsTrId("countryquiz-la-expert")
    }
    //% "None"
    return qsTrId("countryquiz-la-none")
}

function getLengthTitleText(name) {
    if (name === "short") {
        //% "Short"
        return qsTrId("countryquiz-la-short")
    } if (name === "long") {
        //% "Long"
        return qsTrId("countryquiz-la-long")
    } if (name === "all") {
        //% "All"
        return qsTrId("countryquiz-la-all")
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