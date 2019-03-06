@IsTest
public with sharing class ErrorLogTest {
    
    static testMethod void testBuildError() {
        Integer numErrors = 10;
        for (Integer i = 0; i < numErrors; i++) {
            ErrorLog.errors.add(new Error_Log__c(Message__c = 'test' + i));
        }
        ErrorLogException testException;
        try {
            throw new ErrorLogException('test message');
        }
        catch (ErrorLogException e) {
            testException = e;
            Test.startTest();
                ErrorLog.logError(testException);
            Test.stopTest();
        }
        System.assertNotEquals(null, testException, 'Expect an exception to have been caught');
        System.assertEquals(numErrors + 1, ErrorLog.errors.size(), 'Expect one error to be added to the queue');
        Error_Log__c log = ErrorLog.errors[ErrorLog.errors.size() - 1];
        System.assertEquals(testException.getLineNumber(), log.Line_Number__c, 'Expect the line number to be stamped on the record');
        System.assertEquals(testException.getMessage(), log.Message__c, 'Expect the message to be stamped on the record');
        System.assertEquals(testException.getTypeName(), log.Type_Name__c, 'Expect the type name to be stamped on the record');
    }

    static testMethod void testCommitErrors() {
        Integer numErrors = 10;
        for (Integer i = 0; i < numErrors; i++) {
            ErrorLog.errors.add(new Error_Log__c(Message__c = 'test' + i));
        }
        Test.startTest();
            ErrorLog.commitErrors();
        Test.stopTest();

        List<Error_Log__c> committedErrors = [SELECT Id, Message__c FROM Error_Log__c];
        System.assertEquals(numErrors, committedErrors.size(), 'Expect errors to have been committed to the database');
    }

    private class ErrorLogException extends Exception {}
}