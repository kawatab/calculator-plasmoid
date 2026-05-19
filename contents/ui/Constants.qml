/*
 *   SPDX-FileCopyrightText: 2026 Yasuhiro Yamakawa <kawatab@gmail.com>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */
import QtQuick 2.15

// Container for application constants and enumerations.
QtObject {
    // Operator enum for calculator operations.
    enum Operator { 
        None,
        Add, 
        Subtract, 
        Multiply, 
        Divide 
    }

    // RegisterRole enum to identify the role of registers in calculations.
    enum RegisterRole {
        Operand,
        Result,
        Memory
    }
}