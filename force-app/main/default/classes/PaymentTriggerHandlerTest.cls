@IsTest
public class PaymentTriggerHandlerTest {
    
    @TestSetup static void setup() {
        List<Contact> testContact = TestUtilities.createContacts(1, true);
        List<Account> testAccount = TestUtilities.createAccounts(1, true);
        List<Opportunity> testOpps = TestUtilities.createOpportunities(testAccount, 10, false);
        for (Opportunity anOpp : testOpps) {
            anOpp.Is_Monthly__c = true;
            anOpp.Projected_End_Date__c = Date.today();
        }
        insert testOpps;
        List<Payment__c> testPayments = TestUtilities.createPayments(testOpps, true);
    }

    static testMethod void testFilterPayments() {
        List<Payment__c> allPayments = [SELECT Id, Opportunity__c, Status__c FROM Payment__c];
        Map<Id,Payment__c> oldMap = new Map<Id,Payment__c>(allPayments.deepClone(true, true, true));
        Set<Id> filterPaymentIds = new Set<Id>();
        for (Integer i = 0; i < allPayments.size() / 2; i++) {
            Payment__c aPayment = allPayments[i];
            aPayment.Status__c = PaymentServices.APPROVED_STATUS;
            aPayment.Post_Date__c = Date.today();
            aPayment.Scheduled_Post_Date__c = Date.today();
            filterPaymentIds.add(aPayment.Id);
        }
        Test.startTest();
            List<Payment__c> filteredPayments = PaymentTriggerHandler.filterApprovedPayments(allPayments, oldMap);
        Test.stopTest();
        
        System.assertEquals(filterPaymentIds.size(), filteredPayments.size(),
            'Expect the correct number of payments to be filtered');
        for (Payment__c aPayment : filteredPayments) {
            System.assert(filterPaymentIds.contains(aPayment.Id),
                'Expect each filtered payment to be in the expected set of filtered payments');
        }
    }

    static testMethod void testFilterPayments_notSustaining() {
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        for (Opportunity anOpp : opps) {
            anOpp.Is_Monthly__c = false;
        }
        update opps;
        List<Payment__c> allPayments = [SELECT Id, Opportunity__c, Status__c FROM Payment__c];
        Map<Id,Payment__c> oldMap = new Map<Id,Payment__c>(allPayments.deepClone(true, true, true));
        for (Integer i = 0; i < allPayments.size() / 2; i++) {
            Payment__c aPayment = allPayments[i];
            aPayment.Status__c = PaymentServices.APPROVED_STATUS;
            aPayment.Post_Date__c = Date.today();
            aPayment.Scheduled_Post_Date__c = Date.today();
        }
        Test.startTest();
            List<Payment__c> filteredPayments = PaymentTriggerHandler.filterApprovedPayments(allPayments, oldMap);
        Test.stopTest();

        System.assert(filteredPayments.isEmpty(),
            'Expect no payments to be filtered because no payments belong to a sustaining opportunity');
    }

    static testMethod void testFilterPayments_noPostDate() {
        List<Payment__c> allPayments = [SELECT Id, Opportunity__c, Status__c FROM Payment__c];
        Map<Id,Payment__c> oldMap = new Map<Id,Payment__c>(allPayments.deepClone(true, true, true));
        for (Integer i = 0; i < allPayments.size() / 2; i++) {
            Payment__c aPayment = allPayments[i];
            aPayment.Status__c = PaymentServices.APPROVED_STATUS;
            aPayment.Post_Date__c = null;
            aPayment.Scheduled_Post_Date__c = null;
        }
        Test.startTest();
            List<Payment__c> filteredPayments = PaymentTriggerHandler.filterApprovedPayments(allPayments, oldMap);
        Test.stopTest();

        System.assert(filteredPayments.isEmpty(), 'Expect no payments to be filtered because no payments have a post date');
    }

    static testMethod void testGetNewPayments() {
        List<Payment__c> allPayments = [SELECT Id, Opportunity__c, Status__c FROM Payment__c];
        for (Integer i = 0; i < allPayments.size(); i++) {
            Payment__c aPayment = allPayments[i];
            aPayment.Status__c = PaymentServices.APPROVED_STATUS;
            aPayment.Post_Date__c = Date.today().addDays(i);
            aPayment.Scheduled_Post_Date__c = Date.today().addDays(i);
        }
        
        Test.startTest();
            List<Payment__c> newPayments = PaymentTriggerHandler.getNewPayments(allPayments);
        Test.stopTest();

        System.assertEquals(allPayments.size(), newPayments.size(), 'Expect one new payment for every old payment');
        for (Integer i = 0; i < newPayments.size(); i++) {
            System.assertEquals(allPayments[i].Opportunity__c, newPayments[i].Opportunity__c,
                'Expect all new payments opportunity to correspond to the old payments opportunity');
            System.assertEquals(allPayments[i].Post_Date__c.addMonths(1), newPayments[i].Scheduled_Post_Date__c,
                'Expect all new payments scheduled post date to be one month after the old payments post date');
        }
    }

