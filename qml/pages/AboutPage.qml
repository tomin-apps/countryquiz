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
                //% "About"
                title: qsTrId("countryquiz-he-about")
                //% "Country Quiz"
                description: qsTrId("countryquiz-la-app_name")
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
                //% "Country Quiz is a quiz game about states in the world. You can practise "
                //% "recognition of flags, maps and capitals. Results are collected into local "
                //% "database for you to see your own progress."
                text: qsTrId("countryquiz-la-about_text")
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
            }

            SectionHeader {
                //% "Development"
                text: qsTrId("countryquiz-se-development")
            }

            Label {
                color: palette.highlightColor
                linkColor: palette.primaryColor
                //% "You may obtain source code and report bugs on Github: <a href=%2>%1</a>"
                text: qsTrId("countryquiz-la-source_code_and_bugs")
                    .arg("github.com/tomin-apps/countryquiz")
                    .arg("\"https://github.com/tomin-apps/countryquiz/\"")
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
                onLinkActivated: Qt.openUrlExternally(link)
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                //% "Contributors"
                text: qsTrId("countryquiz-bt-contributors")
                onClicked: pageStack.push(contributorsPageComponent)
            }

            SectionHeader {
                //% "License"
                text: qsTrId("countryquiz-la-header")
            }

            Label {
                color: palette.highlightColor
                //% "Country Quiz is licensed under MIT license. Touch the button below for more information."
                text: qsTrId("countryquiz-la-license_description")
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                //% "License"
                text: qsTrId("countryquiz-bt-license")
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
                        //% "Contributors"
                        title: qsTrId("countryquiz-he-contributors")
                    }

                    Label {
                        color: palette.highlightColor
                        //% "Original idea and development by %1."
                        text: qsTrId("countryquiz-la-main_developer")
                            .arg("Tomi Leppänen")
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        wrapMode: Text.Wrap
                        x: Theme.horizontalPageMargin
                    }

                    SectionHeader {
                        //% "Translators"
                        text: qsTrId("countryquiz-se-translators")
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

                VerticalScrollDecorator { }
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
                        //% "License"
                        title: qsTrId("countryquiz-he-header")
                        //% "MIT license"
                        description: qsTrId("countryquiz-la-mit_license")
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

                VerticalScrollDecorator { }
            }
        }
    }
}