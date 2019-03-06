@IsTest
public with sharing class DonationCancelControllerTest {
    
    public static testMethod void testCancelDonation() {
        List<Contact> testContact = TestUtilities.createContacts(1, true);
        testContact = [SELECT Id, AccountId FROM Contact WHERE Id = :testContact];
        Opportunity testOpp = TestUtilities.createOpportunities(testContact, 1, false)[0];
        testOpp.End_Reason__c = null;
        testOpp.Membership_Active__c = true;
        testOpp.Membership_Tier__c = MembershipUtilities.MEMBERSHIP_TIER_BASIC;
        insert testOpp;
        Payment__c processedPayment = TestUtilities.createPayment(testOpp, false);
        processedPayment.Status__c = PaymentServices.APPROVED_STATUS;
        Payment__c pendingPayment = TestUtilities.createPayment(testOpp, false);
        Test.startTest();
            DonationCancelController.cancelDonation(new Opportunity(Id = testOpp.Id));
        Test.stopTest();

        Opportunity requeriedOpp = [SELECT Id, End_Reason__c, Is_Cancelled__c,
                                        (SELECT Id, Status__c FROM Payments__r)
                                    FROM Opportunity WHERE Id = :testOpp.Id];
        System.assert(requeriedOpp.Is_Cancelled__c, 'Expect the opportunity to be cancelled');
        System.assertEquals(MembershipUtilities.END_REASON_CANCELLED, requeriedOpp.End_Reason__c, 'Expect the end reason to be set to cancelled');
        for (Payment__c aPayment : requeriedOpp.Payments__r) {
            if (aPayment.Id == processedPayment.Id) {
                System.assertEquals(processedPayment.Status__c, aPayment.Status__c, 'Expect the status of a non-pending payment to remain unchanged');
            }
            else {
                System.assertEquals(PaymentServices.CANCELLED_STATUS, aPayment.Status__c, 'Expect the status of a pending payment to change to cancelled');
            }
        }
    }

    public static testMethod void testGetDonation() {
        List<Contact> testContact = TestUtilities.createContacts(1, true);
        testContact = [SELECT Id, AccountId FROM Contact WHERE Id = :testContact];
        Opportunity testOpp = TestUtilities.createOpportunities(testContact, 1, false)[0];
        insert testOpp;

        Test.startTest();
            DonationCancelController.getDonation(testOpp.Id);
        Test.stopTest();

        Opportunity requeriedOpp = [SELECT Id, End_Reason__c, Is_Cancelled__c
                                    FROM Opportunity WHERE Id = :testOpp.Id];

        System.assertNotEquals(null, requeriedOpp.Id, 'Opp Id should not be null.');
        System.assert(!requeriedOpp.Is_Cancelled__c, 'Expect the opportunity to not be cancelled');
    }
    
}
