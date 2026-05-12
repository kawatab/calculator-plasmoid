/*
 *   SPDX-FileCopyrightText: 2026 Yasuhiro Yamakawa <kawatab@gmail.com>
 *   SPDX-FileCopyrightText: 2015 Bernhard Friedreich <friesoft@gmail.com>
 *   SPDX-FileCopyrightText: 2014 Martin Yrjölä <martin.yrjola@gmail.com>
 *   SPDX-FileCopyrightText: 2012, 2014 Davide Bettio <davide.bettio@kdemail.net>
 *   SPDX-FileCopyrightText: 2012, 2014 David Edmundson <davidedmundson@kde.org>
 *   SPDX-FileCopyrightText: 2012 Luiz Romário Santana Rios <luizromario@gmail.com>
 *   SPDX-FileCopyrightText: 2007 Henry Stanaland <stanaland@gmail.com>
 *   SPDX-FileCopyrightText: 2008 Laurent Montel <montel@kde.org>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 *
 *   Based on the source code from the Debian package (plasma-widgets-addons).
 *   Fork maintenance by Yasuhiro Yamakawa:
 *   - Ported to Plasma 6 / Qt6 (Fixed implicit 'event' parameter warnings).
 *   - Improved hardware compatibility for Dell KB740 (F9 key mapping).
 */

