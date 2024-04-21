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
            bottomPadding: Theme.paddingLarge
            spacing: Theme.paddingMedium
            width: aboutPage.width

            PageHeader {
                title: qsTr("About")
                description: qsTr("Country Quiz")
                height: Math.max(implicitHeight, icon.height + Theme.paddingLarge)
                leftMargin: Theme.horizontalPageMargin + Theme.paddingLarge
                rightMargin: Theme.paddingLarge + icon.width + Theme.horizontalPageMargin

                Image {
                    id: icon

                    anchors {
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }
                    source: Qt.resolvedUrl("../../harbour-countryquiz.svg")
                    sourceSize.height: Theme.iconSizeLauncher
                    sourceSize.width: Theme.iconSizeLauncher
                }
            }

            Label {
                color: palette.highlightColor
                text: qsTr("Country Quiz is a quiz game about states in the world. You can practise "
                          + "recognition of flags, maps and capitals. Results are collected into local "
                          + "database for you to see your own progress.")
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
            }

            SectionHeader {
                text: qsTr("Development")
            }

            Label {
                color: palette.highlightColor
                linkColor: Theme.primaryColor
                text: qsTr("You may obtain source code and report bugs on Github: <a href=%2>%1</a>")
                    .arg("github.com/tomin-apps/countryquiz")
                    .arg("\"https://github.com/tomin-apps/countryquiz/\"")
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
                onLinkActivated: Qt.openUrlExternally(link)
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Contributors")
                onClicked: pageStack.push(contributorsPageComponent)
            }

            SectionHeader {
                text: qsTr("License")
            }

            Label {
                color: palette.highlightColor
                text: qsTr("Country Quiz is licensed under MIT license. Touch the button below for more information.")
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("License")
                onClicked: pageStack.push(licensePageComponent)
            }
        }

        VerticalScrollDecorator { }
    }

    Component {
        id: contributorsPageComponent

        Page {
            function load() {
                var xhr = new XMLHttpRequest
                xhr.open("GET", Qt.resolvedUrl("../../TRANSLATORS"))
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        content.text = xhr.responseText
                    } else {
                        busyIndicator.running = false
                    }
                }
                xhr.send()
            }

            id: contributorsPage
            allowedOrientations: Orientation.All
            onStatusChanged: if (status == PageStatus.Active) load()

            BusyIndicator {
                id: busyIndicator
                anchors.centerIn: parent
                running: content.text === ""
                size: BusyIndicatorSize.Large
            }

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: contributors.height

                Column {
                    id: contributors
                    bottomPadding: Theme.paddingLarge
                    spacing: Theme.paddingMedium
                    width: contributorsPage.width

                    PageHeader {
                        title: qsTr("Contributors")
                    }

                    Label {
                        color: palette.highlightColor
                        text: qsTr("Original idea and development by %1.")
                            .arg("Tomi Leppänen")
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        wrapMode: Text.Wrap
                        x: Theme.horizontalPageMargin
                    }

                    SectionHeader {
                        text: qsTr("Translators")
                    }

                    Label {
                        id: content
                        color: palette.highlightColor
                        opacity: content.text !== "" ? 1.0 : 0.0
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        wrapMode: Text.Wrap
                        x: Theme.horizontalPageMargin

                        Behavior on opacity {
                            FadeAnimator {
                                duration: 500
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: licensePageComponent

        Page {
            function load() {
                var xhr = new XMLHttpRequest
                xhr.open("GET", Qt.resolvedUrl("../../COPYING"))
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        content.text = xhr.responseText
                    }
                }
                xhr.send()
            }

            id: licensePage
            allowedOrientations: Orientation.All
            onStatusChanged: if (status == PageStatus.Active) load()

            BusyIndicator {
                anchors.centerIn: parent
                running: content.text === ""
                size: BusyIndicatorSize.Large
            }

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: license.height

                Column {
                    id: license
                    bottomPadding: Theme.paddingLarge
                    spacing: Theme.paddingMedium
                    width: licensePage.width

                    PageHeader {
                        title: qsTr("License")
                        description: qsTr("MIT license")
                    }

                    Label {
                        id: content
                        color: palette.highlightColor
                        opacity: content.text !== "" ? 1.0 : 0.0
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        wrapMode: Text.Wrap
                        x: Theme.horizontalPageMargin

                        Behavior on opacity {
                            FadeAnimator {
                                duration: 500
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                }
            }
        }
    }
}