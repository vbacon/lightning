@isTest
public class DonationFormPaymentBatchTest {
    static testMethod void batchTestMethod() {
        List<Account> testAccount = TestUtilities.createAccounts(1, true);
        List<Contact> testContact = TestUtilities.createContacts(testAccount, 1, true);
        Opportunity testOpp = TestUtilities.createOpportunities(testAccount, testContact, 1, false)[0];
        testOpp.Worldpay_Token__c = '1234123412341234';
        insert testOpp;
        Payment__c testPayment = TestUtilities.createPayment(testOpp, false);
            testPayment.Status__c = 'Pending';
            testPayment.Scheduled_Post_Date__c = Date.today();
        insert testPayment;

        Test.setMock(HttpCalloutMock.class, new VantivUtilitiesMock());
        DonationFormPaymentBatch paymentBatch = new DonationFormPaymentBatch();

        Test.startTest();
            Database.executeBatch(paymentBatch,2);
        Test.stopTest();

        Payment__c updatedPayment = [SELECT Id, Status__c, Amount__c FROM Payment__c WHERE Id = :testPayment.Id];
        System.assertEquals(PaymentServices.APPROVED_STATUS, updatedPayment.Status__c, 'Expect payment to be processed and approved');
    }

    static testMethod void testDatabaseFailure() {
        List<Account> testAccount = TestUtilities.createAccounts(1, true);
        List<Contact> testContact = TestUtilities.createContacts(testAccount, 1, true);
        Opportunity testOpp = TestUtilities.createOpportunities(testAccount, testContact, 1, true)[0];
        Payment__c testPayment = TestUtilities.createPayment(testOpp, false);
            testPayment.Status__c = 'Pending';
            testPayment.Scheduled_Post_date__c = Date.today();
        insert testPayment;

        Test.setMock(HttpCalloutMock.class, new VantivUtilitiesMock());
        DonationFormPaymentBatch paymentBatch = new DonationFormPaymentBatch();
        paymentBatch.failedList.add(testAccount[0].Id);

        Test.startTest();
            Database.executeBatch(paymentBatch,2);
        Test.stopTest();

        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];

        System.assertEquals(1, errorLogs.size(), 'Should have one error log created');
    }
}
