@IsTest
public class CalcOpportunityTotalBatchTest {
    
    static testMethod void testActiveRecurDonationTotal() {
        
        List<Account> accounts = TestUtilities.createAccounts(1, true);
        List<Contact> contacts = TestUtilities.createContacts(accounts, 1, true);

        List<Opportunity> opps = TestUtilities.createOpportunities(contacts, 3, false);
        for (Opportunity opp : opps ) {
          opp.Is_Monthly__c = true;
          opp.Membership_Active__c = true;
          opp.CloseDate = Date.today().addMonths(-2);
        }
        opps[0].Initial_Payment_Amount__c = 15;
        opps[1].Initial_Payment_Amount__c = 25;
        opps[2].Initial_Payment_Amount__c = 10;
        opps[2].Membership_Active__c = false; // Testing an Opp that isn't active.       
        insert opps;        

        Test.startTest();
            Database.executeBatch(new ZeroOutAnnualContactFieldsBatch(), 200);
        Test.stopTest();

        List<Contact> updatedContacts = [SELECT Id, Sum_Annualized_Sustaining_Donations__c
             FROM Contact];

        for (Contact c : updatedContacts) {
            System.assertEquals(480, c.Sum_Annualized_Sustaining_Donations__c, 'Value should be 480');
        }
        
    }
   
}


