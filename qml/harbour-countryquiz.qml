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

    initialPage: Component {
        Page {
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
            }
        }
    }
    cover: Component {
        CoverBackground {
            Label {
                anchors.centerIn: parent
                //% "Country Quiz"
                text: qsTrId("countryquiz-la-app_name")
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

        id: signaler
    }
}