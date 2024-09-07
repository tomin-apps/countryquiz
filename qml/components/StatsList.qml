/*
 * Copyright (c) 2024 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import CountryQuiz 1.0
import QtQuick 2.6
import Sailfish.Silica 1.0
import "../helpers.js" as Helpers

ListView {
    property color primaryTextColor: palette.primaryColor
    property color secondaryTextColor: palette.secondaryColor
    property int horizontalMargin: Theme.paddingMedium

    boundsBehavior: Flickable.StopAtBounds
    height: (model !== 0 ? model.count : 0) * Theme.itemSizeSmall
    delegate: Rectangle {
        height: Theme.itemSizeSmall
        color: index % 2 == 0 ? Theme.rgba(palette.overlayBackgroundColor, Theme.opacityLow) : "transparent"
        width: ListView.view.width

        Label {
            id: positionLabel
            anchors {
                left: parent.left
                leftMargin: horizontalMargin
                verticalCenter: parent.verticalCenter
            }
            color: secondaryTextColor
            font.pixelSize: Theme.fontSizeLarge
            text: model.position
        }

        Label {
            anchors {
                left: positionLabel.right
                leftMargin: Theme.paddingMedium
                top: parent.top
            }
            color: primaryTextColor
            //% "You"
            text: model.name || qsTrId("countryquiz-la-you")
            truncationMode: TruncationMode.Fade
            width: parent.width - positionLabel.width - scoreLabel.width - Theme.paddingMedium * 2 - horizontalMargin * 2
        }

        Label {
            anchors {
                left: positionLabel.right
                leftMargin: Theme.paddingMedium
                bottom: parent.bottom
            }
            color: secondaryTextColor
            //: %1 is the date when the game was played, try to keep this short
            //% "On %1"
            text: qsTrId("countryquiz-la-on_date").arg(model.datetime.toLocaleString(Qt.locale(), Locale.ShortFormat))
        }

        Label {
            id: scoreLabel
            anchors {
                right: parent.right
                rightMargin: horizontalMargin
                top: parent.top
            }
            color: primaryTextColor
            //: %1 is number of right answers out of %2 total answer to reward %3 points, try to keep this short
            //% "%1 / %2 for %3 p"
            text: qsTrId("countryquiz-la-questions_out_of_questions_for_points")
                    .arg(model.number_of_correct)
                    .arg(model.length)
                    .arg(model.score)
        }

        Label {
            anchors {
                right: parent.right
                rightMargin: horizontalMargin
                bottom: parent.bottom
            }
            color: secondaryTextColor
            //: %1 is time that it took to finish the quiz, try to keep this short
            //% "In %1"
            text: qsTrId("countryquiz-la-in_time_as_sentence").arg(Helpers.timeAsString(model.time))
        }
    }
}