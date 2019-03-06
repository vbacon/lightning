@IsTest
public with sharing class ContactUtilitiesTest {
 
    @testSetup static void setup() {

        Member_Benefit__c mb1 = new Member_Benefit__c (Name = 'Benefit 1', Description__c = 'Benefit 1');
        Member_Benefit__c mb2 = new Member_Benefit__c (Name = 'Benefit 2', Description__c = 'Benefit 2');
        insert new List<Member_Benefit__c>{mb1, mb2};            
        
        Member_Level__c ml1 = new Member_Level__c (Name = 'Level 1', Member_Level_Value__c = 100);
        Member_Level__c ml2 = new Member_Level__c (Name = 'Level 1', Member_Level_Value__c = 200);
        insert new List<Member_Level__c>{ml1, ml2};            
        
        Member_Benefit_Level__c mbl1 = new Member_Benefit_Level__c(Member_Benefit__c = mb1.Id, Member_Level__c = ml1.Id);
        Member_Benefit_Level__c mbl2 = new Member_Benefit_Level__c(Member_Benefit__c = mb2.Id, Member_Level__c = ml2.Id);
        insert new List<Member_Benefit_Level__c>{mbl1, mbl2};   

    }
    
    static testMethod void testMemberLevelString_1() {
        
        List<Account> accounts = TestUtilities.createAccounts(1, true);
        List<Contact> contacts = TestUtilities.createContacts(accounts, 1, true);
        contacts[0].Sum_Annualized_Sustaining_Donations__c = 75;

        Test.startTest();
            update contacts;
        Test.stopTest();

        List<Contact> updatedContacts1 = [SELECT Id, Membership_Benefits__c FROM Contact];
        for (Contact c : updatedContacts1) {
            System.assertEquals(null, c.Membership_Benefits__c, 'Value should be null.');
        }        
 
    }

    static testMethod void testMemberLevelString_2() {

        List<Account> accounts = TestUtilities.createAccounts(1, true);
        List<Contact> contacts = TestUtilities.createContacts(accounts, 1, true);
        contacts[0].Sum_Annualized_Sustaining_Donations__c = 150;

        Test.startTest();
            update contacts;
        Test.stopTest();

        List<Contact> updatedContacts2 = [SELECT Id, Membership_Benefits__c FROM Contact];
        for (Contact c : updatedContacts2) {
            System.assertEquals('Benefit 1', c.Membership_Benefits__c, 'Value should be \'Benefit 1\'.');
        }
 
    }

    static testMethod void testMemberLevelString_3() {

        List<Account> accounts = TestUtilities.createAccounts(1, true);
        List<Contact> contacts = TestUtilities.createContacts(accounts, 1, true);
        contacts[0].Sum_Annualized_Sustaining_Donations__c = 225;
        
        Test.startTest();
            update contacts;
        Test.stopTest();

        List<Contact> updatedContacts3 = [SELECT Id, Membership_Benefits__c FROM Contact];
        for (Contact c : updatedContacts3) {
            System.assertEquals('Benefit 2', c.Membership_Benefits__c, 'Value should be \'Benefit 2\'.');
        }        
 
    }
   
    static testMethod void testRecalcValues() {
        
        List<Account> accounts = TestUtilities.createAccounts(1, true);
        List<Contact> contacts = TestUtilities.createContacts(accounts, 1, true);
        
        // Opp 0 will be a one time donation of $100
        // Opp 1 will be an active recurring donation of $15 monthly ($180 annualized)
        // Opp 2 will be an inactive recurring donation with one $50 payment
        // Opp 3 has a Cancelled payment which should not be counted.
        // Opp 4 has a 15 month old payment that should not be counted.
        
        List<Opportunity> opps = TestUtilities.createOpportunities(contacts, 5, false);
        for (Opportunity opp : opps ) {
          opp.Membership_Active__c = true;
          opp.CloseDate = Date.today().addMonths(-2);
        }
        opps[0].Is_Monthly__c = false;
        opps[1].Is_Monthly__c = true;
        opps[2].Is_Monthly__c = true;
        opps[2].Membership_Active__c = false;
        opps[3].Is_Monthly__c = false;
        opps[4].Is_Monthly__c = false;
        opps[4].CloseDate = Date.today().addMonths(-15);

        opps[0].Initial_Payment_Amount__c = 100;
        opps[1].Initial_Payment_Amount__c = 15;
        opps[2].Initial_Payment_Amount__c = 50;        
        opps[3].Initial_Payment_Amount__c = 200;
        opps[4].Initial_Payment_Amount__c = 75;
        insert opps;

        List<Payment__c> payments = TestUtilities.createPayments(opps, false);
        for (Payment__c payment : payments ) {
          payment.Status__c = PaymentServices.APPROVED_STATUS;
          payment.Post_Date__c = Date.today().addMonths(-2);
        }
        payments[0].Amount__c = 100;
        payments[1].Amount__c = 15;
        payments[2].Amount__c = 50;
        payments[3].Amount__c = 200;
        payments[4].Amount__c = 75;
        payments[3].Status__c = PaymentServices.CANCELLED_STATUS;
        payments[4].Post_Date__c = Date.today().addMonths(-15);
        insert payments;

        Test.startTest();
            ContactUtilities.recalcAnnualDonationValues(opps);
        Test.stopTest();

        List<Contact> updatedContacts = [SELECT Id, Sum_One_Time_Last_Year_Donations__c, 
            Sum_Annualized_Sustaining_Donations__c, Sum_Inactive_Last_Year_Donations__c,
            Total_Annualized_Donation_Value__c
            FROM Contact];

        for (Contact c : updatedContacts) {
            System.assertEquals(330, c.Total_Annualized_Donation_Value__c, 'Value should be 330'); // 100 + 180 + 50
        }

    } 

}

