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
                linkColor: palette.primaryColor
                //% "Country Quiz is licensed under <a href=%1>MIT license</a>. "
                //% "Map assets are licensed under <a href=%2>Creative Commons BY-SA 4.0</a>."
                text: qsTrId("countryquiz-la-license_description")
                    .arg("\"#mit\"")
                    .arg("\"#cc-by-sa\"")
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
                onLinkActivated: {
                    if (link === "#mit") {
                        pageStack.push(licensePageComponent, {
                           "file": "COPYING",
                           //% "MIT license"
                           "name": qsTrId("countryquiz-la-mit_license")
                        })
                    } else if (link === "#cc-by-sa") {
                        pageStack.push(licensePageComponent, {
                           "file": "assets/COPYING.CC-BY-SA-4.0.txt",
                           //% "Creative Commons BY-SA 4.0"
                           "name": qsTrId("countryquiz-la-cc_by_sa_license"),
                           //% "Map file is based on work of Allice Hunter."
                           "preface": qsTrId("countryquiz-la-assets_map_author")
                        })
                    }
                }
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
                        //% "Original idea and development by Tomi Leppänen."
                        text: qsTrId("countryquiz-la-main_developer")
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        wrapMode: Text.Wrap
                        x: Theme.horizontalPageMargin
                    }

                    SectionHeader {
                        //% "Assets"
                        text: qsTrId("countryquiz-se-assets")
                    }

                    Label {
                        color: palette.highlightColor
                        //% "Map file is based on work of Allice Hunter."
                        text: qsTrId("countryquiz-la-assets_map_author")
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
            property string file
            property string name
            property string preface

            function load() {
                var xhr = new XMLHttpRequest
                xhr.open("GET", Qt.resolvedUrl("../../" + file))
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
                        description: name
                    }

                    Label {
                        color: palette.secondaryHighlightColor
                        text: preface
                        visible: text !== ""
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        wrapMode: Text.Wrap
                        x: Theme.horizontalPageMargin
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