@IsTest
public with sharing class UtilitiesTest {

    static testMethod void addTwoRealValues() {

        Decimal A = 10.5;
        Decimal B = 9.5;
        Decimal C;

        Test.startTest();
            C = Utilities.add(A, B);
        Test.stopTest();

        System.assertEquals(20.0, C, 'Value should be 20.0');

    }

    static testMethod void addOneNullOneReal() {

        Decimal a = 10.5;
        Decimal b;
        Decimal c;

        Test.startTest();
            c = Utilities.add(a, b);
        Test.stopTest();

        System.assertEquals(10.5, c, 'Value should be 10.5');

    }

    static testMethod void addTwoNulls() {

        Decimal a;
        Decimal b;
        Decimal c;

        Test.startTest();
            c = Utilities.add(a, b);
        Test.stopTest();

        System.assertEquals(null, c, 'Value should be null');

    }


}