import QtQuick 2.5
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5 as QQC2
import org.kde.kirigami 2.20 as Kirigami
import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: main;

    switchWidth: Kirigami.Units.gridUnit * 7
    switchHeight: Math.round(Kirigami.Units.gridUnit * 10.5)

    // Make the buttons' text labels scale with the widget's size
    // This is propagated down to all child controls with text

    property real result: 0;
    property bool hasResult: false;
    property bool showingInput: true;
    property bool showingResult: false;
    property string operator
    property real operand: 0;
    property bool commaPressed: false;
    property int decimals: 0;
    property int inputSize: 0;
    property TextEdit display

    readonly property int maxInputLength: 18; // More than that and the number notation
                                              // turns scientific (i.e.: 1.32324e+12).
                                              // When calculating 1/3 the answer is
                                              // 18 characters long.

    // Modified by Yasuhiro Yamakawa on 2026-05-12
    // Support sign inversion (Casio style):
    // Inverts the current result if no input has started, or inverts the current operand being typed.
    function digitClicked(digit) {
        if (showingResult) {
            allClearClicked();
        }

        if (commaPressed) {
            ++decimals;
            var tenToTheDecimals = Math.pow(10, decimals);
            operand = Math.abs(operand); // Remove the sign
            operand = (operand * tenToTheDecimals + digit) / tenToTheDecimals;
        } else {
            operand = Math.abs(operand); // Remove the sign
            operand = operand * 10 + digit;
        }
        showingInput = true;
        displayNumber(operand);
        ++inputSize;
    }

    // Modified by Yasuhiro Yamakawa on 2026-05-12
    // Support sign inversion (Casio style):
    // Inverts the current result if no input has started, or inverts the current operand being typed.
    function deleteDigit() {
        if (showingResult) {
            allClearClicked();
        }

        if (showingInput) {
            if (commaPressed) {
                if (decimals === 0) {
                    commaPressed = false;
                } else if (decimals > 0) {
                    operand = Math.abs(operand); // Remove the sign
                    operand -= operand % Math.pow(10, 1 - decimals);
                    --decimals;
                    --inputSize;
                }
            } else if (inputSize > 0) {
                operand = Math.abs(operand); // Remove the sign
                operand = (operand - (operand % 10)) / 10;
                --inputSize;
            }
        }
        displayNumber(operand);
    }

    function decimalClicked() {
        if (showingResult) {
            allClearClicked();
        }

        commaPressed = true;
        showingInput = true;
        displayNumber(operand);
    }

    function doOperation() {
        switch (operator) {
        case "+":
            result += operand;
            break;
        case "-":
            result -= operand;
            break;
        case "*":
            result *= operand;
            break;
        case "/":
            if (operand === 0) {
                divisionByZero();
                return;
            }
            result /= operand;
            break;
        default:
            return;
        }

        showingInput = false;
        displayNumber(result);
    }

    function clearOperand() {
        operand = 0;
        commaPressed = false;
        decimals = 0;
        inputSize = 0;
    }

    function setOperator(op) {
        if (!hasResult) {
            result = operand;
            hasResult = true;
        } else if (showingInput) {
            doOperation();
        }

        clearOperand();
        operator = op;
        showingResult = false;
    }

    // Added by Yasuhiro Yamakawa on 2026-05-12
    // Support sign inversion
    function negate() {
        if (showingInput && operand !== 0) {
            operand = -operand;
            displayNumber(operand);
        } else if (hasResult) {
            result = -result;
            displayNumber(result);
        }
    }

    function equalsClicked() {
        showingResult = true;
        doOperation();
    }

    function clearClicked() {
        clearOperand();
        operator = "";
        displayNumber(operand);
        showingInput = true;
        showingResult = false;
    }

    function allClearClicked() {
        clearClicked();
        result = 0;
        hasResult = false;
    }

    function algarismCount(number) {
        return number == 0? 1 :
                            Math.floor(Math.log(Math.abs(number))/Math.log(10)) + 1;
    }

    function copyToClipboard() {
        display.selectAll();
        display.copy();
        display.deselect();
    }

    function pasteFromClipboard() {
        dummyTextEditForPasting.paste()
        var content = dummyTextEditForPasting.text
        dummyTextEditForPasting.clear()
        if (content != "") {
            content = content.trim();
        }

        // check if the clipboard content as a whole is a valid number (without sign, no operators, ...)
        if (isValidClipboardInput(content)) {
            var digitRegex = new RegExp('^[0-9]$');
            var decimalRegex = new RegExp('^[\.,]$');

            for (var i = 0; i < content.length; i++) {
                if (digitRegex.test(content[i])) {
                    digitClicked(parseInt(content[i]));
                } else if (decimalRegex.test(content[i])) {
                    decimalClicked();
                }
            }
        }
    }

    function isValidClipboardInput(input) {
        return new RegExp('^[0-9]*[\.,]?[0-9]+$').test(input);
    }

    function displayNumber(number) {
        var text = number.toLocaleString(Qt.locale(), "g", 14);

        // Show all decimals including zeroes and show decimalPoint
        if (showingInput && commaPressed) {
            text = number.toLocaleString(Qt.locale(), "f", decimals);
            if (decimals === 0) {
                text += Qt.locale().decimalPoint;
            }
        }
        display.text = text;

        var decimalsToShow = 9;
        // Decrease precision until the text fits to the display.
        while (display.contentWidth > display.width && decimalsToShow > 0) {
            display.text = number.toLocaleString(Qt.locale(), "g", decimalsToShow--);
        }
    }

    function divisionByZero() {
        showingInput = false;
        showingResult = true;
        display.text = i18nc("Abbreviation for result (undefined) of division by zero, max. six to nine characters.", "undef");
    }

    TextEdit {
        id: dummyTextEditForPasting
        visible: false
        height: 0
        activeFocusOnTab: false
    }

    // Added by Yasuhiro Yamakawa on 2026-05-12
    // Custom button component to ensure consistent styling and behavior across all calculator buttons.
    component CalcButton : PlasmaComponents.Button {
        Layout.fillWidth: true
        Layout.fillHeight: true
    
        // Override the contentItem once here
        contentItem: QQC2.Label {
            text: parent.text
            font: parent.font
            color: Kirigami.Theme.textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    fullRepresentation: QQC2.Control {
        // Make the buttons' text labels scale with the widget's size
        // This is propagated down to all child controls with text
        font.pixelSize: Math.round(width/12)
        padding: 0
        Layout.minimumWidth: main.switchWidth
        Layout.minimumHeight: main.switchHeight
        Layout.preferredWidth: main.switchWidth * 2
        Layout.preferredHeight: main.switchHeight * 2

        contentItem: ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 4

            focus: true;
            spacing: 4;

            // Modified by Yasuhiro Yamakawa on 2026-05-12 for Qt6 compatibility:
            // Updated all key event handlers (digits and operators) to explicit signal handler syntax.
            Keys.onDigit0Pressed: (event) => {
                digitClicked(0); zeroButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDigit1Pressed: (event) => {
                digitClicked(1); oneButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDigit2Pressed: (event) => {
                digitClicked(2); twoButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDigit3Pressed: (event) => {
                digitClicked(3); threeButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDigit4Pressed: (event) => {
                digitClicked(4); fourButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDigit5Pressed: (event) => {
                digitClicked(5); fiveButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDigit6Pressed: (event) => {
                digitClicked(6); sixButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDigit7Pressed: (event) => {
                digitClicked(7); sevenButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDigit8Pressed: (event) => {
                digitClicked(8); eightButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDigit9Pressed: (event) => {
                digitClicked(9); nineButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onEscapePressed: (event) => {
                allClearClicked(); allClearButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDeletePressed: (event) => {
                clearClicked(); clearButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onPressed: (event) => {
                switch (event.key) {
                case Qt.Key_Plus:
                    setOperator("+");
                    plusButton.forceActiveFocus(Qt.TabFocusReason);
                    break;
                case Qt.Key_Minus:
                    setOperator("-");
                    minusButton.forceActiveFocus(Qt.TabFocusReason);
                    break;
                case Qt.Key_Asterisk:
                    setOperator("*");
                    multiplyButton.forceActiveFocus(Qt.TabFocusReason);
                    break;
                case Qt.Key_Slash:
                    setOperator("/");
                    divideButton.forceActiveFocus(Qt.TabFocusReason);
                    break;
                case Qt.Key_Comma:
                case Qt.Key_Period:
                    decimalClicked();
                    decimalButton.forceActiveFocus(Qt.TabFocusReason);
                    break;
                case Qt.Key_Equal:
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    equalsClicked();
                    break;
                case Qt.Key_Backspace:
                    deleteDigit();
                    display.forceActiveFocus(Qt.TabFocusReason);
                    break;
                // Added by Yasuhiro Yamakawa on 2026-05-12
                // Handles the +/- key found on keyboards like the Dell KB740 (maps to F9).
                case Qt.Key_F9:
                    negate();
                    negateButton.forceActiveFocus(Qt.TabFocusReason);
                    break;
                default:
                    if (event.matches(StandardKey.Copy)) {
                        copyToClipboard();
                        break;
                    } else if (event.matches(StandardKey.Paste)) {
                        pasteFromClipboard();
                        break;
                    }
                    // Modified by Yasuhiro Yamakawa on 2026-05-12 for Qt6 compatibility:
                    // Fall through: set accepted to false and exit to skip the final accepted = true
                    event.accepted = false;
                    return;
                }
                // Modified by Yasuhiro Yamakawa on 2026-05-12 for Qt6 compatibility:
                // Finalize the event if it was caught by one of the cases above
                event.accepted = true;
            }
            // Modified by Yasuhiro Yamakawa on 2026-05-12
            // Don't show highlight on buttons after release keys.
            Keys.onReleased: (event) => {
                display.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }

            KSvg.FrameSvgItem {
                id: displayFrame;
                Layout.fillWidth: true
                Layout.minimumHeight: 2 * display.font.pixelSize;
                imagePath: "widgets/frame";
                prefix: "plain";

                TextEdit {
                    id: display;
                    anchors {
                        fill: parent;
                        margins: parent.margins.right;
                    }
                    text: "0";
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 2;
                    font.weight: Font.Bold;
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                    color: Kirigami.Theme.textColor
                    horizontalAlignment: TextEdit.AlignRight;
                    verticalAlignment: TextEdit.AlignVCenter;
                    readOnly: true;

                    focus: main.expanded

                    Accessible.name: text
                    Accessible.description: i18nc("@label calculation result", "Result")

                    Binding {
                        target: main
                        property: "display"
                        value: display
                    }
                }

                KeyNavigation.up: zeroButton
                KeyNavigation.down: allClearButton
            }

            // Modified by Yasuhiro Yamakawa on 2026-05-12
            // Arranged the buttons to match the standard calculator layout and added the new negate button.
            GridLayout {
                id: buttonsGrid;
                columns: 4;
                rows: 5;
                columnSpacing: 4
                rowSpacing: 4

                Layout.fillWidth: true
                Layout.fillHeight: true

                CalcButton {
                    id: allClearButton

                    KeyNavigation.up: display
                    KeyNavigation.down: sevenButton
                    KeyNavigation.left: divideButton
                    KeyNavigation.right: clearButton

                    text: i18nc("Text of the all clear button", "AC");
                    onClicked: allClearClicked();
                }

                CalcButton {
                    id: clearButton

                    KeyNavigation.up: display
                    KeyNavigation.down: eightButton
                    KeyNavigation.left: allClearButton
                    KeyNavigation.right: negateButton

                    text: i18nc("Text of the clear button", "C");
                    onClicked: clearClicked();
                }

                // Added by Yasuhiro Yamakawa on 2026-05-12
                // New button for sign inversion (negate).
                CalcButton {
                    id: negateButton

                    KeyNavigation.up: display
                    KeyNavigation.down: nineButton
                    KeyNavigation.left: clearButton
                    KeyNavigation.right: divideButton

                    text: i18nc("Text of the negate button", "+/−");
                    onClicked: negate();
                }

                CalcButton {
                    id: divideButton

                    KeyNavigation.up: display
                    KeyNavigation.down: multiplyButton
                    KeyNavigation.left: negateButton
                    KeyNavigation.right: allClearButton

                    text: i18nc("Text of the division button", "÷");
                    onClicked: setOperator("/");
                }


                CalcButton {
                    id: sevenButton

                    KeyNavigation.up: allClearButton
                    KeyNavigation.down: fourButton
                    KeyNavigation.left: multiplyButton
                    KeyNavigation.right: eightButton

                    text: "\u20027\u2002";
                    onClicked: digitClicked(7);
                }

                CalcButton {
                    id: eightButton

                    KeyNavigation.up: clearButton
                    KeyNavigation.down: fiveButton
                    KeyNavigation.left: sevenButton
                    KeyNavigation.right: nineButton

                    text: "\u20028\u2002";
                    onClicked: digitClicked(8);
                }

                CalcButton {
                    id: nineButton

                    KeyNavigation.up: negateButton
                    KeyNavigation.down: sixButton
                    KeyNavigation.left: eightButton
                    KeyNavigation.right: multiplyButton

                    text: "\u20029\u2002";
                    onClicked: digitClicked(9);
                }

                CalcButton {
                    id: multiplyButton

                    KeyNavigation.up: divideButton
                    KeyNavigation.down: minusButton
                    KeyNavigation.left: nineButton
                    KeyNavigation.right: sevenButton

                    text: i18nc("Text of the multiplication button", "\u2002×\u2002");
                    onClicked: setOperator("*");
                }


                CalcButton {
                    id: fourButton

                    KeyNavigation.up: sevenButton
                    KeyNavigation.down: oneButton
                    KeyNavigation.left: minusButton
                    KeyNavigation.right: fiveButton

                    text: "\u20024\u2002";
                    onClicked: digitClicked(4);
                }

                CalcButton {
                    id: fiveButton

                    KeyNavigation.up: eightButton
                    KeyNavigation.down: twoButton
                    KeyNavigation.left: fourButton
                    KeyNavigation.right: sixButton

                    text: "\u20025\u2002";
                    onClicked: digitClicked(5);
                }

                CalcButton {
                    id: sixButton

                    KeyNavigation.up: nineButton
                    KeyNavigation.down: threeButton
                    KeyNavigation.left: fiveButton
                    KeyNavigation.right: minusButton

                    text: "\u20026\u2002";
                    onClicked: digitClicked(6);
                }

                CalcButton {
                    id: minusButton

                    KeyNavigation.up: multiplyButton
                    KeyNavigation.down: plusButton
                    KeyNavigation.left: sixButton
                    KeyNavigation.right: fourButton

                    text: i18nc("Text of the minus button", "−");
                    onClicked: setOperator("-");
                }


                CalcButton {
                    id: oneButton

                    KeyNavigation.up: fourButton
                    KeyNavigation.down: zeroButton
                    KeyNavigation.left: plusButton
                    KeyNavigation.right: twoButton

                    text: "\u20021\u2002";
                    onClicked: digitClicked(1);
                }

                CalcButton {
                    id: twoButton

                    KeyNavigation.up: fiveButton
                    KeyNavigation.down: decimalButton
                    KeyNavigation.left: oneButton
                    KeyNavigation.right: threeButton

                    text: "\u20022\u2002";
                    onClicked: digitClicked(2);
                }

                CalcButton {
                    id: threeButton

                    KeyNavigation.up: sixButton
                    KeyNavigation.down: ansButton
                    KeyNavigation.left: twoButton
                    KeyNavigation.right: plusButton

                    text: "\u20023\u2002";
                    onClicked: digitClicked(3);
                }

                CalcButton {
                    id: plusButton

                    KeyNavigation.up: minusButton
                    KeyNavigation.down: display
                    KeyNavigation.left: threeButton
                    KeyNavigation.right: oneButton

                    Layout.rowSpan: 2
                    text: i18nc("Text of the plus button", "+");
                    onClicked: setOperator("+");
                }

                CalcButton {
                    id: zeroButton

                    KeyNavigation.up: oneButton
                    KeyNavigation.down: display
                    KeyNavigation.left: plusButton
                    KeyNavigation.right: decimalButton


                    text: "\u20020\u2002";
                    onClicked: digitClicked(0);
                }

                CalcButton {
                    id: decimalButton

                    KeyNavigation.up: twoButton
                    KeyNavigation.down: display
                    KeyNavigation.left: zeroButton
                    KeyNavigation.right: ansButton

                    text: Qt.locale().decimalPoint;
                    onClicked: decimalClicked();
                }

                CalcButton {
                    id: ansButton

                    KeyNavigation.up: threeButton
                    KeyNavigation.down: display
                    KeyNavigation.left: decimalButton
                    KeyNavigation.right: plusButton
                    
                    text: i18nc("Text of the equals button", "=");
                    onClicked: equalsClicked();
                }
            }
        }
    }
}
