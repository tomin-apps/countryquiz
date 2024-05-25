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
                //% "Select language for country and capital names and quiz statistics"
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