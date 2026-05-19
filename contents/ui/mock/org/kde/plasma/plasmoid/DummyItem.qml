/*
 *   SPDX-FileCopyrightText: 2026 Yasuhiro Yamakawa <kawatab@gmail.com>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

// This is a dummy QML item used for testing purposes. It simulates the interface of a real plasmoid item
// without implementing any actual functionality. This allows us to test the main application logic in isolation.

import QtQuick 2.15

Item {
    id: dummyRoot

    property Item fullRepresentation: null
    property Item compactRepresentation: null
    property int switchHeight: 0
    property int switchWidth: 0

    property var configuration: {
        return new Proxy({}, {
            get: function(target, prop) { return ""; },
            set: function(target, prop, value) { return true; }
        });
    }

    default property list<Item> dummyChildren
}
