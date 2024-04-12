/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import QtQuick.XmlListModel 2.0

XmlListModel {
    property string language

    source: Qt.resolvedUrl(language === "" ? "../../assets/data.xml" : "../../assets/data.%1.xml".arg(language))
    query: "/countries/country"

    XmlRole {
        name: "iso"
        query: "@iso/string()"
    }

    XmlRole {
        name: "pre"
        query: "pre/string()"
    }

    XmlRole {
        name: "name"
        query: "name/string()"
    }

    XmlRole {
        name: "alt"
        query: "alt/string()"
    }

    XmlRole {
        name: "capital"
        query: "string-join(capital, ';')"
    }

    XmlRole {
        name: "region"
        query: "region/string()"
    }

    XmlRole {
        name: "other"
        query: "string-join(other, ';')"
    }
}