@IsTest
public class ZeroOutAnnualContactFieldsBatchTest {
    
    static testMethod void testZeroOutValues() {
        List<Contact> contacts = TestUtilities.createContacts(5, false);
        for (Integer i = 0; i < contacts.size(); i++) {
            contacts[i].Sum_One_Time_Last_Year_Donations__c = 100 + (i * 25);
            contacts[i].Sum_Annualized_Sustaining_Donations__c = 60 + (i * 5);
            contacts[i].Sum_Inactive_Last_Year_Donations__c = 40 + (i * 12);
        }

        insert contacts;

        Test.startTest();
            Database.executeBatch(new ZeroOutAnnualContactFieldsBatch(), 200);
        Test.stopTest();

        List<Contact> updatedContacts = [SELECT Id, Sum_One_Time_Last_Year_Donations__c, Sum_Annualized_Sustaining_Donations__c,
            Sum_Inactive_Last_Year_Donations__c, Total_Annualized_Donation_Value__c FROM Contact];

        for (Contact c : updatedContacts) {
            System.assertEquals(null, c.Sum_One_Time_Last_Year_Donations__c, 'Value should be null');
            System.assertEquals(null, c.Sum_Annualized_Sustaining_Donations__c, 'Value should be null');
            System.assertEquals(null, c.Sum_Inactive_Last_Year_Donations__c, 'Value should be null');
            System.assertEquals(0.0, c.Total_Annualized_Donation_Value__c, 'Value should be zero');
        }
       
    }

    
}
