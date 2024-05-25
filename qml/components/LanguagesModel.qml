/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import QtQuick.XmlListModel 2.0

XmlListModel {
    readonly property bool ready: status === XmlListModel.Ready
    readonly property string defaultLanguage: {
        var preferred = Qt.locale().uiLanguages
        for (var i = 0; i < preferred.length; ++i) {
            for (var j = 0; j < count; ++j) {
                if (get(j).code === preferred[i]) {
                    return preferred[i]
                }
            }
        }
        return "en-GB"
    }

    function getWikipediaLink(language) {
        for (var i = 0; i < count; ++i) {
            var item = get(i)
            if (item.code === language) {
                return item.url
            }
        }
        return "https://en.wikipedia.org/wiki/"
    }

    query: "/languages/language"
    source: Qt.resolvedUrl("../../assets/data.xml")

    XmlRole {
        name: "code"
        query: "@code/string()"
    }

    XmlRole {
        name: "name"
        query: "@name/string()"
    }

    XmlRole {
        name: "url"
        query: "@url/string()"
    }
}