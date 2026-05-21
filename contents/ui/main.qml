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
 *   - Added support for sign inversion (negate) and clear entry (CE) functionality.
 *   - Updated button layout to match standard calculator design.
 *   - Improved code readability and maintainability with an enum for operators.
 *   - Migrated from native JavaScript numbers to the DecimalNumber class.
 *   - Added support for calculator memory functions (M+, M-, MRC).
 *   - Added support for root operation.
 *   - Emulated Casio-style behavior.
 *   - Added support for constant calculation mode (K mode).
 *   - Modified error handling to display an error state instead of showing "Error" in the display.
 *   - Added support for percentage calculations with context-sensitive behavior.
 */
// pragma ComponentBehavior: Bound;

import QtQuick 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5 as QQC2
import org.kde.kirigami 2.20 as Kirigami
import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0

PlasmoidItem {
    id: main

    switchWidth: Kirigami.Units.gridUnit * 7
    switchHeight: Math.round(Kirigami.Units.gridUnit * 6)

    property DecimalNumber result: DecimalNumber {}
    property DecimalNumber operand: DecimalNumber {}
    property DecimalNumber memory: DecimalNumber {}
    property DecimalNumber buffer: DecimalNumber {}
    property int displayValue: Constants.RegisterRole.Operand
    property int operator: Constants.Operator.None
    property bool hasMemory: false
    property bool isKCalculationMode: false
    property bool isPercentageMode: false
    property bool isErrorState: false
    property TextEdit display

    function isDisplayedNumberEditable() {
        return displayValue === Constants.RegisterRole.Operand;
    }

    function isDisplayedNumberReadOnly() {
        return displayValue !== Constants.RegisterRole.Operand;
    }

    function isOperandDisplayed() {
        return displayValue !== Constants.RegisterRole.Result;
    }

    function isResultDisplayed() {
        return displayValue === Constants.RegisterRole.Result;
    }

    function isMemoryDisplayed() {
        return displayValue === Constants.RegisterRole.Memory
    }

    function hasOperator() {
        return operator !== Constants.Operator.None;
    }

    function hasNoOperator() {
        return operator === Constants.Operator.None;
    }

    function isOperatorIndicatorAdditionVisible() {
        return !isErrorState && operator === Constants.Operator.Add && (isOperandDisplayed() || (isResultDisplayed() && !isKCalculationMode));
    }

    function isOperatorIndicatorSubtractionVisible() {
        return !isErrorState && operator === Constants.Operator.Subtract && (isOperandDisplayed() || (isResultDisplayed() && !isKCalculationMode));
    }

    function isOperatorIndicatorMultiplicationVisible() {
        return !isErrorState && operator === Constants.Operator.Multiply && (isOperandDisplayed() || (isResultDisplayed() && !isKCalculationMode));
    }

    function isOperatorIndicatorDivisionVisible() {
        return !isErrorState && operator === Constants.Operator.Divide && (isOperandDisplayed() || (isResultDisplayed() && !isKCalculationMode));
    }

    function isOperatorIndicatorEqualVisible() {
        return !isErrorState && (operator === Constants.Operator.None || isKCalculationMode) && isResultDisplayed();
    }

    // Support digit input functionality:
    // If the displayed number is read-only (result), start a new entry by clearing the current
    // result if no operator is pending, or clearing the current operand if an operator is pending.
    function digitClicked(digit) {
        if (isErrorState) return; // AC and CE can clear the error state.
        clearPercentageMode();

        if (isDisplayedNumberReadOnly()) {
            if (hasNoOperator()) {
                allClearClicked();
            } else {
                clearOperand();
            }
        }

        operand.appendDigit(digit);
        displayOperand();
    }

    // Support delete (backspace) functionality:
    // If the displayed number is editable (current operand), delete the last digit. If the
    // displayed number is read-only (result), clear the current entry instead.
    function deleteDigit() {
        if (isErrorState) return; // AC and CE can clear the error state.
        clearPercentageMode();

        if (isDisplayedNumberEditable()) {
            operand.deleteDigit();
            displayOperand();
        } else {
            clearEntryClicked();
        }
    }

    // Support decimal point input functionality:
    // If the displayed number is read-only (result), start a new entry by clearing the current
    // result if no operator is pending, or clearing the current operand if an operator is pending.
    function decimalClicked() {
        if (isErrorState) return; // AC and CE can clear the error state.
        clearPercentageMode();

        if (isDisplayedNumberReadOnly()) {
            clearOperand();
        }

        operand.appendDecimalPoint();
        displayOperand();
    }

    function clearOperand() {
        operand.clear();
    }

    // Modified by Yasuhiro Yamakawa on 2026-05-14
    // Adapted to the new operator handling logic.
    function doOperation() {
        switch (operator) {
        case Constants.Operator.None:
            result.assign(operand);
            break;
        case Constants.Operator.Add:
            result.add(operand);
            break;
        case Constants.Operator.Subtract:
            result.subtract(operand);
            break;
        case Constants.Operator.Multiply:
            result.multiply(operand);
            break;
        case Constants.Operator.Divide:
            if (operand.isZero()) {
                isErrorState = true;
                return;
            }
            result.divide(operand);
            break;
        }

        // Keep result for
        if (!isKCalculationMode) {
            buffer.assign(result);
        }

        displayResult();
    }

    function clearOperator() {
        operator = Constants.Operator.None;
    }

    function operatorClicked(op) {
        if (isErrorState) return; // AC and CE can clear the error state.
        
        if (isPercentageMode) {
            isPercentageMode = false;
            if (operator === Constants.Operator.Add) {
                if (op === Constants.Operator.Subtract) {
                    operand.assign(buffer);
                    result.subtract(operand);
                    operator = Constants.Operator.None;
                    displayResult();
                    return;
                }
            } else if (operator === Constants.Operator.Multiply) {
                if (op === Constants.Operator.Add) {
                    operand.assign(buffer);
                    result.add(operand);
                    operator = Constants.Operator.None;
                    displayResult();
                    return;
                } else if (op === Constants.Operator.Subtract) {
                    operand.assign(result);
                    result.assign(buffer);
                    result.subtract(operand);
                    operator = Constants.Operator.None;
                    displayResult();
                    return;
                }
            }
            operator = Constants.Operator.None;
        }

        if (isOperandDisplayed()) {
            if (isKCalculationMode) {
                isKCalculationMode = false;
                result.assign(operand);
                displayResult();
            } else {
                doOperation();
            }
        } else if (isResultDisplayed()) {
            if (isKCalculationMode) {
                isKCalculationMode = false;
            } else if (isResultDisplayed && operator === op) {
                isKCalculationMode = true;
                buffer.assign(result);
            }
        }
        
        if (isErrorState) { // Reverts result on error.
            result.assign(buffer);
        } else {
            operator = op;
        }
    }

    // Support negate (±) functionality:
    // Negates the current operand if it's being displayed, or negates the result if the result is
    // being displayed.
    function negateClicked() {
        if (isErrorState) return; // AC and CE can clear the error state.
        clearPercentageMode();

        if (isOperandDisplayed()) {
            operand.negate();
            displayOperand();
        } else {
            result.negate();
            displayResult();
        }
    }

    // Support root (√) functionality:
    // If the current operand or result is negative, display an error message instead of performing
    // the operation, as square root of negative numbers is not supported in this calculator.
    function rootClicked() {
        if (isErrorState) return; // AC and CE can clear the error state.
        clearPercentageMode();

        if (isOperandDisplayed()) {
            operand.setReadOnly();

            if (operand.isNegative()) {
                isErrorState = true;
                operand.negate();
                displayOperand();
                return;
            }

            buffer.assign(operand);
            operand.sqrt();
            displayOperand();
        } else {
            if (result.isNegative()) {
                isErrorState = true;
                result.negate();
                displayResult();
                return;
            }

            if (isKCalculationMode) {
                isKCalculationMode = false;
                operator = Constants.Operator.None;
            }

            // After clicking operators, if the user clicks the root button before entering a new operand.
            if (hasOperator()) {
                allClearClicked();
                return;
            }

            result.sqrt();
            displayResult();
        }
    }

    // Support equals (=) functionality:
    // If an operator is pending, perform the calculation with the current operand and display the
    // result. Then clear the operator and operand to allow for new input or continued calculations
    // with the result.
    function equalsClicked() {
        if (isErrorState) return; // AC and CE can clear the error state.
        clearPercentageMode();

        if (isKCalculationMode) {
            if (isOperandDisplayed()) {
                result.assign(operand);
            }
            operand.assign(buffer);
            doOperation();
        } else if (isOperandDisplayed() || hasOperator()) {
            doOperation();
            if (isErrorState) { // Reverts result on error.
                result.assign(buffer);
            } else {
                clearOperator();
                clearOperand();
            }
        }
    }

    // Support clear entry (CE) functionality:
    // Clears the current operand being typed without affecting the ongoing calculation or operator.
    function clearEntryClicked() {
        if (isErrorState) { // Clears error state on first click.
            isErrorState = false;
        } else {  // Clears operand on second click.
            isPercentageMode = false;
            clearOperand();
            displayOperand();
        }
    }

    // Support all clear (AC) functionality:
    // Clears the entire calculation state, including the current result and any ongoing input.
    function allClearClicked() {
        isKCalculationMode = false;
        buffer.clear();
        clearOperator();
        clearEntryClicked();
        result.clear();
    }

    // For memory recall/clear (MRC) button:
    // If the display is currently showing the memory value, clear it.
    // If hasMemory is false, it behaves as if it were zero.
    function memoryRecallClearClicked() {
        if (isErrorState) return; // AC and CE can clear the error state.
        isPercentageMode = false;

        if (isMemoryDisplayed()) {
            clearMemory();
        } else {
            if (hasNoOperator()) {
                allClearClicked();
            }
            operand.assign(memory);
            displayMemory();
        }
    }

    function clearMemory() {
        memory.clear();
        hasMemory = false;
    }

    // For memory plus (M+) button:
    // Adds the current result to memory.
    function memoryPlusClicked() {
        if (isErrorState) return; // AC and CE can clear the error state.
        isPercentageMode = false;

        equalsClicked();
        memory.add(result);
        hasMemory = true;
    }

    // For memory minus (M-) button:
    // Subtracts the current result from memory.
    function memoryMinusClicked() {
        if (isErrorState) return; // AC and CE can clear the error state.
        isPercentageMode = false;

        equalsClicked();
        memory.subtract(result);
        hasMemory = true;
    }

    // Support percentage (%) functionality:
    // The behavior of the percentage button depends on the current operator and whether the operand
    // or result is being displayed. It follows Casio-style percentage calculations.
    function percentClicked() {
        if (isErrorState) return; // AC and CE can clear the error state.

        if (isKCalculationMode || isPercentageMode) return;

        switch (operator) {
            case Constants.Operator.None:
                // Do nothing
                return;
            case Constants.Operator.Add:
                // a * (1 / (1 - b/100))
                // a * (b/100 / (1 - b/100)) --- (-)
                isPercentageMode = true;
                buffer.assign(result);
                operand.fromPercent();
                result.assignOne();
                result.subtract(operand);
                if (result.isZero()) {
                    isErrorState = true;
                    return;
                }
                operand.assign(result);
                result.assign(buffer);
                result.divide(operand);
                break;
            case Constants.Operator.Subtract:
                // (a - b) / b (%)
                if (operand.isZero()) {
                    isErrorState = true;
                    return;
                }
                result.subtract(operand);
                result.divide(operand);
                result.toPercent();
                operator = Constants.Operator.None
                break;
            case Constants.Operator.Multiply:
                // a * b/100
                // a + a * b/100 --- (+)
                // a - a * b/100 --- (-)
                isPercentageMode = true;
                buffer.assign(result);
                operand.fromPercent();
                result.multiply(operand);
                break;
            case Constants.Operator.Divide:
                // a / b (%)
                if (operand.isZero()) {
                    isErrorState = true;
                    return;
                }
                result.divide(operand);
                result.toPercent();
                operator = Constants.Operator.None
                break;
        }

        displayResult();
    }

    // Clears the operator if percentage mode is active. This is necessary to prevent incorrect behavior.
    function clearPercentageMode() {
        if (isPercentageMode) {
            isPercentageMode = false;
            operator = Constants.Operator.None
        }
    }

    // Modified by Yasuhiro Yamakawa on 2026-05-14
    // Ensured that the clipboard functions work correctly.
    function copyToClipboard() {
        let text = isOperandDisplayed() ? operand.toFormatNumber() : result.toFormatNumber();
        text = text.replace(/\u2009/g, "");
        dummyTextEditForPasting.text = text;
        dummyTextEditForPasting.selectAll();
        dummyTextEditForPasting.copy();
        dummyTextEditForPasting.clear();
    }

    function pasteFromClipboard() {
        dummyTextEditForPasting.clear()
        dummyTextEditForPasting.paste()
        let content = dummyTextEditForPasting.text
        dummyTextEditForPasting.clear()
        if (content != "") {
            content = content.trim();
        }

        // check if the clipboard content as a whole is a valid number (without sign, no operators, ...)
        main.clearEntryClicked();
        if (isValidClipboardInput(content)) {
            let digitRegex = new RegExp('^[0-9]$');
            let decimalRegex = new RegExp('^[\.,]$');

            for (let i = 0; i < content.length; i++) {
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

    function displayResult() {
        displayValue = Constants.RegisterRole.Result;
        display.text = result.toFormatNumber();
    }

    function displayOperand() {
        displayValue = Constants.RegisterRole.Operand;
        display.text =operand.toFormatNumber();
    }

    function displayMemory() {
        displayValue = Constants.RegisterRole.Memory;
        display.text =operand.toFormatNumber();
    }

    // Dummy TextEdit used for clipboard operations, as TextEdit's copy/paste functions require a focused TextEdit.
    TextEdit {
        id: dummyTextEditForPasting
        visible: false
        height: 0
        activeFocusOnTab: false
    }

    // Added by Yasuhiro Yamakawa on 2026-05-12
    // Custom button component to ensure consistent styling and behavior across all calculator buttons.
    component CalcButton : PlasmaComponents.Button {
        property alias buttonFont: buttonLabel.font

        implicitWidth: 60
        implicitHeight: 40

        Layout.fillWidth: true
        Layout.fillHeight: true
    
        // Override the contentItem once here
        contentItem: PlasmaComponents.Label {
            id: buttonLabel
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

            focus: true
            spacing: 4

            // Modified by Yasuhiro Yamakawa on 2026-05-12 for Qt6 compatibility:
            // Updated all key event handlers (digits and operators) to explicit signal handler syntax.
            //
            // Modified by Yasuhiro Yamakawa on 2026-05-14:
            // Adapted to the new operator handling logic.
            // Improved readability by adding line breaks.
            Keys.onDigit0Pressed: (event) => {
                main.digitClicked(0);
                zeroButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDigit1Pressed: (event) => {
                main.digitClicked(1);
                oneButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDigit2Pressed: (event) => {
                main.digitClicked(2);
                twoButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDigit3Pressed: (event) => {
                main.digitClicked(3);
                threeButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDigit4Pressed: (event) => {
                main.digitClicked(4);
                fourButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDigit5Pressed: (event) => {
                main.digitClicked(5);
                fiveButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDigit6Pressed: (event) => {
                main.digitClicked(6);
                sixButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDigit7Pressed: (event) => {
                main.digitClicked(7);
                sevenButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDigit8Pressed: (event) => {
                main.digitClicked(8);
                eightButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDigit9Pressed: (event) => {
                main.digitClicked(9);
                nineButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onEscapePressed: (event) => {
                main.allClearClicked();
                allClearButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onDeletePressed: (event) => {
                // Modified by Yasuhiro Yamakawa on 2026-05-14
                // Support clear entry (CE) functionality with the Delete key.
                main.clearEntryClicked(); 
                clearButton.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            Keys.onPressed: (event) => {
                switch (event.key) {
                case Qt.Key_Plus:
                    main.operatorClicked(Constants.Operator.Add);
                    plusButton.forceActiveFocus(Qt.TabFocusReason);
                    break;
                case Qt.Key_Minus:
                    main.operatorClicked(Constants.Operator.Subtract);
                    minusButton.forceActiveFocus(Qt.TabFocusReason);
                    break;
                case Qt.Key_Asterisk:
                    main.operatorClicked(Constants.Operator.Multiply);
                    multiplyButton.forceActiveFocus(Qt.TabFocusReason);
                    break;
                case Qt.Key_Slash:
                    main.operatorClicked(Constants.Operator.Divide);
                    divideButton.forceActiveFocus(Qt.TabFocusReason);
                    break;
                case Qt.Key_Comma:
                case Qt.Key_Period:
                    main.decimalClicked();
                    decimalButton.forceActiveFocus(Qt.TabFocusReason);
                    break;
                case Qt.Key_Equal:
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    main.equalsClicked();
                    break;
                case Qt.Key_Backspace:
                    main.deleteDigit();
                    break;
                // Added by Yasuhiro Yamakawa on 2026-05-12
                // Handles the +/- key found on keyboards like the Dell KB740 (maps to F9).
                case Qt.Key_F9:
                    main.negateClicked();
                    negateButton.forceActiveFocus(Qt.TabFocusReason);
                    break;
                case Qt.Key_Percent:
                    main.percentClicked();
                    break;
                default:
                    if (event.matches(StandardKey.Copy)) {
                        main.copyToClipboard();
                        break;
                    } else if (event.matches(StandardKey.Paste)) {
                        main.pasteFromClipboard();
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
            // Modified by Yasuhiro Yamakawa on 2026-05-12:
            // Don't show highlight on buttons after release keys.
            //
            // Modified by Yasuhiro Yamakawa on 2026-05-14:
            // Fix the wrong focus behavior after key release.
            Keys.onReleased: (event) => {
                mainLayout.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }

            KSvg.FrameSvgItem {
                id: displayFrame
                Layout.fillWidth: true
                Layout.minimumHeight: 2 * display.font.pixelSize
                imagePath: "widgets/frame"
                prefix: "plain"

                // focus: main.expanded

                ColumnLayout {
                    // Fill the frame completely while respecting the SVG theme borders
                    anchors.fill: parent
                    anchors.leftMargin: (parent && parent.margins) ? parent.margins.left : 0
                    anchors.rightMargin: (parent && parent.margins) ? parent.margins.right : 0
                    anchors.topMargin: (parent && parent.margins) ? parent.margins.top : 0
                    anchors.bottomMargin: (parent && parent.margins) ? parent.margins.bottom : 0
                    spacing: 0

                    RowLayout {
                        id: statusRow
                        Layout.fillWidth: true
                        Layout.preferredHeight: displayFrame.height * 0.2
                        spacing: 0

                        TextEdit {
                            id: memoryIndicator
                            text: "M"

                            Layout.fillHeight: true
                            Layout.preferredWidth: height
                            Layout.leftMargin: displayFrame.width * 0.05

                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1
                            font.weight: Font.Bold
                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                            color: Kirigami.Theme.textColor
                            verticalAlignment: TextEdit.AlignVCenter
                            readOnly: true
                            opacity: main.hasMemory ? 1.0 : 0.0

                            Accessible.name: text
                            Accessible.description: i18nc("@label Status", "Status")
                        }

                        TextEdit {
                            id: kCalculationIndicator
                            text: "K"
                    
                            Layout.fillHeight: true
                            Layout.preferredWidth: height
                            Layout.leftMargin: displayFrame.width * 0.1
                            rightPadding: 0

                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1
                            font.weight: Font.Bold
                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                            color: Kirigami.Theme.textColor
                            verticalAlignment: TextEdit.AlignVCenter
                            readOnly: true
                            opacity: main.isKCalculationMode ? 1.0 : 0.0

                            Accessible.name: text
                            Accessible.description: i18nc("@label Status", "Status")
                        }

                        TextEdit {
                            id: errorStateIndicator
                            text: "E"
                    
                            Layout.fillHeight: true
                            Layout.preferredWidth: height
                            Layout.leftMargin: displayFrame.width * 0.05
                            rightPadding: 0

                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1
                            font.weight: Font.Bold
                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                            color: Kirigami.Theme.textColor
                            verticalAlignment: TextEdit.AlignVCenter
                            readOnly: true
                            opacity: main.isErrorState ? 1.0 : 0.0

                            Accessible.name: text
                            Accessible.description: i18nc("@label Error State", "Error State")
                        }

                        TextEdit {
                            id: operatorIndicatorAdd
                            Layout.fillHeight: true
                            Layout.preferredWidth: height
                            Layout.leftMargin: displayFrame.width * 0.05

                            text: "+" // "\u2795"
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1
                            font.weight: Font.Bold
                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                            color: Kirigami.Theme.textColor
                            verticalAlignment: TextEdit.AlignVCenter
                            readOnly: true
                            opacity: main.isOperatorIndicatorAdditionVisible() ? 1.0 : 0.0

                            Accessible.name: text
                            Accessible.description: i18nc("@label Current Operand", "Apply Plus")
                        }

                        TextEdit {
                            id: operatorIndicatorSubtract
                            Layout.fillHeight: true
                            Layout.preferredWidth: height
                            Layout.leftMargin: displayFrame.width * 0.02

                            text: "\u2212" // "\u2796"
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1
                            font.weight: Font.Bold
                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                            color: Kirigami.Theme.textColor
                            // horizontalAlignment: TextEdit.AlignHCenter
                            verticalAlignment: TextEdit.AlignVCenter
                            readOnly: true
                            opacity: main.isOperatorIndicatorSubtractionVisible() ? 1.0 : 0.0

                            // focus: main.expanded

                            Accessible.name: text
                            Accessible.description: i18nc("@label Status", "Status")
                        }

                        TextEdit {
                            id: operatorIndicatorMultiply
                            Layout.fillHeight: true
                            Layout.preferredWidth: height
                            Layout.leftMargin: displayFrame.width * 0.02

                            text: "\u00d7" // "\u2715"
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1
                            font.weight: Font.Bold
                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                            color: Kirigami.Theme.textColor
                            verticalAlignment: TextEdit.AlignVCenter
                            readOnly: true
                            opacity: main.isOperatorIndicatorMultiplicationVisible() ? 1.0 : 0.0

                            Accessible.name: text
                            Accessible.description: i18nc("@label Status", "Status")
                        }

                        TextEdit {
                            id: operatorIndicatorDivide
                            Layout.fillHeight: true
                            Layout.preferredWidth: height
                            Layout.leftMargin: displayFrame.width * 0.02

                            text: "\u00f7" // "\u2797"
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1
                            font.weight: Font.Bold
                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                            color: Kirigami.Theme.textColor
                            verticalAlignment: TextEdit.AlignVCenter
                            readOnly: true
                            opacity: main.isOperatorIndicatorDivisionVisible() ? 1.0 : 0.0

                            Accessible.name: text
                            Accessible.description: i18nc("@label Status", "Status")
                        }

                        TextEdit {
                            id: operatorIndicatorEqual
                            Layout.fillHeight: true
                            Layout.preferredWidth: height
                            Layout.leftMargin: displayFrame.width * 0.02

                            text: "="
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1
                            font.weight: Font.Bold
                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                            color: Kirigami.Theme.textColor
                            verticalAlignment: TextEdit.AlignVCenter
                            readOnly: true
                            opacity: main.isOperatorIndicatorEqualVisible() ? 1.0 : 0.0

                            Accessible.name: text
                            Accessible.description: i18nc("@label Status", "Status")
                        }
                    }

                    TextEdit {
                        id: display
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        text: "0"
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 2
                        font.weight: Font.Bold
                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                        color: Kirigami.Theme.textColor
                        horizontalAlignment: TextEdit.AlignRight
                        verticalAlignment: TextEdit.AlignVCenter
                        readOnly: true

                        // focus: main.expanded

                        Accessible.name: text
                        Accessible.description: i18nc("@label calculation result", "Result")

                        Binding {
                            target: main
                            property: "display"
                            value: display
                        }
                    }
                }
            }

            // Modified by Yasuhiro Yamakawa on 2026-05-12
            // Arranged the buttons to match the standard calculator layout and
            //   added the new negate button.
            GridLayout {
                id: buttonsGrid
                columns: 4
                rows: 5
                columnSpacing: 4
                rowSpacing: 4

                Layout.fillWidth: true
                Layout.fillHeight: true

                property real equalWidth: (width - (columnSpacing * (columns - 1))) / columns
                property real equalHeight: (height - (rowSpacing * (rows - 1))) / rows
                property real extraSmallFontSize: Math.max(1, Math.min(equalWidth / 6 , equalHeight / 3.6))
                property real smallFontSize: Math.max(1, Math.min(equalWidth / 5 , equalHeight / 3))
                property real normalFontSize: Math.max(1, Math.min(equalWidth / 4 , equalHeight / 2.4))

                CalcButton {
                    id: memoryRecallClearButton
                    buttonFont.pointSize: buttonsGrid.extraSmallFontSize

                    KeyNavigation.up: zeroButton
                    KeyNavigation.down: allClearButton
                    KeyNavigation.left: rootButton
                    KeyNavigation.right: memoryMinusButton

                    text: i18nc("Text of the memory recall/clear button", "MRC")
                    onClicked: main.memoryRecallClearClicked()
                }

                CalcButton {
                    id: memoryMinusButton
                    buttonFont.pointSize: buttonsGrid.extraSmallFontSize

                    KeyNavigation.up: decimalButton
                    KeyNavigation.down: clearButton
                    KeyNavigation.left: memoryRecallClearButton
                    KeyNavigation.right: memoryPlusButton

                    text: i18nc("Text of the memory minus button", "M−")
                    onClicked: main.memoryMinusClicked()
                }

                // Added by Yasuhiro Yamakawa on 2026-05-12
                // New button for sign inversion (negate).
                CalcButton {
                    id: memoryPlusButton
                    buttonFont.pointSize: buttonsGrid.extraSmallFontSize

                    KeyNavigation.up: ansButton
                    KeyNavigation.down: negateButton
                    KeyNavigation.left: memoryMinusButton
                    KeyNavigation.right: rootButton

                    text: i18nc("Text of the memory plus button", "M+")
                    onClicked: main.memoryPlusClicked()
                }

                CalcButton {
                    id: rootButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize
                    Layout.preferredWidth: buttonsGrid.equalWidth

                    KeyNavigation.up: plusButton
                    KeyNavigation.down: percentButton
                    KeyNavigation.left: memoryPlusButton
                    KeyNavigation.right: memoryRecallClearButton

                    text: i18nc("Text of the root button", "√")
                    onClicked: main.rootClicked()
                }


                CalcButton {
                    id: allClearButton
                    buttonFont.pointSize: buttonsGrid.smallFontSize
                    Layout.preferredWidth: buttonsGrid.equalWidth

                    KeyNavigation.up: memoryRecallClearButton
                    KeyNavigation.down: sevenButton
                    KeyNavigation.left: percentButton
                    KeyNavigation.right: clearButton

                    text: i18nc("Text of the all clear button", "AC")
                    onClicked: main.allClearClicked()
                }

                CalcButton {
                    id: clearButton
                    buttonFont.pointSize: buttonsGrid.smallFontSize
                    Layout.preferredWidth: buttonsGrid.equalWidth

                    KeyNavigation.up: memoryMinusButton
                    KeyNavigation.down: eightButton
                    KeyNavigation.left: allClearButton
                    KeyNavigation.right: negateButton

                    text: i18nc("Text of the clear button", "C")
                    // Modified by Yasuhiro Yamakawa on 2026-05-14:
                    // Clear entry (CE) button - clears the current input.
                    onClicked: main.clearEntryClicked()
                }

                // Added by Yasuhiro Yamakawa on 2026-05-12
                // New button for sign inversion (negate).
                CalcButton {
                    id: negateButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize
                    Layout.preferredWidth: buttonsGrid.equalWidth

                    KeyNavigation.up: memoryPlusButton
                    KeyNavigation.down: nineButton
                    KeyNavigation.left: clearButton
                    KeyNavigation.right: percentButton

                    text: i18nc("Text of the negate button", "+/−")
                    onClicked: main.negateClicked()
                }

                CalcButton {
                    id: percentButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize
                    Layout.preferredWidth: buttonsGrid.equalWidth

                    KeyNavigation.up: rootButton
                    KeyNavigation.down: divideButton
                    KeyNavigation.left: negateButton
                    KeyNavigation.right: allClearButton

                    text: i18nc("Text of the percent button", "%")
                    onClicked: main.percentClicked()
                }


                CalcButton {
                    id: sevenButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize

                    KeyNavigation.up: allClearButton
                    KeyNavigation.down: fourButton
                    KeyNavigation.left: divideButton
                    KeyNavigation.right: eightButton

                    text: "7"
                    onClicked: main.digitClicked(7)
                }

                CalcButton {
                    id: eightButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize

                    KeyNavigation.up: clearButton
                    KeyNavigation.down: fiveButton
                    KeyNavigation.left: sevenButton
                    KeyNavigation.right: nineButton

                    text: "8"
                    onClicked: main.digitClicked(8)
                }

                CalcButton {
                    id: nineButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize

                    KeyNavigation.up: negateButton
                    KeyNavigation.down: sixButton
                    KeyNavigation.left: eightButton
                    KeyNavigation.right: divideButton

                    text: "9"
                    onClicked: main.digitClicked(9)
                }

                CalcButton {
                    id: divideButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize

                    KeyNavigation.up: percentButton
                    KeyNavigation.down: multiplyButton
                    KeyNavigation.left: nineButton
                    KeyNavigation.right: sevenButton

                    text: i18nc("Text of the division button", "÷")
                    onClicked: main.operatorClicked(Constants.Operator.Divide)
                }


                CalcButton {
                    id: fourButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize

                    KeyNavigation.up: sevenButton
                    KeyNavigation.down: oneButton
                    KeyNavigation.left: multiplyButton
                    KeyNavigation.right: fiveButton

                    text: "4"
                    onClicked: main.digitClicked(4)
                }

                CalcButton {
                    id: fiveButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize

                    KeyNavigation.up: eightButton
                    KeyNavigation.down: twoButton
                    KeyNavigation.left: fourButton
                    KeyNavigation.right: sixButton

                    text: "5"
                    onClicked: main.digitClicked(5)
                }

                CalcButton {
                    id: sixButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize

                    KeyNavigation.up: nineButton
                    KeyNavigation.down: threeButton
                    KeyNavigation.left: fiveButton
                    KeyNavigation.right: multiplyButton

                    text: "6"
                    onClicked: main.digitClicked(6)
                }

                CalcButton {
                    id: multiplyButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize

                    KeyNavigation.up: divideButton
                    KeyNavigation.down: minusButton
                    KeyNavigation.left: sixButton
                    KeyNavigation.right: fourButton

                    text: i18nc("Text of the multiplication button", "×")
                    onClicked: main.operatorClicked(Constants.Operator.Multiply)
                }


                CalcButton {
                    id: oneButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize

                    KeyNavigation.up: fourButton
                    KeyNavigation.down: zeroButton
                    KeyNavigation.left: minusButton
                    KeyNavigation.right: twoButton

                    text: "1"
                    onClicked: main.digitClicked(1)
                }

                CalcButton {
                    id: twoButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize

                    KeyNavigation.up: fiveButton
                    KeyNavigation.down: decimalButton
                    KeyNavigation.left: oneButton
                    KeyNavigation.right: threeButton

                    text: "2"
                    onClicked: main.digitClicked(2)
                }

                CalcButton {
                    id: threeButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize

                    KeyNavigation.up: sixButton
                    KeyNavigation.down: ansButton
                    KeyNavigation.left: twoButton
                    KeyNavigation.right: minusButton

                    text: "1"
                    onClicked: main.digitClicked(3)
                }

                CalcButton {
                    id: minusButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize

                    KeyNavigation.up: multiplyButton
                    KeyNavigation.down: plusButton
                    KeyNavigation.left: threeButton
                    KeyNavigation.right: oneButton

                    text: i18nc("Text of the minus button", "−")
                    onClicked: main.operatorClicked(Constants.Operator.Subtract)
                }


                CalcButton {
                    id: zeroButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize

                    KeyNavigation.up: oneButton
                    KeyNavigation.down: memoryRecallClearButton
                    KeyNavigation.left: plusButton
                    KeyNavigation.right: decimalButton


                    text: "0"
                    onClicked: main.digitClicked(0)
                }

                CalcButton {
                    id: decimalButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize

                    KeyNavigation.up: twoButton
                    KeyNavigation.down: memoryMinusButton
                    KeyNavigation.left: zeroButton
                    KeyNavigation.right: ansButton

                    text: Qt.locale().decimalPoint
                    onClicked: main.decimalClicked()
                }

                CalcButton {
                    id: ansButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize

                    KeyNavigation.up: threeButton
                    KeyNavigation.down: memoryPlusButton
                    KeyNavigation.left: decimalButton
                    KeyNavigation.right: plusButton
                    
                    text: i18nc("Text of the equals button", "=")
                    onClicked: main.equalsClicked()
                }

                CalcButton {
                    id: plusButton
                    buttonFont.pointSize: buttonsGrid.normalFontSize

                    KeyNavigation.up: minusButton
                    KeyNavigation.down: rootButton
                    KeyNavigation.left: ansButton
                    KeyNavigation.right: zeroButton

                    text: i18nc("Text of the plus button", "+")
                    onClicked: main.operatorClicked(Constants.Operator.Add)
                }
            }
        }
    }
}
