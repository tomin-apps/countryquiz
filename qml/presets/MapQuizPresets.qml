/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6

ListModel {
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
        region: true
        time: 30
    }

    ListElement {
        name: "veteran"
        count: 15
        choices: 5
        region: true
        time: 15
    }
}