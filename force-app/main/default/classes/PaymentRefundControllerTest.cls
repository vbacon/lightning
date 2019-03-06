@isTest
public with sharing class PaymentRefundControllerTest {
    static testMethod void checkPaymentChildRecordNotExistTest() {
        List<Account> testAccount = TestUtilities.createAccounts(1, true);
        List<Contact> testContact = TestUtilities.createContacts(testAccount, 1, true);
        Opportunity testOpp = TestUtilities.createOpportunities(testAccount, testContact, 1, true)[0];
        Payment__c testPayment = TestUtilities.createPayment(testOpp, false);
            testPayment.Status__c = PaymentServices.APPROVED_STATUS;
            insert testPayment;
        Test.startTest();
            Boolean refundRecordExists = PaymentRefundController.checkPaymentChildRecord(testPayment.Id);
        Test.stopTest();
        System.assert(!refundRecordExists,'We expect the payment child record does not exist.');
    }
    static testMethod void checkPaymentChildRecordExistTest() {
        List<Account> testAccount = TestUtilities.createAccounts(1, true);
        List<Contact> testContact = TestUtilities.createContacts(testAccount, 1, true);
        Opportunity testOpp = TestUtilities.createOpportunities(testAccount, testContact, 1, true)[0];
        Payment__c testPayment = TestUtilities.createPayment(testOpp, false);
            testPayment.Status__c = PaymentServices.APPROVED_STATUS;
            insert testPayment;
        Payment__c testChildPayment = new Payment__c();
            testChildPayment.Opportunity__c = testOpp.Id;
            testChildPayment.Amount__c = -10.00;
            testChildPayment.Scheduled_Post_Date__c = Date.today();
            testChildPayment.Original_Payment_Id__c = testPayment.Id;
            testChildPayment.Status__c = PaymentServices.REFUNDED_STATUS;
            insert testChildPayment;
        Test.startTest();
            Boolean refundRecordExists = PaymentRefundController.checkPaymentChildRecord(testPayment.Id);
        Test.stopTest();
        System.assert(refundRecordExists,'We expect the payment child record should exist.');
    }
    static testMethod void createRefundPaymentRecordTest() {
        List<Account> testAccount = TestUtilities.createAccounts(1, true);
        List<Contact> testContact = TestUtilities.createContacts(testAccount, 1, true);
        Opportunity testOpp = TestUtilities.createOpportunities(testAccount, testContact, 1, true)[0];
        Payment__c testPayment = TestUtilities.createPayment(testOpp, false);
        Payment__c childRec = new Payment__c();
            childRec.Status__c =  PaymentServices.REFUNDED_STATUS;
            childRec.Amount__c = -10.00;
            childRec.Opportunity__c = testOpp.Id;
        Test.startTest();
            Payment__c refundRecord = PaymentRefundController.createRefundPaymentRecord(testPayment.Id,childRec);
        Test.stopTest();
        System.assertEquals(testPayment.Id, refundRecord.Original_Payment_Id__c,'We expect the refund record has been created');
        System.assertEquals((-1 * testPayment.Amount__c), refundRecord.Amount__c, 'We expect the refund record amount to be the negative value of the parent payment');
    }
    static testMethod void refundDonationTest() {
        List<Account> testAccount = TestUtilities.createAccounts(1, true);
        List<Contact> testContact = TestUtilities.createContacts(testAccount, 1, true);
        Opportunity testOpp = TestUtilities.createOpportunities(testAccount, testContact, 1, true)[0];
        Payment__c testPayment = TestUtilities.createPayment(testOpp, false);
            testPayment.Capture_Sale_Transaction__c = '82922712172354325';
            testPayment.Status__c = PaymentServices.APPROVED_STATUS;
            insert testPayment;
        VantivUtilitiesMock theMock = new VantivUtilitiesMock();
        Test.setMock(HttpCalloutMock.class, theMock);
        Test.startTest();
            Payment__c refundRecord = PaymentRefundController.refundDonation(testPayment.Id);
        Test.stopTest();
        System.assertEquals(testPayment.Id, refundRecord.Original_Payment_Id__c,'We expect the refund record has been created.');
        System.assertEquals((-1 * testPayment.Amount__c), refundRecord.Amount__c, 'We expect the refund record amount to be the negative value of the parent payment');
        System.assertEquals(PaymentServices.REFUNDED_STATUS, refundRecord.Status__c,'We expect the refund record status should be Refunded.');
    }
}