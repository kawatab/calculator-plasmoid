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
        verify(mainRoot.result.isZero(), "Result should be initialized successfully");
        verify(mainRoot.memory.isZero(), "Memory should be initialized successfully");

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

    function test_percent() {
        // 1. Load the main.qml file dynamically using the Loader component defined above
        let appInstance = mainAppLoader.createObject(parent);
        
        // 2. Verify that the Loader successfully created an instance of main.qml
        verify(appInstance !== null, "main.qml failed to load");
        compare(appInstance.status, Loader.Ready, "main.qml failed to load due to configuration or syntax errors");
        verify(appInstance.item !== null, "The root item inside main.qml failed to initialize");

        // 3. Access the root object inside main.qml using appInstance.item
        let mainRoot = appInstance.item;

        // 4. Test
        mainRoot.digitClicked(2);
        mainRoot.digitClicked(0);
        mainRoot.digitClicked(0);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(5);
        mainRoot.percentClicked();
        verify(mainRoot.result.toFormatNumber() === "10", "Result of 200×5% should be 10");

        mainRoot.allClearClicked();

        mainRoot.digitClicked(1);
        mainRoot.digitClicked(0);
        mainRoot.digitClicked(0);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(5);
        mainRoot.percentClicked();
        mainRoot.operatorClicked(Constants.Operator.Add);
        verify(mainRoot.result.toFormatNumber() === "105", "Result of 100×5%+ should be 105");

        mainRoot.allClearClicked();

        mainRoot.digitClicked(5);
        mainRoot.digitClicked(0);
        mainRoot.digitClicked(0);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(2);
        mainRoot.digitClicked(0);
        mainRoot.percentClicked();
        mainRoot.operatorClicked(Constants.Operator.Subtract);
        verify(mainRoot.result.toFormatNumber() === "400", "Result of 500×20%- should be 400");

        mainRoot.allClearClicked();

        mainRoot.digitClicked(3);
        mainRoot.digitClicked(0);
        mainRoot.operatorClicked(Constants.Operator.Divide);
        mainRoot.digitClicked(6);
        mainRoot.digitClicked(0);
        mainRoot.percentClicked();
        verify(mainRoot.result.toFormatNumber() === "50", "Result of 30÷60% should be 50");

        mainRoot.allClearClicked();

        mainRoot.digitClicked(1);
        mainRoot.digitClicked(2);
        mainRoot.operatorClicked(Constants.Operator.Subtract);
        mainRoot.digitClicked(1);
        mainRoot.digitClicked(0);
        mainRoot.percentClicked();
        verify(mainRoot.result.toFormatNumber() === "20", "Result of 12-10% should be 20");

        mainRoot.allClearClicked();

        mainRoot.digitClicked(1);
        mainRoot.digitClicked(2);
        mainRoot.digitClicked(0);
        mainRoot.operatorClicked(Constants.Operator.Add);
        mainRoot.digitClicked(2);
        mainRoot.digitClicked(5);
        mainRoot.percentClicked();
        verify(mainRoot.result.toFormatNumber() === "160", "Result of 120+25% should be 160");

        mainRoot.operatorClicked(Constants.Operator.Subtract);
        verify(mainRoot.result.toFormatNumber() === "40", "Result of 120+25%- should be 40");

        mainRoot.allClearClicked();


        // 5. Clean up by destroying the created instance to avoid side effects on other tests
        appInstance.destroy();
    }

    function test_basic_calculation_calculator_A() {
        // 1. Load the main.qml file dynamically using the Loader component defined above
        let appInstance = mainAppLoader.createObject(parent);
        
        // 2. Verify that the Loader successfully created an instance of main.qml
        verify(appInstance !== null, "main.qml failed to load");
        compare(appInstance.status, Loader.Ready, "main.qml failed to load due to configuration or syntax errors");
        verify(appInstance.item !== null, "The root item inside main.qml failed to initialize");

        // 3. Access the root object inside main.qml using appInstance.item
        let mainRoot = appInstance.item;

        // 4. Test
        mainRoot.digitClicked(4);
        mainRoot.operatorClicked(Constants.Operator.Subtract);
        mainRoot.digitClicked(6);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "-2", "Result of 4-6 should be -2");

        mainRoot.digitClicked(1);
        mainRoot.operatorClicked(Constants.Operator.Add);
        mainRoot.digitClicked(2);
        mainRoot.operatorClicked(Constants.Operator.Divide);
        mainRoot.digitClicked(3);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(4);
        mainRoot.operatorClicked(Constants.Operator.Subtract);
        mainRoot.digitClicked(5);
        mainRoot.decimalClicked();
        mainRoot.digitClicked(5);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "-1.5", "Result of 1+2÷3✕4-5.5= should be -1.5");

        mainRoot.digitClicked(9);
        mainRoot.digitClicked(9);
        mainRoot.digitClicked(9);
        mainRoot.digitClicked(9);
        mainRoot.digitClicked(9);
        mainRoot.digitClicked(9);
        mainRoot.digitClicked(9);
        mainRoot.digitClicked(9);
        mainRoot.operatorClicked(Constants.Operator.Add);
        mainRoot.digitClicked(1);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "100\u2009000\u2009000", "Result of 99999999+1= should be 100 000 000");

        mainRoot.digitClicked(4);
        mainRoot.rootClicked();
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(5);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "10", "Result of 4√✕5= should be 10");

        mainRoot.digitClicked(2);
        mainRoot.digitClicked(3);
        mainRoot.operatorClicked(Constants.Operator.Add);
        mainRoot.operatorClicked(Constants.Operator.Add);
        mainRoot.digitClicked(1);
        mainRoot.digitClicked(2);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "35", "Result of 23++12= should be 35");

        mainRoot.digitClicked(4);
        mainRoot.digitClicked(5);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "68", "Result of 45= should be 68");

        mainRoot.digitClicked(7);
        mainRoot.digitClicked(8);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "101", "Result of 78= should be 101");

        mainRoot.digitClicked(5);
        mainRoot.operatorClicked(Constants.Operator.Subtract);
        mainRoot.operatorClicked(Constants.Operator.Subtract);
        mainRoot.digitClicked(7);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "2", "Result of 5--7= should be 2");

        mainRoot.digitClicked(2);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "-3", "Result of 2= should be -3");

        mainRoot.digitClicked(1);
        mainRoot.digitClicked(2);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(2);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "24", "Result of 12✕✕2= should be 24");

        mainRoot.digitClicked(4);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "48", "Result of 4= should be 48");

        mainRoot.digitClicked(9);
        mainRoot.operatorClicked(Constants.Operator.Divide);
        mainRoot.operatorClicked(Constants.Operator.Divide);
        mainRoot.digitClicked(4);
        mainRoot.digitClicked(5);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "5", "Result of 9÷÷45= should be 5");

        mainRoot.digitClicked(7);
        mainRoot.digitClicked(2);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "8", "Result of 72= should be 8");

        mainRoot.digitClicked(1);
        mainRoot.digitClicked(0);
        mainRoot.digitClicked(0);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(5);
        mainRoot.percentClicked();
        verify(mainRoot.result.toFormatNumber() === "5", "Result of 100×5% should be 5");

        mainRoot.digitClicked(1);
        mainRoot.digitClicked(0);
        mainRoot.digitClicked(0);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(5);
        mainRoot.percentClicked();
        mainRoot.operatorClicked(Constants.Operator.Add);
        verify(mainRoot.result.toFormatNumber() === "105", "Result of 100×5%+ should be 105");

        mainRoot.digitClicked(5);
        mainRoot.digitClicked(0);
        mainRoot.digitClicked(0);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(2);
        mainRoot.digitClicked(0);
        mainRoot.percentClicked();
        mainRoot.operatorClicked(Constants.Operator.Subtract);
        verify(mainRoot.result.toFormatNumber() === "400", "Result of 500×20%- should be 400");

        mainRoot.digitClicked(3);
        mainRoot.digitClicked(0);
        mainRoot.operatorClicked(Constants.Operator.Divide);
        mainRoot.digitClicked(6);
        mainRoot.digitClicked(0);
        mainRoot.percentClicked();
        verify(mainRoot.result.toFormatNumber() === "50", "Result of 30÷60% should be 50");

        mainRoot.digitClicked(1);
        mainRoot.digitClicked(2);
        mainRoot.operatorClicked(Constants.Operator.Subtract);
        mainRoot.digitClicked(1);
        mainRoot.digitClicked(0);
        mainRoot.percentClicked();
        verify(mainRoot.result.toFormatNumber() === "20", "Result of 12-10% should be 20");

        mainRoot.digitClicked(1);
        mainRoot.digitClicked(2);
        mainRoot.digitClicked(0);
        mainRoot.operatorClicked(Constants.Operator.Add);
        mainRoot.digitClicked(2);
        mainRoot.digitClicked(5);
        mainRoot.percentClicked();
        verify(mainRoot.result.toFormatNumber() === "160", "Result of 120+25% should be 160");

        mainRoot.operatorClicked(Constants.Operator.Subtract);
        verify(mainRoot.result.toFormatNumber() === "40", "Result of - should be 40");

        mainRoot.memoryRecallClearClicked();
        mainRoot.memoryRecallClearClicked();
        mainRoot.digitClicked(8);
        mainRoot.digitClicked(0);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(9);
        mainRoot.memoryPlusClicked();
        verify(mainRoot.result.toFormatNumber() === "720", "Result of [MRC][MRC]80✕9[M+] should be 720");

        mainRoot.digitClicked(5);
        mainRoot.digitClicked(0);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(6);
        mainRoot.memoryMinusClicked();
        verify(mainRoot.result.toFormatNumber() === "300", "Result of 50✕6[M-] should be 300");

        mainRoot.digitClicked(2);
        mainRoot.digitClicked(0);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(3);
        mainRoot.memoryPlusClicked();
        verify(mainRoot.result.toFormatNumber() === "60", "Result of 20✕3[M+] should be 60");
        mainRoot.memoryRecallClearClicked();
        verify(mainRoot.operand.toFormatNumber() === "480", "Result of [MRC] should be 480");

        mainRoot.digitClicked(2);
        mainRoot.operatorClicked(Constants.Operator.Add);
        mainRoot.digitClicked(3);
        mainRoot.clearEntryClicked();
        mainRoot.digitClicked(4);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "6", "Result of 2+3[C]4= should be 6");

        mainRoot.digitClicked(2);
        mainRoot.operatorClicked(Constants.Operator.Add);
        mainRoot.operatorClicked(Constants.Operator.Subtract);
        mainRoot.digitClicked(7);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "-5", "Result of 2+-7= should be -5");

        // 5. Clean up by destroying the created instance to avoid side effects on other tests
        appInstance.destroy();
    }

    function test_basic_calculation_calculator_B() {
        // 1. Load the main.qml file dynamically using the Loader component defined above
        let appInstance = mainAppLoader.createObject(parent);
        
        // 2. Verify that the Loader successfully created an instance of main.qml
        verify(appInstance !== null, "main.qml failed to load");
        compare(appInstance.status, Loader.Ready, "main.qml failed to load due to configuration or syntax errors");
        verify(appInstance.item !== null, "The root item inside main.qml failed to initialize");

        // 3. Access the root object inside main.qml using appInstance.item
        let mainRoot = appInstance.item;

        // 4. Test

        mainRoot.allClearClicked();
        verify(mainRoot.operand.toFormatNumber() === "0", "Result of [AC] should be 0");
        verify(mainRoot.result.toFormatNumber() === "0", "Result of [AC] should be 0");

        mainRoot.digitClicked(6);
        mainRoot.operatorClicked(Constants.Operator.Divide);
        mainRoot.digitClicked(3);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(5);
        mainRoot.operatorClicked(Constants.Operator.Add);
        mainRoot.digitClicked(2);
        mainRoot.decimalClicked();
        mainRoot.digitClicked(4);
        mainRoot.operatorClicked(Constants.Operator.Subtract);
        mainRoot.digitClicked(1);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "11.4", "Result of 6÷3✕5+2.4-1= should be 11.4");

        mainRoot.digitClicked(2);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(3);
        mainRoot.negateClicked();
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "-6", "Result of 2✕3[+/-]= should be -6");

        mainRoot.digitClicked(2);
        mainRoot.digitClicked(3);
        mainRoot.operatorClicked(Constants.Operator.Add);
        mainRoot.operatorClicked(Constants.Operator.Add);
        mainRoot.digitClicked(1);
        mainRoot.digitClicked(2);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "35", "Result of 23++12= should be 35");

        mainRoot.digitClicked(4);
        mainRoot.digitClicked(5);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "68", "Result of 45= should be 68");

        mainRoot.digitClicked(5);
        mainRoot.operatorClicked(Constants.Operator.Subtract);
        mainRoot.operatorClicked(Constants.Operator.Subtract);
        mainRoot.digitClicked(7);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "2", "Result of 5--7= should be 2");

        mainRoot.digitClicked(2);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "-3", "Result of 2= should be -3");

        mainRoot.digitClicked(1);
        mainRoot.digitClicked(2);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(2);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "24", "Result of 12✕✕2= should be 24");

        mainRoot.digitClicked(4);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "48", "Result of 4= should be 48");

        mainRoot.digitClicked(9);
        mainRoot.operatorClicked(Constants.Operator.Divide);
        mainRoot.operatorClicked(Constants.Operator.Divide);
        mainRoot.digitClicked(4);
        mainRoot.digitClicked(5);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "5", "Result of 9÷÷45= should be 5");

        mainRoot.digitClicked(7);
        mainRoot.digitClicked(2);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "8", "Result of 72= should be 8");

        mainRoot.digitClicked(2);
        mainRoot.decimalClicked();
        mainRoot.digitClicked(3);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.equalsClicked();
        mainRoot.equalsClicked();
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "27.984\u20091", "Result of 2.3✕✕=== should be 27.984 1");

        mainRoot.digitClicked(4);
        mainRoot.rootClicked();
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(5);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "10", "Result of 4√✕5= should be 10");

        mainRoot.digitClicked(2);
        mainRoot.digitClicked(0);
        mainRoot.digitClicked(0);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(5);
        mainRoot.percentClicked();
        verify(mainRoot.result.toFormatNumber() === "10", "Result of 200×5% should be 10");

        mainRoot.digitClicked(1);
        mainRoot.digitClicked(0);
        mainRoot.digitClicked(0);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(5);
        mainRoot.percentClicked();
        mainRoot.operatorClicked(Constants.Operator.Add);
        verify(mainRoot.result.toFormatNumber() === "105", "Result of 100×5%+ should be 105");

        mainRoot.digitClicked(5);
        mainRoot.digitClicked(0);
        mainRoot.digitClicked(0);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(2);
        mainRoot.digitClicked(0);
        mainRoot.percentClicked();
        mainRoot.operatorClicked(Constants.Operator.Subtract);
        verify(mainRoot.result.toFormatNumber() === "400", "Result of 500×20%- should be 400");

        mainRoot.digitClicked(3);
        mainRoot.digitClicked(0);
        mainRoot.operatorClicked(Constants.Operator.Divide);
        mainRoot.digitClicked(6);
        mainRoot.digitClicked(0);
        mainRoot.percentClicked();
        verify(mainRoot.result.toFormatNumber() === "50", "Result of 30÷60% should be 50");

        mainRoot.digitClicked(1);
        mainRoot.digitClicked(2);
        mainRoot.operatorClicked(Constants.Operator.Subtract);
        mainRoot.digitClicked(1);
        mainRoot.digitClicked(0);
        mainRoot.percentClicked();
        verify(mainRoot.result.toFormatNumber() === "20", "Result of 12-10% should be 20");

        mainRoot.digitClicked(1);
        mainRoot.digitClicked(2);
        mainRoot.digitClicked(0);
        mainRoot.operatorClicked(Constants.Operator.Add);
        mainRoot.digitClicked(2);
        mainRoot.digitClicked(5);
        mainRoot.percentClicked();
        verify(mainRoot.result.toFormatNumber() === "160", "Result of 120+25% should be 160");

        mainRoot.operatorClicked(Constants.Operator.Subtract);
        verify(mainRoot.result.toFormatNumber() === "40", "Result of - should be 40");

        mainRoot.memoryRecallClearClicked();
        mainRoot.memoryRecallClearClicked();
        mainRoot.digitClicked(8);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(9);
        mainRoot.memoryPlusClicked();
        verify(mainRoot.result.toFormatNumber() === "72", "Result of [MRC][MRC]8✕9[M+] should be 72");

        mainRoot.digitClicked(5);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(6);
        mainRoot.memoryMinusClicked();
        verify(mainRoot.result.toFormatNumber() === "30", "Result of 5✕6[M-] should be 30");

        mainRoot.digitClicked(2);
        mainRoot.operatorClicked(Constants.Operator.Multiply);
        mainRoot.digitClicked(3);
        mainRoot.memoryPlusClicked();
        verify(mainRoot.result.toFormatNumber() === "6", "Result of 2✕3[M+] should be 6");
        mainRoot.memoryRecallClearClicked();
        verify(mainRoot.operand.toFormatNumber() === "48", "Result of [MRC] should be 48");

        mainRoot.digitClicked(2);
        mainRoot.operatorClicked(Constants.Operator.Add);
        mainRoot.digitClicked(3);
        mainRoot.clearEntryClicked();
        mainRoot.digitClicked(4);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "6", "Result of 2+3[C]4= should be 6");

        mainRoot.digitClicked(2);
        mainRoot.operatorClicked(Constants.Operator.Add);
        mainRoot.operatorClicked(Constants.Operator.Subtract);
        mainRoot.digitClicked(7);
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "-5", "Result of 2+-7= should be -5");

        mainRoot.digitClicked(5);
        mainRoot.operatorClicked(Constants.Operator.Add);
        mainRoot.digitClicked(7);
        mainRoot.digitClicked(7);
        mainRoot.deleteDigit();
        mainRoot.equalsClicked();
        verify(mainRoot.result.toFormatNumber() === "12", "Result of 2+77[▶]= should be 12");

        // 5. Clean up by destroying the created instance to avoid side effects on other tests
        appInstance.destroy();
    }
}