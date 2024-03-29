/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Nemo.Configuration 1.0

Item {
    property alias hasPlayed: group.hasPlayed
    readonly property string lastChosenQuizType: group.lastChosenQuizType || "flags"
    readonly property string lastOpenedStatsSection: group.lastOpenedStatsSection || "flags"

    function setLastChosenQuizType(type) {
        group.lastChosenQuizType = type
    }

    function setLastOpenedStatsSection(type) {
        group.lastOpenedStatsSection = type
    }

    ConfigurationGroup {
        id: group
        path: "/site/tomin/apps/CountryQuiz"

        property bool hasPlayed
        property string lastChosenQuizType
        property string lastOpenedStatsSection
    }
}