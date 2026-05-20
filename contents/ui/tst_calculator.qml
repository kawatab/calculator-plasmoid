/*
 *   SPDX-FileCopyrightText: 2026 Yasuhiro Yamakawa <kawatab@gmail.com>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

// This is a test suite for the calculator plasmoid. It verifies that the main.qml file can be loaded
// and that its properties can be accessed without errors. This helps ensure that the basic structure
// of the application is correct and that the main logic can run without issues.
// 
// How to run this test:
// qmltestrunner -import contents/ui/mock -input contents/ui/tst_calculator.qml


import QtQuick 2.15
import QtTest 1.15

TestCase {
    name: "CalculatorTests"

    Component {
        id: mainAppLoader
        Loader {
            source: Qt.resolvedUrl("main.qml")
        }
    }
    
    // Inject global mock functions to bypass the missing translation catalogs
    function i18n(text) { return text; }
    function i18nc(context, text) { return text; }
    function i18np(singular, plural, n) { return n === 1 ? singular : plural; }
    function i18ncp(context, singular, plural, n) { return n === 1 ? singular : plural; }

    function test_primitives() {
        // 1. Load the main.qml file dynamically using the Loader component defined above
        let appInstance = mainAppLoader.createObject(parent);
        
        // 2. Verify that the Loader successfully created an instance of main.qml
        verify(appInstance !== null, "main.qml failed to load");
        compare(appInstance.status, Loader.Ready, "main.qml failed to load due to configuration or syntax errors");
        verify(appInstance.item !== null, "The root item inside main.qml failed to initialize");

        // 3. Access the root object inside main.qml using appInstance.item
        let mainRoot = appInstance.item;

        // 4. Test
        verify(mainRoot.operand.isZero(), "Operand should be zero successfully");
        verify(mainRoot.operand.isEditable(), "Operand should be editable successfully");
        verify(mainRoot.result.isZero(), "Result should be initialized successfully");
        verify(mainRoot.result.isReadOnly(), "Result should be read-only successfully");
        verify(mainRoot.memory.isZero(), "Memory should be initialized successfully");
        verify(mainRoot.memory.isReadOnly(), "Memory should be read-only successfully");

        mainRoot.digitClicked(5);
        mainRoot.operatorClicked(Constants.Operator.Add);
        mainRoot.digitClicked(3);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "8", "Result of 5 + 3 should be 8");

        mainRoot.allClearClicked();

        mainRoot.digitClicked(9);
        mainRoot.operatorClicked(Constants.Operator.Subtract);
        mainRoot.digitClicked(4);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "5", "Result of 9 - 4 should be 5");

        mainRoot.allClearClicked();

        mainRoot.digitClicked(6);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(7);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "42", "Result of 6 * 7 should be 42");

        mainRoot.allClearClicked();

        mainRoot.digitClicked(8);
        mainRoot.operatorClicked(Constants.Operator.Divide);
        mainRoot.digitClicked(2);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "4", "Result of 8 / 2 should be 4");

        // 5. Clean up by destroying the created instance to avoid side effects on other tests
        appInstance.destroy();
    }

    function test_input() {
        // 1. Load the main.qml file dynamically using the Loader component defined above
        let appInstance = mainAppLoader.createObject(parent);
        
        // 2. Verify that the Loader successfully created an instance of main.qml
        verify(appInstance !== null, "main.qml failed to load");
        compare(appInstance.status, Loader.Ready, "main.qml failed to load due to configuration or syntax errors");
        verify(appInstance.item !== null, "The root item inside main.qml failed to initialize");

        // 3. Access the root object inside main.qml using appInstance.item
        let mainRoot = appInstance.item;

        // 4. Test
        mainRoot.digitClicked(0);
        mainRoot.digitClicked(1);
        mainRoot.digitClicked(2);
        mainRoot.digitClicked(3);
        mainRoot.digitClicked(4);
        mainRoot.digitClicked(5);
        mainRoot.digitClicked(6);
        mainRoot.digitClicked(7);
        mainRoot.digitClicked(8);
        mainRoot.digitClicked(9);
        mainRoot.digitClicked(0);
        mainRoot.digitClicked(1);
        mainRoot.digitClicked(2);
        verify(mainRoot.operand.toFormatNumber() === "123\u2009456\u2009789\u2009012", "Result of 012345679012 should be 123 456 789 012");

        mainRoot.allClearClicked();

        mainRoot.digitClicked(0);
        mainRoot.decimalClicked();
        mainRoot.digitClicked(1);
        mainRoot.digitClicked(2);
        mainRoot.digitClicked(3);
        mainRoot.digitClicked(4);
        mainRoot.digitClicked(5);
        mainRoot.digitClicked(6);
        mainRoot.digitClicked(7);
        mainRoot.digitClicked(8);
        mainRoot.digitClicked(9);
        mainRoot.digitClicked(0);
        mainRoot.digitClicked(1);
        mainRoot.digitClicked(2);
        verify(mainRoot.operand.toFormatNumber() === "0.123\u2009456\u2009789\u200901", "Result of 012345679012 should be 0.123 456 789 01");

        mainRoot.allClearClicked();

        // 5. Clean up by destroying the created instance to avoid side effects on other tests
        appInstance.destroy();
    }
}