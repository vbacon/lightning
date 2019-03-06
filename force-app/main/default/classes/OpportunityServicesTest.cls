@IsTest
public class OpportunityServicesTest {
    //TODO: FIX THIS TESTMETHOD
    public static testMethod void testCancelMembership() {
        Contact testContact = TestUtilities.createContacts(1, true)[0];
        testContact = [SELECT Id, AccountId FROM Contact WHERE Id = :testContact.Id];
        Opportunity testOpp = TestUtilities.createOpportunities(new List<Contact>{testContact}, 1, true)[0];
        Payment__c completedPayment = TestUtilities.createPayment(testOpp, false);
        Payment__c pendingPayment = TestUtilities.createPayment(testOpp, false);
        completedPayment.Status__c = PaymentServices.APPROVED_STATUS;
        completedPayment.Worldpay_Order_Id__c = 'uniquevalue0';
        List<Payment__c> allPayments = new List<Payment__c>{completedPayment, pendingPayment};
        insert allPayments;

        Test.startTest();
            Opportunity returnedOpp = OpportunityServices.cancelDonation(testOpp);
        Test.stopTest();

        List<Payment__c> requeriedPayments = [SELECT Status__c FROM Payment__c WHERE Id IN :allPayments];
        
        System.assert(returnedOpp.Is_Cancelled__c, 'Expect the returned opportunity to have been cancelled');
        System.assertEquals(MembershipUtilities.END_REASON_CANCELLED, returnedOpp.End_Reason__c, 'Expect cancelled donations end reason to reflect that it was cancelled');
        System.assertEquals(allPayments.size(), requeriedPayments.size(), 'No payments should have been deleted');
        for (Payment__c aPayment : requeriedPayments) {
            if (aPayment.Id == completedPayment.Id) {
                System.assertEquals(PaymentServices.APPROVED_STATUS, aPayment.Status__c, 'Expect non-pending payments to not have their status updated');
            }
            else {
                System.assertEquals(PaymentServices.CANCELLED_STATUS, aPayment.Status__c, 'Expect pending payments to have their status updated from pending to cancelled');
            }
        }
    }
}