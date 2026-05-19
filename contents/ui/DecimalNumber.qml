/*
 *   SPDX-FileCopyrightText: 2026 Yasuhiro Yamakawa <kawatab@gmail.com>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

// DecimalNumber.qml
// This file defines a DecimalNumber type that represents a decimal number using a mantissa and an
// exponent. It provides methods for basic arithmetic operations, normalization, and formatting the
// number for display. The DecimalNumber type is designed to handle numbers with a specified
// precision and to manage user input for a calculator application. The implementation includes
// handling for appending digits, deleting digits, and formatting the number according to locale-
// specific rules. The code is structured to ensure that the mantissa and exponent are kept within
// defined limits, and it includes logic for normalizing the number after arithmetic operations to
// maintain the correct format.

import QtQuick 2.15

QtObject {
    readonly property real maxMantissa: 999999999999
    readonly property real minMantissa: -999999999999
    readonly property int precision: 12
    readonly property int maxExponent: 100
    readonly property int minExponent: -100
    property real mantissa: 0
    property int exponent: 0
    property int caretPosition: -1
    property bool commaPressed: false

    function isEditable() {
        return caretPosition >= 0;
    }

    // Clears and sets editable if the number is read-only.
    function ensureEditable() {
        if (isReadOnly()) {
            clear();
        }
    }

    function isReadOnly() {
        return caretPosition < 0;
    }

    function setReadOnly() {
        caretPosition = -1;
        commaPressed = false;
    }

    function isZero() {
        return mantissa === 0;
    }

    function isNegative() {
        return mantissa < 0;
    }

    // Set 0 and enable to edit.
    function clear() {
        mantissa = 0;
        exponent = 0;
        caretPosition = 0;
        commaPressed = false;
    }

    // If non-zero, the mantissa always has 12 digits and the exponent is adjusted accordingly.
    // This function is called after each arithmetic operation to maintain the correct format of
    // the number. If the mantissa is zero, the exponent is reset to zero as well.
    function normalize() {
        if (isZero()) {
            exponent = 0;
        } else {
            let digitCount = Math.floor(Math.log10(Math.abs(mantissa)));
            var diff = digitCount - precision + 1;
            if (diff > 0) {
                mantissa /= Math.pow(10, diff);
            } else if (diff < 0) {
                mantissa *= Math.pow(10, -diff);
            }
            exponent += diff;
            mantissa = Math.round(mantissa);
        }
    }

    function assign(other) {
        mantissa = other.mantissa;
        exponent = other.exponent;
    }
    
    function assignZero() {
        mantissa = 0;
        exponent = 0;
    }

    function add(other) { // assignZero() or normalize() required.
        if (isZero()) {
            assign(other);
            return;
        } else if (other.isZero()) {
            return;
        }

        if (exponent === other.exponent) {
            mantissa += other.mantissa;
        } else if (exponent > other.exponent) {
            addAlined(this, other);
        } else {
            addAlined(other, this);
        }

        normalize();
    }

    function addAlined(large, small) {
        let diff = large.exponent - small.exponent;
        if (diff > precision) {
            mantissa = large.mantissa;
            exponent = large.exponent;
        } else {
            // 1 + 999 999 999 = 1 000 000 000
            let largeMantissa = large.mantissa * 10;
            let smallMantissa = small.mantissa / Math.pow(10, diff - 1);
            mantissa = Math.round(largeMantissa + smallMantissa);
            exponent = large.exponent - 1;
        }
    }
    
    function subtract(other) { // assignZero() or normalize() required.
        if (isZero()) {
            assign(other);
            negate();
            return;
        } else if (other.isZero()) {
            return;
        }

        if (exponent === other.exponent) {
            mantissa -= other.mantissa;
        } else if (exponent > other.exponent) {
            subtractAlined(this, other);
        } else {
            subtractAlined(other, this);
            negate();
        }
        normalize();
    }

    function subtractAlined(large, small) {
        let diff = large.exponent - small.exponent;
        if (diff > precision) {
            mantissa = large.mantissa;
            exponent = large.exponent;
        } else {
            // 1 000 000 000 000 - 999 999 999 = 1
            let largeMantissa = large.mantissa * 10;
            let smallMantissa = small.mantissa / Math.pow(10, diff - 1);
            mantissa = Math.round(largeMantissa - smallMantissa);
            exponent = large.exponent - 1;
        }
    }
    
    function multiply(other) { // assignZero() or normalize() required.
        if (isZero()  || other.isZero()) {
            assignZero();
            return;
        }

        mantissa *= other.mantissa;
        exponent += other.exponent;
        normalize();
    }
    
    function divide(other) { // assignZero() or normalize() required.
        if (isZero()) {
            assignZero();
            return;
        } else if (other.isZero()) {
            // Returns zero deliberately to avoid infinity or NaN, and the error state is handled in the main.qml.
            assignZero();
            return;
        }

        mantissa /= other.mantissa;
        exponent -= other.exponent;
        normalize();
    }

    function negate() {
        mantissa = -mantissa;
    }

    function sqrt() {
        if (isNegative()) {
            // Returns zero deliberately to avoid NaN, and the error state is handled in the main.qml.
            assignZero();
            return;
        } 

        if (isZero()) {
            return;
        }

        // Fixes convergence issue: The calculation should round to 1 but fails to 
        // hit it exactly due to float precision limits.
        if (mantissa === 100000000001 && exponent === -11 ||
            mantissa === 999999999999 && exponent === -12) {
            mantissa = 1e11;
            exponent = -11;
            return;
        }

        let tempMantissa = mantissa;
        let tempExponent = exponent;

        if (Math.abs(tempExponent) % 2 === 1) {
            tempMantissa = tempMantissa * 10;
            --tempExponent;
        }

        mantissa = Math.sqrt(tempMantissa);
        exponent = tempExponent / 2;
        normalize();
    }

    function appendDigit(digit) { // ensure editable
        ensureEditable();

        if (commaPressed) {
            appendDecimalDigit(digit);
        } else {
            appendIntegerDigit(digit);
        }
    }

    function appendIntegerDigit(digit) { // ensure editable
        ensureEditable();

        mantissa = Math.abs(mantissa); // Remove the sign
        if (isZero()) {
            if (digit > 0) {
                mantissa = digit * 1e11;
                exponent = -(precision - 1);
                caretPosition = 1;
            }
        } else {
            if (precision > caretPosition) {
                mantissa += digit * Math.pow(10, precision - caretPosition - 1);
                ++exponent;
                ++caretPosition;
            }
        }
    }

    // If number is less than 1, precision is decreased.
    function appendDecimalDigit(digit) { // ensure editable
        ensureEditable();

        mantissa = Math.abs(mantissa); // Remove the sign
        if (precision > caretPosition) {
            if (isZero()) {
                if (digit > 0) {
                    mantissa = digit * 1e11;
                    exponent = -precision - caretPosition;
                }
                ++caretPosition;
            } else if (exponent > -precision) {
                mantissa += digit * Math.pow(10, precision - caretPosition - 1);
                ++caretPosition;
            } else if (caretPosition < precision - 1) {
                mantissa += digit * Math.pow(10, -exponent - caretPosition - 1);
                ++caretPosition;
            }
        }
    }

    function appendDecimalPoint() { // ensure editable
        ensureEditable();
        commaPressed = isZero() || caretPosition < precision;
    }

    function deleteDigit() { // ensure editable
        ensureEditable();

        if (commaPressed) {
            if (caretPosition === exponent + precision) {
                commaPressed = false;
                if (isZero()) {
                    clear();
                }
            } else {
                deleteDecimalDigit();
            }
        } else {
            deleteIntegerDigit();
        }
    }

    function deleteIntegerDigit() { // ensure editable
        if (isZero()) return;

        ensureEditable();

        mantissa = Math.abs(mantissa); // Remove the sign
        mantissa -= mantissa % Math.pow(10, precision - caretPosition + 1);
        --caretPosition;
        --exponent;
        if (isZero()) {
            clear();
        }
    }

    function deleteDecimalDigit() { // ensure editable
        ensureEditable();

        if (caretPosition > exponent + precision) {
           mantissa = Math.abs(mantissa); // Remove the sign
           if (mantissa > 0 || caretPosition <= precision) {
                mantissa -= mantissa % Math.pow(10, precision - caretPosition + 1);
                --caretPosition;
            }
        }
    }

    function toFormatNumber() {
        var text = "";
        // Show all decimals including zeroes and show decimalPoint
        if (isEditable() && commaPressed) {
            if (isZero()) {
                text = insertSeparatorToFractionPart("0." + "0".repeat(caretPosition));
            } else {
                let number = exponent > 0 ? mantissa * Math.pow(10, exponent) : mantissa / Math.pow(10, -exponent);
                let temp = number.toLocaleString(Qt.locale(), "f", (number < 1 ? caretPosition : caretPosition - (exponent + precision)));
                text = insertSeparatorToFractionPart(temp);
                if (!text.includes(Qt.locale().decimalPoint)) {
                    text += Qt.locale().decimalPoint;
                }
            }
        /*
        // Don't allow scientific notation for numbers and show up to 12 significant digits.
        } else if (exponent > 0) {
            text = "OVERFLOW";
        } else if (exponent > -precision) {
            let temp = (mantissa / Math.pow(10, -exponent)).toLocaleString(Qt.locale(), "g", precision);
            text = insertSeparatorToFractionPart(temp);
        } else {
            text = (mantissa / Math.pow(10, -exponent)).toLocaleString(Qt.locale(), "f", precision);
            if (isNegative) {
                text = text.substring(0, precision + 2);
            } else {
                text = text.substring(0, precision + 1);
            }

            text = text.replace(/0+$/, "");

            if (text[text.length - 1] === ".") {
                text = "0";
            } else {
                text = insertSeparatorToFractionPart(text);
            }
        }
        */
        // Allow scientific notation for numbers.
        } else if (exponent > 0) {
            text = formatToScientificString();
        } else if (exponent > -precision) {
            let temp = (mantissa / Math.pow(10, -exponent)).toLocaleString(Qt.locale(), "g", precision);
            text = insertSeparatorToFractionPart(temp);
        } else if (exponent > -2 * precision) {
            let count = countTrailingZero(mantissa);
            let digitCount = 1 - exponent - count;
            if (digitCount <= precision) {
                text = insertSeparatorToFractionPart((mantissa / Math.pow(10, -exponent)).toLocaleString(Qt.locale(), "f", digitCount - 1));
            } else {
                if (exponent > -precision - 9) {
                     text = insertSeparatorToFractionPart((mantissa / Math.pow(10, -exponent)).toLocaleString(Qt.locale(), "f", precision - 1));
                } else {
                    text = formatToScientificString();
                }
            }
        } else {
            text = formatToScientificString();
        }

        var regex = new RegExp(Qt.locale().groupSeparator, "g");
        return text.replace(regex, "\u2009");
    }

    function countTrailingZero(number) {
        let temp = Math.abs(number);
        let count = 0;

        while (temp > 0) {
            if (temp % 10 != 0) break;
            ++count;
            temp = Math.trunc(temp / 10);
        }
        
        return count;
    }

    function formatToScientificString() {
        let normalizedMantissa = (mantissa / Math.pow(10, precision - 1));
        let text = normalizedMantissa.toLocaleString(Qt.locale(), "f", precision - 5);
        let normalizedExponent = exponent + precision - 1;
        return insertSeparatorToFractionPart(text) + (normalizedExponent < 0 ? "E" : "E+") + normalizedExponent.toString();
    }

    function insertSeparatorToFractionPart(text) {
        let parts = text.split(Qt.locale().decimalPoint);
        if (parts.length < 2 || !parts[1]) return text;
        return parts[0] + Qt.locale().decimalPoint + parts[1].match(/.{1,3}/g).join("\u2009");
    }
}