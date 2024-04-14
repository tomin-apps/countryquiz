/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"
import "../presets"

Item {
    property string openedSection

    function isInitialSection(section) {
        return config.lastOpenedStatsSection === section
    }

    id: statsTab
    onOpenedSectionChanged: config.setLastOpenedStatsSection(openedSection)

    SilicaFlickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: group.height

        ExpandingSectionGroup {
            id: group
            animateToExpandedSection: false
            width: parent.width

            StatsSection {
                expanded: isInitialSection(quizType)
                presets: FlagQuizPresets { }
                quizType: "flags"
                title: qsTr("Flag Quiz")
            }
            StatsSection {
                expanded: isInitialSection(quizType)
                presets: MapQuizPresets { }
                quizType: "maps"
                title: qsTr("Map Quiz")
            }
            StatsSection {
                expanded: isInitialSection(quizType)
                presets: CapitalQuizPresets { }
                quizType: "capitals"
                title: qsTr("Capital City Quiz")
            }
        }

        VerticalScrollDecorator { }
    }
}