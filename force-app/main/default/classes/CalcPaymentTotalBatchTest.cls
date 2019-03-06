@IsTest
public class CalcPaymentTotalBatchTest {
    
    static testMethod void testOneTimeDonationPayments() {
        
        List<Account> accounts = TestUtilities.createAccounts(1, true);
        List<Contact> contacts = TestUtilities.createContacts(accounts, 1, true);
        
        List<Opportunity> opps = TestUtilities.createOpportunities(contacts, 5, false);
        for (Opportunity opp : opps ) {
          opp.Is_Monthly__c = false;
          opp.Membership_Active__c = true;
          opp.CloseDate = Date.today().addMonths(-2);
        }
        opps[0].Initial_Payment_Amount__c = 100;
        opps[1].Initial_Payment_Amount__c = 200;
        opps[2].Initial_Payment_Amount__c = 300;        
        opps[3].Initial_Payment_Amount__c = 400;
        opps[3].Initial_Payment_Amount__c = 500;
        opps[4].CloseDate = Date.today().addMonths(-14);
        insert opps;

        List<Payment__c> payments = TestUtilities.createPayments(opps, false);
        for (Payment__c payment : payments ) {
          payment.Status__c = PaymentServices.APPROVED_STATUS;
        }
        payments[0].Amount__c = 100;  // Should be counted
        payments[1].Amount__c = 200;  // Should be counted
        payments[2].Amount__c = 300;  // Should be counted
        payments[3].Amount__c = 400;  // Will have Cancelled status
        payments[4].Amount__c = 500;  // Will be more than a year old
        payments[3].Status__c = PaymentServices.CANCELLED_STATUS;
        insert payments;

        Test.startTest();
            Database.executeBatch(new ZeroOutAnnualContactFieldsBatch(), 200);
        Test.stopTest();

        List<Contact> updatedContacts = [SELECT Id, Sum_One_Time_Last_Year_Donations__c
             FROM Contact];

        for (Contact c : updatedContacts) {
            System.assertEquals(600, c.Sum_One_Time_Last_Year_Donations__c, 'Value should be 600');
        }
   
    }

    static testMethod void testInactiveRecurringPayments() {
        
        List<Account> accounts = TestUtilities.createAccounts(1, true);
        List<Contact> contacts = TestUtilities.createContacts(accounts, 1, true);

        List<Opportunity> opps = TestUtilities.createOpportunities(contacts, 1, false);
        for (Opportunity opp : opps ) {
          opp.Is_Monthly__c = true;
          opp.Membership_Active__c = false;
          opp.CloseDate = Date.today().addMonths(-2);
        }
        opps[0].Initial_Payment_Amount__c = 15;
        insert opps;        
                
        List<Payment__c> payments1 = TestUtilities.createPayments(opps, false);
        payments1[0].Status__c = PaymentServices.APPROVED_STATUS;
        payments1[0].Amount__c = 15;
        insert payments1;

        List<Payment__c> payments2 = TestUtilities.createPayments(opps, false);
        payments2[0].Status__c = PaymentServices.APPROVED_STATUS;
        payments2[0].Amount__c = 15;
        payments2[0].Worldpay_Order_Id__c = 'abcdefghi123472141814';
        insert payments2;

        List<Payment__c> payments3 = TestUtilities.createPayments(opps, false);
        payments3[0].Status__c = PaymentServices.APPROVED_STATUS;
        payments3[0].Amount__c = 15;
        payments3[0].Worldpay_Order_Id__c = 'abcdefghi123412341814';        
        insert payments3;

        List<Payment__c> payments4 = TestUtilities.createPayments(opps, false);
        payments4[0].Status__c = PaymentServices.CANCELLED_STATUS;
        payments4[0].Amount__c = 15;
        payments4[0].Worldpay_Order_Id__c = 'abcdefghi1491531814';        
        insert payments4;

        Test.startTest();
            Database.executeBatch(new ZeroOutAnnualContactFieldsBatch(), 200);
        Test.stopTest();

        List<Contact> updatedContacts = [SELECT Id, Sum_Inactive_Last_Year_Donations__c
             FROM Contact];

        for (Contact c : updatedContacts) {
            System.assertEquals(45, c.Sum_Inactive_Last_Year_Donations__c, 'Value should be 45');
        }
    }

