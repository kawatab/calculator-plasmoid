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
    property int caretPosition: 0
    property bool commaPressed: false

    function isZero() {
        return mantissa === 0;
    }

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
        if (mantissa === 0) {
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
        return;
    }

    function assign(other) {
        mantissa = other.mantissa;
        exponent = other.exponent;
        caretPosition = 0;
        commaPressed = false;
    }
    
    function add(other) {
        if (isZero()) {
            assign(other);
            return;
        } else if (other.isZero()) {
            return;
        }

        if (exponent === other.exponent) {
            mantissa += other.mantissa;
        } else if (exponent > other.exponent) {
            add_helper(this, other);
        } else {
            add_helper(other, this);
        }
        normalize();
    }

    function add_helper(large, small) {
        var tempMantissa = small.mantissa / Math.pow(10, large.exponent - small.exponent);
        tempMantissa = Math.round(large.mantissa + tempMantissa);
        mantissa = tempMantissa;
        exponent = large.exponent;
    }
    
    function subtract(other) {
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
            subtract_helper(this, other);
        } else {
            subtract_helper(other, this);
        }
        normalize();
    }

    function subtract_helper(large, small) {
        var tempMantissa = small.mantissa / Math.pow(10, large.exponent - small.exponent);
        tempMantissa = Math.round(large.mantissa - tempMantissa);
        mantissa = tempMantissa;
        exponent = large.exponent;
    }
    
    function multiply(other) {
        if (isZero()  || other.isZero()) {
            clear();
            return;
        }

        mantissa *= other.mantissa;
        exponent += other.exponent;
        normalize();
    }
    
    function divide(other) {
        if (isZero()) {
            clear();
            return;
        } else if (other.isZero()) {
            clear();
            // TODO: Divide by zero error handling
            return;
        }

        mantissa /= other.mantissa;
        exponent -= other.exponent;
        normalize();
    }

    function negate() {
        mantissa = -mantissa;
    }

    function appendDigit(digit) {
        if (commaPressed) {
            appendDecimalDigit(digit);
        } else {
            appendIntegerDigit(digit);
        }
    }

    function appendIntegerDigit(digit) {
        mantissa = Math.abs(mantissa); // Remove the sign
        if (mantissa === 0) {
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
    function appendDecimalDigit(digit) {
        mantissa = Math.abs(mantissa); // Remove the sign
        if (precision > caretPosition) {
            if (mantissa === 0) {
                if (digit > 0) {
                    mantissa = digit * 1e11;
                    exponent = -precision - caretPosition;
                }
                ++caretPosition;
            } else if (exponent > - precision) {
                mantissa += digit * Math.pow(10, precision - caretPosition - 1);
                ++caretPosition;
            } else if (precision > caretPosition + 1) {
                mantissa += digit * Math.pow(10, -exponent - caretPosition - 1);
                ++caretPosition;
            }
        }
    }

    function appendDecimalPoint() {
        commaPressed = mantissa === 0 || caretPosition < precision;
    }

    function deleteDigit() {
        if (commaPressed) {
            if (caretPosition === exponent + precision) {
                commaPressed = false;
                if (mantissa === 0) {
                    clear();
                }
            } else {
                deleteDecimalDigit();
            }
        } else {
            deleteIntegerDigit();
        }
    }

    function deleteIntegerDigit() {
        mantissa = Math.abs(mantissa); // Remove the sign
        if (mantissa > 0) {
            if (caretPosition >= 0) {
                --caretPosition;
                mantissa -= mantissa % Math.pow(10, precision - caretPosition);
                --exponent;
                if (mantissa === 0) {
                    clear();
                }
            }
        }
    }

    function deleteDecimalDigit() {
        if (caretPosition > exponent + precision && caretPosition >= 0) {
           mantissa = Math.abs(mantissa); // Remove the sign
           if (mantissa > 0 || caretPosition <= precision) {
                --caretPosition;
                mantissa -= mantissa % Math.pow(10, precision - caretPosition);
            }
        }
    }

    function toFormatNumber(showingInput) {
        console.log("num: " + (mantissa * Math.pow(10, exponent)) + ", man: " + mantissa + ", exp: " + exponent + ", caret: " + caretPosition);
        var text = "";
        // Show all decimals including zeroes and show decimalPoint
        if (showingInput && commaPressed) {
            if (mantissa === 0) {
                text = insertSeparatorToFractionPart("0." + "0".repeat(caretPosition));
            } else {
                let number = exponent > 0 ? mantissa * Math.pow(10, exponent) : mantissa / Math.pow(10, -exponent);
                let temp = number.toLocaleString(Qt.locale(), "f", (number < 1 ? caretPosition : caretPosition - (exponent + precision)));
                text = insertSeparatorToFractionPart(temp);
                if (!text.includes(Qt.locale().decimalPoint)) {
                    text += Qt.locale().decimalPoint;
                }
            }
        } else if (exponent > 0) {
            text = formatToScientificString();
        } else if (exponent > -precision) {
            let temp = (mantissa / Math.pow(10, -exponent)).toLocaleString(Qt.locale(), "g", precision);
            text = insertSeparatorToFractionPart(temp);
        } else if (exponent > -2 * precision) {
            let count = countTrailingZero(mantissa);
            let digitCount = 1 - exponent - count;
            if (digitCount <= precision) {
                text = insertSeparatorToFractionPart((mantissa / Math.pow(10, -exponent)).toLocaleString(Qt.locale(), "g", precision));
            } else {
                text = formatToScientificString();
            }
        } else {
            text = formatToScientificString();
        }

        console.log("number=" + text);
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
        let text = normalizedMantissa.toLocaleString(Qt.locale(), "g", precision);
        let normalizedExponent = (exponent + precision - 1);
        return insertSeparatorToFractionPart(text) + (normalizedExponent < 0 ? "E" : "E+") + normalizedExponent.toString();
    }

    function insertSeparatorToFractionPart(text) {
        let parts = text.split(Qt.locale().decimalPoint);
        if (parts.length < 2 || !parts[1]) return text;
        return parts[0] + Qt.locale().decimalPoint + parts[1].match(/.{1,3}/g).join("\u2009");
    }
}