    static testMethod void testInsertNewPayments() {
        List<Payment__c> allPayments = [SELECT Id, Opportunity__c, Status__c, Amount__c FROM Payment__c];
        for (Integer i = 0; i < allPayments.size(); i++) {
            Payment__c aPayment = allPayments[i];
            aPayment.Status__c = PaymentServices.APPROVED_STATUS;
            aPayment.Post_Date__c = Date.today().addDays(i);
            aPayment.Scheduled_Post_Date__c = Date.today().addDays(i);
        }
        List<Payment__c> newPayments = PaymentTriggerHandler.getNewPayments(allPayments);
        Test.startTest();
            PaymentTriggerHandler.insertNewPayments(allPayments, newPayments);
        Test.stopTest();

        System.assert(ApexPages.getMessages().isEmpty(), 'Expect no exception to be thrown');
        System.assertEquals(allPayments.size() + newPayments.size(), [SELECT Id FROM Payment__c].size(),
            'Expect all new payments to be inserted correctly');
    }

    static testMethod void testInsertNewPayments_dmlException() {
        List<Payment__c> allPayments = [SELECT Id, Opportunity__c, Status__c, Amount__c FROM Payment__c];
        for (Integer i = 0; i < allPayments.size(); i++) {
            Payment__c aPayment = allPayments[i];
            aPayment.Status__c = PaymentServices.APPROVED_STATUS;
            aPayment.Post_Date__c = Date.today().addDays(i);
            aPayment.Scheduled_Post_Date__c = Date.today().addDays(i);
        }
        List<Payment__c> newPayments = PaymentTriggerHandler.getNewPayments(allPayments);
        insert newPayments;
        Test.startTest();
            PaymentTriggerHandler.insertNewPayments(allPayments, newPayments);
        Test.stopTest();

        System.assert(!ApexPages.getMessages().isEmpty(), 'Expect error to be added to record');

    }

    static testMethod void testFilterUpdatePayments() {
        List<Payment__c> allPayments = [SELECT Id, Opportunity__c, Status__c FROM Payment__c];
        Map<Id,Payment__c> oldMap = new Map<Id,Payment__c>(allPayments.deepClone(true, true, true));
        Set<Id> filterPaymentIds = new Set<Id>();
        for (Integer i = 0; i < allPayments.size() / 2; i++) {
            Payment__c aPayment = allPayments[i];
            aPayment.Status__c = PaymentServices.APPROVED_STATUS;
            aPayment.Post_Date__c = Date.today();
            filterPaymentIds.add(aPayment.Id);
        }
        Test.startTest();
            List<Payment__c> filteredPayments = PaymentTriggerHandler.filterUpdatedPayments(allPayments, oldMap);
        Test.stopTest();
        System.assertEquals(filterPaymentIds.size(), filteredPayments.size(),
                'Expect the correct number of payments to be filtered');
        for (Integer i = 0; i < filteredPayments.size(); i++) {
             System.assert(filterPaymentIds.contains(filteredPayments[i].Id),
                'Expect each filtered payment to be in the expected set of filtered payments');
            System.assertEquals(filteredPayments[i].Status__c, PaymentServices.APPROVED_STATUS,
                'Expect payment status should be approved');
        }
    }

    static testMethod void testUpdateMembershipProjectedEndDate() {
        List<Payment__c> allPayments = [SELECT Id, Post_Date__c, Opportunity__c, Status__c FROM Payment__c];
        List<Payment__c> paymentList = new List<Payment__c>();
        for (Integer i = 0; i < allPayments.size() / 2; i++) {
            Payment__c aPayment = allPayments[i];
            aPayment.Status__c = PaymentServices.APPROVED_STATUS;
            aPayment.Post_Date__c = Date.today();
            paymentList.add(aPayment);
        }
        update paymentList;
        Test.startTest();
            List<Opportunity> opportunityUpdate = PaymentTriggerHandler.updateOpportunityProjectedEndDate(paymentList);
        Test.stopTest();
       
        System.assertNotEquals(opportunityUpdate[0].Projected_End_Date__c, Date.today());
    }

}