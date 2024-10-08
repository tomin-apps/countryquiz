/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6

ListModel {
    ListElement {
        name: "easy"
        choices: 3
        region: false
        time: 60
    }

    ListElement {
        name: "regular"
        choices: 4
        region: false
        time: 30
    }

    ListElement {
        name: "veteran"
        choices: 5
        region: true
        time: 15
    }
}