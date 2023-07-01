/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Nemo.Configuration 1.0

Item {
    property alias hasPlayed: group.hasPlayed
    ConfigurationGroup {
        id: group
        path: "/site/tomin/apps/CountriesQuiz"

        property bool hasPlayed
    }
}