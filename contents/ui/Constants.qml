/*
 *   SPDX-FileCopyrightText: 2026 Yasuhiro Yamakawa <kawatab@gmail.com>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */
import QtQuick 2.0

// Container for application constants and enumerations
QtObject {
    // Operator enum for calculator operations
    // Added by Yasuhiro Yamakawa on 2026-05-14:
    // Replaces the old string-based operator handling with a type-safe enum,
    // improving code clarity and maintainability.
    enum Operator { 
        None,
        Add, 
        Subtract, 
        Multiply, 
        Divide 
    }

    enum RegisterRole {
        Operand,
        Result,
        Memory
    }
}