/*
 * Copyright (c) 2023-2025 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import CountryQuiz 1.0
import Nemo.Configuration 1.0
import Nemo.KeepAlive 1.2
import QtQuick 2.6
import QtQml.Models 2.2
import Sailfish.Silica 1.0
import "../components"
import "../helpers.js" as Helpers

Page {
    id: page

    property int current: 1
    property var indices
    property var setup
    property var correctAnswers: new Array
    property var selectedAnswers: new Array
    property var times: new Array

    // TODO: How to avoid height changes when the keyboard appears the first time?
    readonly property int availableHeight: expertMode && saved.keyboardRectangleY > 0 ? saved.keyboardRectangleY : height
    readonly property int count: indices.length
    readonly property bool expertMode: setup.choicesCount === 0
    readonly property int index: indices[current - 1]
    readonly property bool finished: closeTimer.running

    function closeInSecond(index) {
        if (!finished) {
            closeTimer.selectedIndex = index
            closeTimer.running = true
        }
    }

    onStatusChanged: if (status === PageStatus.Active) choices.opacity = 1.0

    ConfigurationGroup {
        property int keyboardRectangleY: -1

        id: saved
        path: "/site/tomin/apps/CountryQuiz"

        Connections {
            target: Qt.inputMethod
            onKeyboardRectangleChanged: {
                var y = Qt.inputMethod.keyboardRectangle.y
                if (y > 0 && saved.keyboardRectangleY !== y) {
                    saved.keyboardRectangleY = y
                }
            }
        }
    }

    Connections {
        target: Qt.application
        onStateChanged: {
            if (Qt.application.state === Qt.ApplicationActive && status === PageStatus.Active) {
                fadeIn.enabled = false
                choices.opacity = 1.0
            }
        }
    }

    PageHeader {
        readonly property string name: {
            if (setup.quizType === "flags") {
                //% "Flag"
                return qsTrId("countryquiz-he-flag")
            } if (setup.quizType === "maps") {
                //% "Map"
                return qsTrId("countryquiz-he-map")
            } if (setup.quizType === "capitals") {
                //% "Capital City"
                return qsTrId("countryquiz-he-capital-city")
            }
            return ""
        }

        id: header
        title: "%1 %2 / %3".arg(name).arg(page.current).arg(page.count)
        z: 2
    }

    Column {
        readonly property int otherHeight: header.height + label.height + timeLeft.height
        readonly property bool otherReady: header.height !== 0 && label.height !== 0 && timeLeft.height !== 0
        property bool useHeaderSpace
        id: column
        anchors.top: useHeaderSpace ? page.top : header.bottom
        width: parent.width
        z: 1

        Loader {
            property int maximumHeight: {
                var maximum = Math.min(parent.width, page.availableHeight - column.otherHeight - choices.minimumHeight - choiceInput.height)
                if (setup.quizType === "maps" && maximum < parent.width) {
                    column.useHeaderSpace = true
                    return maximum + header.height
                } else {
                    column.useHeaderSpace = false
                }
                return maximum
            }
            property int maximumWidth: parent.width
            property bool ready: parent.width !== 0 && page.availableHeight !== 0 && column.otherReady && choices.minimumHeight !== 0

            anchors.horizontalCenter: parent.horizontalCenter
            sourceComponent: setup.quizType === "flags" ? flagComponent : setup.quizType === "maps" ? mapComponent : setup.quizType === "capitals" ? capitalComponent : null
        }

        Label {
            id: label
            color: palette.highlightColor
            font.pixelSize: Theme.fontSizeSmall
            horizontalAlignment: Text.AlignHCenter
            text: {
                if (setup.quizType === "flags") {
                    //% "Guess which country this flag belongs to"
                    return qsTrId("countryquiz-la-guess_flag")
                }
                if (setup.quizType === "maps") {
                    //% "Guess which country is highlighted on the map"
                    return qsTrId("countryquiz-la-guess_maps")
                }
                if (setup.quizType === "capitals") {
                    if (dataModel.get(index).capital.indexOf(';') === -1) {
                        //% "Guess which country's capital is this"
                        return qsTrId("countryquiz-la-guess_capital")
                    } else {
                        //% "Guess which country's capitals are these"
                        return qsTrId("countryquiz-la-guess_multiple_capitals")
                    }
                }
                return ""
            }
            width: parent.width
            wrapMode: Text.Wrap
        }

        Item {
            readonly property int smallFontSize: Theme.fontSizeLarge
            readonly property int largeFontSize: Theme.fontSizeExtraLarge

            id: timerItem
            height: timeLeft.height
            width: parent.width

            Icon {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: Theme.paddingSmall / 2
                }
                color: palette.highlightColor
                source: "image://theme/icon-s-duration"

                Component.onCompleted: {
                    var change = (timerItem.largeFontSize / timerItem.smallFontSize - 1) * timeLeft.contentWidth
                    anchors.horizontalCenterOffset = -timeLeft.width / 2 - Theme.paddingMedium - change
                }
            }

            Label {
                id: timeLeft
                anchors.horizontalCenter: parent.horizontalCenter
                color: palette.highlightColor
                font.pixelSize: timerItem.smallFontSize
                height: timerItem.largeFontSize + Theme.paddingMedium
                text: Helpers.timeAsString(quizTimer.timeLimit)
                verticalAlignment: Text.AlignVCenter

                states: [
                    State {
                        name: "enlarged"

                        PropertyChanges {
                            scale: timerItem.largeFontSize / timerItem.smallFontSize
                            target: timeLeft
                        }
                    },
                    State {
                        name: "alerted"
                        extend: "enlarged"

                        PropertyChanges {
                            color: "red"
                            target: timeLeft
                        }
                    }

                ]

                transitions: Transition {
                    ScaleAnimator {
                        duration: 500
                        easing.type: Easing.InOutQuad
                    }

                    ColorAnimation {
                        duration: 500
                        easing.type: Easing.InOutQuad
                        property: "color"
                    }
                }

                Connections {
                    target: quizTimer.tick
                    onTriggered: {
                        var left = quizTimer.timeLeft
                        timeLeft.text = Helpers.timeAsString(left)
                        if (quizTimer.running) {
                            timeLeft.state = left % 1000 >= 500 ? left < 5000 ? "alerted" : "enlarged" : ""
                        }
                    }
                }
            }
        }
    }

    ListView {
        readonly property int choicesCount: Math.max(setup.choicesCount, 1)
        readonly property int maximumHeight: Math.min(Math.min(page.width, page.availableHeight / 2), (Theme.itemSizeLarge + Theme.paddingLarge) * choicesCount)
        readonly property int minimumHeight: Math.min((Theme.itemSizeSmall + Theme.paddingSmall) * 5, maximumHeight)
        readonly property bool smallItems: height / choicesCount < Theme.itemSizeMedium + Theme.paddingMedium

        id: choices
        anchors.bottom: expertMode ? choiceInput.top : parent.bottom
        boundsBehavior: Flickable.StopAtBounds
        clip: expertMode
        height: Math.min(maximumHeight, Math.max(minimumHeight, page.availableHeight - column.height - (column.useHeaderSpace ? 0 : header.height)))
        model: DelegateModel {
            function reset() {
                // Move the items back to the right places
                var items = []
                for (var i = 0; i < includedGroup.count; ++i) {
                    items.push(includedGroup.get(i))
                }
                items.sort(function (a, b) {
                    return b.model.index - a.model.index
                })
                for (i = 0; i < items.length; ++i) {
                    var item = items[i]
                    item.inIncluded = false
                    if (item.model.index >= 0) {
                        delegateModel.items.move(item.itemsIndex, item.model.index, 1)
                    }
                }
            }

            signal highlightCorrect(int selected)
            signal highlightAllWrong(int selected)
            signal highlightItem(int index, color colour)

            id: delegateModel
            delegate: Component {
                QuizButton {
                    id: button
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: !expertMode ? choices.height / choices.choicesCount - choices.spacing : Theme.itemSizeSmall
                    text: model.pre ? model.pre + " " + model.name : model.name
                    altText: !expertMode ? model.alt || "" : ""
                    radius: !expertMode ? undefined : 0
                    width: parent.width - (!expertMode ? 2 * Theme.horizontalPageMargin : 0)

                    onClicked: {
                        if (!page.finished) {
                            quizTimer.stop()
                            if (expertMode) {
                                choiceInput.forceActiveFocus()
                            }
                            if (model.index !== page.index) {
                                button.color = "red"
                            }
                            delegateModel.highlightCorrect(model.index)
                            page.closeInSecond(model.index)
                        }
                    }

                    Component.onCompleted: if (page.finished) button.color = (model.index === page.index) ? "green" : "red"

                    Connections {
                        target: delegateModel
                        onHighlightCorrect: if (model.index === page.index) button.color = "green"
                        onHighlightAllWrong: button.color = (model.index === page.index) ? "green" : "red"
                        onHighlightItem: if (model.index === index) button.color = colour
                    }
                }
            }
            filterOnGroup: "included"
            model: dataModel
            groups: [
                DelegateModelGroup {
                    id: includedGroup
                    name: "included"
                }
            ]
        }
        opacity: 0.0
        spacing: expertMode || smallItems ? Theme.paddingSmall : Theme.paddingMedium
        width: parent.width

        Behavior on opacity {
            id: fadeIn
            FadeAnimator {
                duration: 300
                onRunningChanged: if (!running && !closeTimer.running) quizTimer.start()
            }
        }
    }

    TextInput {
        property var list: null
        // TODO: Can we avoid the height reserved for suggestions?
        // TODO: Would like to do these but they break EnterKey behaviour
        //property var __inputMethodExtensions: {
        //    "keyboardClosingDisabled": true,
        //    "pasteDisabled": true
        //}

        function splitted(text, part) {
            var names = [{"weight": 0, "part": part, "text": text}]
            var weight = 1
            for (var i = 1; i < text.length; ++i) {
                if (text[i] === ' ' || text[i] === '-') {
                    var str = text.substr(i+1)
                    if (str !== "") {
                        names.push({
                            "weight": weight++,
                            "part": part,
                            "text": str
                        })
                    }
                }
            }
            return names
        }

        function buildMatchables(index) {
            var item = dataModel.get(index)
            var matchables = []
            if (item.pre) {
                matchables.push({
                    "weight": 0,
                    "part": 0,
                    "text": item.pre + ' ' + item.name
                })
            }
            var names = splitted(StringHelper.cleanup(item.name), 0)
            matchables.extend(names)
            if (item.alt !== "") {
                names = splitted(StringHelper.cleanup(item.alt), 1)
                matchables.extend(names)
            }
            var other = item.other.split(';')
            for (var i = 0; i < other.length; ++i) {
                if (other[i] !== "") {
                    names = splitted(StringHelper.cleanup(other[i]), 2)
                    matchables.extend(names)
                }
            }
            return matchables
        }

        function filter(text) {
            text = StringHelper.cleanup(text)
            var mistakes = text !== "" ? Math.log(text.length) / Math.LN2 : 0
            var found = []
            for (var i = 0; i < list.length; ++i) {
                var matchables = buildMatchables(list[i])
                for (var j = 0; j < matchables.length; ++j) {
                    var item = matchables[j]
                    var distance = StringHelper.levenshtein(text, item.text.substr(0, text.length))
                    if (distance <= mistakes) {
                        found.push([item.part, item.weight, distance, list[i]])
                        break
                    }
                }
            }
            found.sort()
            for (i = 0; i < found.length; ++i) {
                found[i] = found[i][3]
            }
            return found
        }

        id: choiceInput
        color: Theme.highlightColor
        cursorDelegate: Component {
            Rectangle {
                // TODO: Some odd issue with height
                id: cursor
                color: Theme.primaryColor
                height: choiceInput.font.pixelSize
                width: Math.ceil(Theme.pixelRatio * 1.5)

                Timer {
                    interval: 800
                    repeat: true
                    running: true
                    onTriggered: cursor.visible = !cursor.visible
                }
            }
        }
        enabled: expertMode
        font.pixelSize: Theme.fontSizeMedium
        focus: expertMode
        height: Theme.itemSizeExtraSmall
        inputMethodHints: Qt.ImhNoPredictiveText
        readOnly: !visible
        verticalAlignment: TextInput.AlignVCenter
        visible: expertMode && !page.finished && page.status !== PageStatus.Deactivating
        width: parent.width - 2 * Theme.horizontalPageMargin
        x: Theme.horizontalPageMargin
        y: page.availableHeight - height - Theme.paddingSmall

        EnterKey.enabled: expertMode && !page.finished && text !== "" && includedGroup.count >= 1 && choices.atYBeginning
        EnterKey.iconSource: "image://theme/icon-m-enter-accept"
        EnterKey.onClicked: {
            if (expertMode && !page.finished && text !== "") {
                quizTimer.stop()
                var indices = filter(text)
                if (indices.length >= 1) {
                    delegateModel.highlightCorrect(indices[0])
                    page.closeInSecond(indices[0])
                }
            }
        }

        onTextChanged: {
            if (expertMode && !page.finished) {
                delegateModel.reset()
                if (text !== "") {
                    var indices = filter(text)
                    // Collecting items to an array as move will rearrange them in items
                    var items = []
                    for (var i = 0; i < indices.length; ++i) {
                        var index = indices[i]
                        delegateModel.items.addGroups(index, 1, "included")
                        items.push(delegateModel.items.get(indices[i]))
                    }
                    // Move the items to the right places in includedGroup
                    for (i = 0; i < items.length; ++i) {
                        // Moving them in delegateModel group moves them in includedGroup too
                        delegateModel.items.move(items[i].itemsIndex, i, 1)
                    }
                    choices.positionViewAtBeginning()
                }
            }
        }

        Label {
            anchors.fill: parent
            color: Theme.secondaryHighlightColor
            font.pixelSize: choiceInput.font.pixelSize
            //% "Your choice"
            text: qsTrId("countryquiz-la-your_choice")
            opacity: choiceInput.text === "" ? 1.0 : 0.0
            verticalAlignment: Text.AlignVCenter

            Behavior on opacity {
                FadeAnimator {}
            }
        }

        Rectangle {
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: choiceInput.font.pixelSize / 2 + Theme.paddingMedium
            }
            color: choiceInput.color
            height: Math.ceil(Theme.pixelRatio * 2)
            width: parent.width
        }

        Connections {
            function updateHighlighted(selected) {
                delegateModel.reset()
                choices.clip = false
                // This is not enough to recreate the delegates
                delegateModel.items.addGroups(page.index, 1, "included")
                if (selected >= 0) {
                    delegateModel.items.addGroups(selected, 1, "included")
                } else {
                    includedGroup.insert({
                        //% "No answer given"
                        "name": qsTrId("countryquiz-la-no_answer"),
                        "index": -1,
                    })
                }
                // Thus sort the two items
                if (includedGroup.get(0).model.index !== page.index) {
                    includedGroup.move(1, 0, 1)
                }
                // And colour them just in case
                delegateModel.highlightItem(page.index, "green")
                delegateModel.highlightItem(selected, "red")
            }

            target: expertMode ? delegateModel : null
            onHighlightCorrect: updateHighlighted(selected)
            onHighlightAllWrong: updateHighlighted(selected)
        }
    }

    Timer {
        property int selectedIndex

        id: closeTimer
        interval: 1500
        onTriggered: {
            var correctAnswers = page.correctAnswers
            correctAnswers.push(selectedIndex === page.index)
            var times = page.times
            times.push(quizTimer.timeLimit - quizTimer.timeLeft)
            var selectedAnswers = page.selectedAnswers
            selectedAnswers.push(selectedIndex)
            if (current >= count) {
                pageStack.replace(Qt.resolvedUrl("ResultsPage.qml"), {
                    indices: page.indices,
                    correctAnswers: correctAnswers,
                    selectedAnswers: selectedAnswers,
                    times: times,
                    setup: page.setup
                })
                config.hasPlayed = true
            } else {
                pageStack.replace(Qt.resolvedUrl("QuizPage.qml"), {
                    indices: page.indices,
                    current: page.current + 1,
                    correctAnswers: correctAnswers,
                    selectedAnswers: selectedAnswers,
                    times: times,
                    setup: page.setup,
                })
            }
        }
    }

    Timer {
        id: inactiveTimer
        interval: 5000
        running: expertMode && choiceInput.text === ""
        onTriggered: {
            if (expertMode && !page.finished && choiceInput.text === "") {
                includedGroup.insert({
                    //% "Press to skip"
                    "name": qsTrId("countryquiz-la-press_to_skip"),
                    "index": -2,
                })
            }
        }
    }

    Component {
        id: flagComponent

        Image {
            source: "../../assets/flags/" + dataModel.get(index).iso + ".svg"
            sourceSize.height: maximumHeight
            sourceSize.width: maximumWidth
        }
    }

    Component {
        id: mapComponent

        Map {
            code: dataModel.get(index).iso
            invertedColors: palette.colorScheme === Theme.DarkOnLight
            model: ready ? mapModel : null
            overlayColor: Theme.rgba(Theme.highlightColor, Theme.opacityLow)
            sourceSize: {
                var size = Math.min(maximumWidth, maximumHeight)
                return Qt.size(size, size)
            }
        }
    }

    Component {
        id: capitalComponent

        Item {
            height: capitalsLabel.contentHeight + 2 * Theme.paddingLarge
            width: maximumWidth

            Label {
                id: capitalsLabel

                color: palette.highlightColor
                font.pixelSize: Theme.fontSizeLarge
                horizontalAlignment: Text.AlignHCenter
                text: {
                    var capitals = dataModel.get(index).capital.split(';')
                    switch (capitals.length) {
                    case 1:
                        return "%1".arg(capitals[0])
                    case 2:
                        //% "%1 and %2"
                        return qsTrId("countryquiz-la-one_and_other").arg(capitals[0]).arg(capitals[1])
                    case 3:
                        //% "%1, %2 and %3"
                        return qsTrId("countryquiz-la-three_args").arg(capitals[0]).arg(capitals[1]).arg(capitals[2])
                    }
                    console.warn("UNIMPLEMENTED: Bad number of capitals", capitals.length)
                    return ""
                }
                width: parent.width
                wrapMode: Text.Wrap
            }
        }
    }

    KeepAlive { enabled: true }

    Connections {
        target: quizTimer
        onTriggered: {
            timeLeft.state = "alerted"
            delegateModel.highlightAllWrong(-1)
            closeInSecond(-1)
        }
    }

    Component.onCompleted: {
        appWindow.progress = current
        var choices = Helpers.getIndexArray(dataModel)
        if (!expertMode) {
            choices.swap(0, index)
        }
        if (setup.sameRegion) {
            var region = dataModel.get(index).region
            choices = Helpers.filterIndexArray(dataModel, choices, function(item) {
                return item.region === region
            })
        }
        if (expertMode) {
            // Expert mode, all choices need to be written by the user
            choiceInput.list = choices
        } else {
            for (var i = 1; i < setup.choicesCount; ++i) {
                choices.swap(i, i + Math.floor(Math.random() * (choices.length - i)))
            }
            for (i = 0; i < setup.choicesCount; ++i) {
                delegateModel.items.addGroups(choices[i], 1, "included")
            }
            for (i = 0; i < includedGroup.count - 1; ++i) {
                includedGroup.move(i, i + Math.floor(Math.random() * (includedGroup.count - i)), 1)
            }
        }
    }
}