/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

Page {
    id: aboutPage

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content
            width: parent.width

            PageHeader {
                //% "Options"
                title: qsTrId("countryquiz-he-options")
                width: parent.width
            }

            ComboBox {
                readonly property var modes: ["solo", "party", "shared", "anonymous"]
                property bool ready
                currentIndex: {
                    for (var i = 0; i < modes.length; ++i) {
                        if (config.mode === modes[i])
                            return i
                    }
                    return 0
                }
                description: {
                    if (config.mode === "solo") {
                        //: Description for solo mode
                        //% "In this mode results are saved on device and are always attributed to you."
                        return qsTrId("countryquiz-de-solo_mode")
                    } else if (config.mode === "party") {
                        //: Description for party mode
                        //% "In this mode results are saved until the application is closed and name is asked after every quiz. "
                        //% "Best for playing with friends."
                        return qsTrId("countryquiz-de-party_mode")
                    } else if (config.mode === "shared") {
                        //: Description for shared device mode
                        //% "In this mode results are saved on device and name is asked after every quiz."
                        return qsTrId("countryquiz-de-shared_mode")
                    } else if (config.mode === "anonymous") {
                        //: Description for anonymous mode
                        //% "In this mode results are not saved and stats are disabled."
                        return qsTrId("countryquiz-de-anonymous_mode")
                    }
                    return ""
                }
                //% "Mode"
                label: qsTrId("countryquiz-la-mode")
                menu: ContextMenu {
                    //: Option to save results with name "you", for playing alone
                    //% "Solo"
                    MenuItem { text: qsTrId("countryquiz-me-solo_mode") }

                    //: Option to save results to temporary database, to play in group
                    //% "Party mode"
                    MenuItem { text: qsTrId("countryquiz-me-party_mode") }

                    //: Option to ask for name after every game, to play on shared device
                    //% "Shared device"
                    MenuItem { text: qsTrId("countryquiz-me-shared_device_mode") }

                    //: Option to never ask for name, results are not saved
                    //% "Anonymous"
                    MenuItem { text: qsTrId("countryquiz-me-anonymous_mode") }
                }
                width: parent.width
                onCurrentIndexChanged: if (ready) config.setMode(modes[currentIndex])
                Component.onCompleted: ready = true
            }

            ComboBox {
                property bool ready
                currentIndex: {
                    var language = dataModel.language || languagesModel.defaultLanguage
                    for (var i = 0; i < languagesModel.count; ++i) {
                        if (languagesModel.get(i).code === language) {
                            return i
                        }
                    }
                    return 0
                }
                //% "Select language for country and capital names and quiz statistics."
                description: qsTrId("countryquiz-de-language_combo_box")
                //% "Language"
                label: qsTrId("countryquiz-la-language")
                menu: ContextMenu {
                    Repeater {
                        delegate: MenuItem { text: name }
                        model: languagesModel
                    }
                }
                width: parent.width
                onCurrentIndexChanged: if (ready && languagesModel.ready) config.setLastSelectedLanguage(languagesModel.get(currentIndex).code)
                Component.onCompleted: ready = true
            }
        }

        VerticalScrollDecorator { }
    }
}