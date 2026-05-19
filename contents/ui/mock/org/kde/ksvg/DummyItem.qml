/*
 *   SPDX-FileCopyrightText: 2026 Yasuhiro Yamakawa <kawatab@gmail.com>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

// This is a dummy QML item used for testing purposes. It simulates the interface of a real KSVG item
// without implementing any actual functionality. This allows us to test the main application logic in isolation.

import QtQuick 2.15

Item {
    id: mockRoot
    
    width: 320
    height: 480
    implicitWidth: 320
    implicitHeight: 480
    
    property string imagePath: ""
    property string prefix: ""
    
    property QtObject margins: QtObject {
        property int left: 0
        property int right: 0
        property int top: 0
        property int bottom: 0
    }
    
    // Create an internal transparent item that automatically forces 
    // nested children to look like they are filling the parent cleanly.
    Item {
        anchors.fill: parent
        data: mockRoot.dummyChildren
    }

    default property list<Item> dummyChildren
}