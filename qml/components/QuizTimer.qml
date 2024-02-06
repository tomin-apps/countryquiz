/*
 * Copyright (c) 2023 Tomi Leppänen
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.6

Item {
    property alias tick: tickTimer
    property alias limit: limitTimer
    property alias timeLimit: limitTimer.interval
    readonly property int total: _total

    property var _lastStarted
    property int _total

    function _digits(value) {
        return (Math.floor(value / 10)).toString() + (value % 10).toString()
    }

    function timeAsString(time) {
        if (time < 0)
            time = 0
        var tenths = Math.floor(time / 100) % 10
        var seconds = Math.floor(time / 1000) % 60
        var minutes = Math.floor(time / 60000) % 60
        var hours = Math.floor(time / 3600000)
        return (hours === 0 ? minutes.toString()
                            : (hours.toString() + ":" + _digits(minutes.toString())))
                + ":" + _digits(seconds.toString()) + "." + tenths.toString()
    }

    function getTimeLeft() {
        return limitTimer.interval - (Date.now() - _lastStarted)
    }

    function getTotalTimeText() {
        return timeAsString(total)
    }

    function reset() {
        limitTimer.running = false
        _total = 0
        _lastStarted = 0
    }

    function start() {
        limitTimer.start()
    }

    function stop() {
        limitTimer.stop()
    }

    Timer {
        id: tickTimer
        interval: 100
        repeat: true
        running: limitTimer.running
    }

    Timer {
        id: limitTimer
        onRunningChanged: {
            var time = Date.now()
            if (running) {
                _lastStarted = time
            } else {
                var elapsed = time - _lastStarted
                _total += elapsed < interval ? elapsed : interval
            }
        }
    }
}