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

function pickRandomIndices(model, count) {
    var indices = getIndexArray(model)
    for (var i = 0; i < count; ++i) {
        var index = i + Math.floor(Math.random() * (indices.length - i))
        indices.swap(i, index)
    }
    return indices.splice(0, count)
}
