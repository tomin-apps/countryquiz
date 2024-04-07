/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6
import "../helpers.js" as Helpers

Item {
    id: timer

    property alias tick: tickTimer
    property alias running: tickTimer.running
    property int timeLimit
    readonly property int timeLeft: _timeLeft
    readonly property int total: _total

    property var _lastStarted
    property int _timeLeft: timeLimit
    property int _total

    signal triggered()

    function getTotalTimeText() {
        return Helpers.timeAsString(total)
    }

    function reset() {
        tickTimer.running = false
        _total = 0
        _lastStarted = 0
        _timeLeft = timeLimit
    }

    function start() {
        _timeLeft = timeLimit
        tickTimer.start()
    }

    function stop() {
        tickTimer.stop()
    }

    Timer {
        id: tickTimer
        interval: 100
        repeat: true

        onRunningChanged: {
            var time = Date.now()
            if (running) {
                _lastStarted = time
            } else {
                var elapsed = time - _lastStarted
                _total += elapsed < timeLimit ? elapsed : timeLimit
            }
        }

        onTriggered: {
            _timeLeft = timeLimit - (Date.now() - _lastStarted)
            if (_timeLeft <= 0) {
                running = false
                timer.triggered()
            }
        }
    }
}