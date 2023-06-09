/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import "pages"

ApplicationWindow {
    initialPage: Component { Flags { } }
    cover: Component {
        Cover {
            Label {
                anchors.centerIn: parent
                text: qsTr("Flag Game")
            }
        }
    }

    allowedOrientations: defaultAllowedOrientations
}