    static testMethod void testBothTypesOfPayments() {
        
        List<Account> oneTimeAccounts = TestUtilities.createAccounts(1, true);
        List<Contact> oneTimeContacts = TestUtilities.createContacts(oneTimeAccounts, 1, false);
        oneTimeContacts[0].lastName = 'One Time';
        oneTimeContacts[0].email = 'onetime@test.com';
        insert oneTimeContacts;
        
        List<Opportunity> oneTimeOpps = TestUtilities.createOpportunities(oneTimeContacts, 5, false);
        for (Opportunity opp : oneTimeOpps ) {
          opp.Is_Monthly__c = false;
          opp.Membership_Active__c = true;
          opp.CloseDate = Date.today().addMonths(-2);
        }
        oneTimeOpps[0].Initial_Payment_Amount__c = 100;
        oneTimeOpps[1].Initial_Payment_Amount__c = 200;
        oneTimeOpps[2].Initial_Payment_Amount__c = 300;        
        oneTimeOpps[3].Initial_Payment_Amount__c = 400;
        oneTimeOpps[3].Initial_Payment_Amount__c = 500;
        oneTimeOpps[4].CloseDate = Date.today().addMonths(-14);
        insert oneTimeOpps;

        List<Payment__c> oneTimePayments = TestUtilities.createPayments(oneTimeOpps, false);
        for (Payment__c payment : oneTimePayments ) {
          payment.Status__c = PaymentServices.APPROVED_STATUS;
        }
        oneTimePayments[0].Amount__c = 100;  // Should be counted
        oneTimePayments[1].Amount__c = 200;  // Should be counted
        oneTimePayments[2].Amount__c = 300;  // Should be counted
        oneTimePayments[3].Amount__c = 400;  // Will have Cancelled status
        oneTimePayments[4].Amount__c = 500;  // Will be more than a year old
        oneTimePayments[3].Status__c = PaymentServices.CANCELLED_STATUS;
        insert oneTimePayments;

        List<Account> inactiveAccounts = TestUtilities.createAccounts(1, true);
        List<Contact> inactiveContacts = TestUtilities.createContacts(inactiveAccounts, 1, false);
        inactiveContacts[0].lastName = 'Inactive';
        inactiveContacts[0].email = 'inactive@test.com';
        inactiveContacts[0].MailingPostalCode = '12345';        
        insert inactiveContacts;

        List<Opportunity> inactiveOpps = TestUtilities.createOpportunities(inactiveContacts, 1, false);
        for (Opportunity opp : inactiveOpps ) {
          opp.Is_Monthly__c = true;
          opp.Membership_Active__c = false;
          opp.CloseDate = Date.today().addMonths(-2);
        }
        inactiveOpps[0].Initial_Payment_Amount__c = 15;
        insert inactiveOpps;        
                
        List<Payment__c> inactivePayment1 = TestUtilities.createPayments(inactiveOpps, false);
        inactivePayment1[0].Status__c = PaymentServices.APPROVED_STATUS;
        inactivePayment1[0].Amount__c = 15;
        inactivePayment1[0].Worldpay_Order_Id__c = 'abcdefdrt1239438275414';
        insert inactivePayment1;

        List<Payment__c> inactivePayment2 = TestUtilities.createPayments(inactiveOpps, false);
        inactivePayment2[0].Status__c = PaymentServices.APPROVED_STATUS;
        inactivePayment2[0].Amount__c = 15;
        inactivePayment2[0].Worldpay_Order_Id__c = 'abcdefghi123472141814';
        insert inactivePayment2;

        List<Payment__c> inactivePayment3 = TestUtilities.createPayments(inactiveOpps, false);
        inactivePayment3[0].Status__c = PaymentServices.APPROVED_STATUS;
        inactivePayment3[0].Amount__c = 15;
        inactivePayment3[0].Worldpay_Order_Id__c = 'abcdefghi123412341814';        
        insert inactivePayment3;

        List<Payment__c> inactivePayment4 = TestUtilities.createPayments(inactiveOpps, false);
        inactivePayment4[0].Status__c = PaymentServices.CANCELLED_STATUS;
        inactivePayment4[0].Amount__c = 15;
        inactivePayment4[0].Worldpay_Order_Id__c = 'abcdefghi1491531814';        
        insert inactivePayment4;

        Test.startTest();
            Database.executeBatch(new ZeroOutAnnualContactFieldsBatch(), 200);
        Test.stopTest();

        List<Contact> updatedOneTimeContacts = [SELECT Id, Sum_One_Time_Last_Year_Donations__c,
             Sum_Inactive_Last_Year_Donations__c FROM Contact WHERE lastName = 'One Time'];

        System.assertEquals(1, updatedOneTimeContacts.size(), 'There should be one updated one time Contact.');
        for (Contact c : updatedOneTimeContacts) {
            System.assertEquals(600, c.Sum_One_Time_Last_Year_Donations__c, 'Value should be 600');
            System.assertEquals(null, c.Sum_Inactive_Last_Year_Donations__c, 'Value should be null');
        }

        List<Contact> updatedInactiveContacts = [SELECT Id, Sum_One_Time_Last_Year_Donations__c,
             Sum_Inactive_Last_Year_Donations__c FROM Contact WHERE lastName = 'Inactive'];

        System.assertEquals(1, updatedInactiveContacts.size(), 'There should be one updated inactive Contact.');
        for (Contact c : updatedInactiveContacts) {
            System.assertEquals(null, c.Sum_One_Time_Last_Year_Donations__c, 'Value should be null');
            System.assertEquals(45, c.Sum_Inactive_Last_Year_Donations__c, 'Value should be 45');
        }
    }

}


