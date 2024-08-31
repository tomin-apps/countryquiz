/*
 * Copyright (c) 2023-2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import CountryQuiz 1.0
import QtQuick 2.6
import Sailfish.Silica 1.0
import "components"
import "helpers.js" as Helpers
import "pages"

ApplicationWindow {
    property alias config: config
    property alias dataModel: dataModel
    property alias mapModel: mapModel
    property alias quizTimer: quizTimer
    property alias signaler: signaler

    property string quizType
    property int progress
    property int total

    id: appWindow
    initialPage: Component {
        Page {
            id: page

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: height
                contentWidth: width

                PullDownMenu {
                    MenuItem {
                        //% "About"
                        text: qsTrId("countryquiz-me-about")
                        onClicked: pageStack.push(Qt.resolvedUrl("pages/AboutPage.qml"))
                    }

                    MenuItem {
                        //% "Options"
                        text: qsTrId("countryquiz-me-options")
                        onClicked: pageStack.push(Qt.resolvedUrl("pages/OptionsPage.qml"))
                    }
                }

                Tabs {
                    id: tabs
                    currentIndex: paged.currentIndex
                    model: pageModel
                    width: parent.width
                    z: 1

                    onChangeTab: paged.currentIndex = index
                }

                PagedView {
                    id: paged
                    anchors.fill: parent
                    contentItem.height: parent.height - tabs.height
                    contentItem.y: tabs.height
                    contentItem.width: parent.width
                    currentIndex: 1
                    delegate: Loader {
                        clip: true
                        height: PagedView.contentHeight
                        source: Qt.resolvedUrl(model.url)
                        width: PagedView.contentWidth
                    }
                    model: pageModel
                }

                Connections {
                    target: signaler
                    onShowQuizTabImmediately: {
                        pageStack.pop(page, PageStackAction.Immediate)
                        tabs.animate = false
                        paged.currentIndex = 1
                        tabs.animate = true
                        appWindow.activate()
                    }
                }
            }

            onStatusChanged: {
                if (status === PageStatus.Activating) {
                    appWindow.progress = 0
                    appWindow.total = 0
                    appWindow.quizType = ""
                }
            }
        }
    }

    cover: Component {
        CoverBackground {
            Column {
                anchors.centerIn: parent
                spacing: Theme.paddingLarge
                width: parent.width - Theme.paddingLarge * 2

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: palette.primaryColor
                    source: appWindow.quizType === ""
                            ? "../assets/icons/globe.svg"
                            : "../assets/icons/%1.svg".arg(appWindow.quizType)
                    sourceSize: Qt.size(parent.width, parent.width)
                }

                Label {
                    color: palette.primaryColor
                    horizontalAlignment: Text.AlignHCenter
                    text: {
                        if (appWindow.quizType === "capitals") {
                            //% "Capital City Quiz"
                            return qsTrId("countryquiz-la-capital_quiz")
                        } else if (appWindow.quizType === "flags") {
                            //% "Flag Quiz"
                            return qsTrId("countryquiz-la-flag_quiz")
                        } else if (appWindow.quizType === "maps") {
                            //% "Map Quiz"
                            return qsTrId("countryquiz-la-map_quiz")
                        } else {
                            //% "Country Quiz"
                            return qsTrId("countryquiz-la-app_name")
                        }
                    }
                    truncationMode: TruncationMode.Elide
                    width: parent.width
                }

                Label {
                    color: palette.secondaryColor
                    horizontalAlignment: Text.AlignHCenter
                    text: appWindow.quizType !== "" && appWindow.progress >= 0 ? "%1 / %2".arg(appWindow.progress).arg(appWindow.total) : ""
                    truncationMode: TruncationMode.Elide
                    width: parent.width
                }

                CoverActionList {
                    enabled: appWindow.quizType === "" || appWindow.progress === -1

                    CoverAction {
                        iconSource: appWindow.progress === -1 ? "image://theme/icon-cover-backup" : "image://theme/icon-cover-play"
                        onTriggered: appWindow.progress === -1 ? signaler.playAgain() : signaler.showQuizTabImmediately()
                    }
                }
            }
        }
    }

    allowedOrientations: defaultAllowedOrientations

    QuizTimer { id: quizTimer }

    MapModel {
        id: mapModel
        invertedColors: palette.colorScheme === Theme.DarkOnLight
        mapFile: Qt.resolvedUrl("../assets/map.svg")
        miniMapSize: Qt.size(Screen.width, Screen.width)
    }

    LanguagesModel { id: languagesModel }

    DataModel {
        id: dataModel
        language: config.lastSelectedLanguage || (languagesModel.ready ? languagesModel.defaultLanguage : "")

        function getIndices(type) {
            var indices = Helpers.getIndexArray(dataModel)
            if (type === "capitals") {
                return Helpers.filterIndexArray(dataModel, indices, function(item) {
                    var capitals = item.capital.split(';')
                    for (var i = 0; i < capitals.length; ++i) {
                        if (capitals[i].search(item.name) !== -1 || item.name.search(capitals[i]) !== -1) {
                            return false
                        }
                    }
                    return true
                })
            }
            return indices
        }
    }

    Config { id: config }

    ListModel {
        id: pageModel

        ListElement {
            //% "Countries"
            title: qsTrId("countryquiz-la-countries")
            url: "pages/CountryListTab.qml"
        }

        ListElement {
            //% "Quiz"
            title: qsTrId("countryquiz-la-quiz")
            url: "pages/QuizSelectionTab.qml"
        }

        ListElement {
            //% "Stats"
            title: qsTrId("countryquiz-la-stats")
            url: "pages/StatsTab.qml"
        }
    }

    Item {
        signal resultSaved()
        signal playAgain()
        signal showQuizTabImmediately()

        id: signaler
    }
}