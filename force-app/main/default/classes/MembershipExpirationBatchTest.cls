@IsTest
public class MembershipExpirationBatchTest {
    
    static testMethod void testMembershipExpirationBatch() {
        List<Account> accounts = TestUtilities.createAccounts(5, true);
        List<Contact> contacts = TestUtilities.createContacts(accounts, 1, true);
        contacts = [SELECT Id, AccountId FROM Contact];
        List<Opportunity> activeOpps = TestUtilities.createOpportunities(contacts, 1, false);
        for (Integer i = 0; i < activeOpps.size(); i++) {
            activeOpps[i].Is_Monthly__c = (Math.mod(i, 2) == 0);
            activeOpps[i].Membership_Active__c = true;
            activeOpps[i].Projected_End_Date__c = Date.today() + 5;
        }
        List<Opportunity> oppsToExpire = TestUtilities.createOpportunities(contacts, 1, false);
        for (Integer i = 0; i < oppsToExpire.size(); i++) {
            oppsToExpire[i].Is_Monthly__c = (Math.mod(i, 2) == 0);
            oppsToExpire[i].Membership_Active__c = true;
            oppsToExpire[i].Projected_End_Date__c = Date.today() - 5;
        }
        List<Opportunity> allOpps = new List<Opportunity>(activeOpps);
        allOpps.addAll(oppsToExpire);
        insert allOpps;

        Test.startTest();
            Database.executeBatch(new MembershipExpirationBatch(), 200);
        Test.stopTest();

        List<Opportunity> updatedActiveOpps = [SELECT Id, Membership_Active__c, Is_Monthly__c, End_Reason__c, Actual_End_Date__c, Projected_End_Date__c
                                                            FROM Opportunity WHERE Id IN :activeOpps];
        List<Opportunity> updatedOppsToExpire = [SELECT Id, Membership_Active__c, Is_Monthly__c, End_Reason__c, Actual_End_Date__c, Projected_End_Date__c
                                                            FROM Opportunity WHERE Id IN :oppsToExpire];
        for (Opportunity anOpp : updatedActiveOpps) {
            System.assertEquals(null, anOpp.Actual_End_Date__c,
                'Expect Opporunities whose projected end dates are not in the past to not have an actual end date');
            System.assertEquals(true, anOpp.Membership_Active__c,
                'Expect Opporunities whose projected end dates are not in the past to have their membership active flag be checked');
         }
        for (Opportunity anOpp : updatedOppsToExpire) {
            System.assertNotEquals(null, anOpp.Actual_End_Date__c,
                'Expect Opporunities that expired to have an actual end date');
            System.assertEquals(false, anOpp.Membership_Active__c,
                'Expect opportunities that expire to have a membership_active of false');
            if (anOpp.Is_Monthly__c) {
                System.assertEquals(MembershipUtilities.END_REASON_SUSTAINER_DEFAULT, anOpp.End_Reason__c,
                    'Expect the opps end reason to reflect the default for sustainer opportunities');
            }
            else {
                System.assertEquals(MembershipUtilities.END_REASON_ONE_TIME_DEFAULT, anOpp.End_Reason__c,
                    'Expect the opps end reason to reflect the default for one time opportunities');
            }
        }

        
    }

    static testMethod void testDatabaseFailure() {
        List<Account> accounts = TestUtilities.createAccounts(5, true);
        List<Contact> contacts = TestUtilities.createContacts(accounts, 1, true);
        contacts = [SELECT Id, AccountId FROM Contact];
        
        List<Opportunity> activeOpps = TestUtilities.createOpportunities(contacts, 1, false);
        for (Integer i = 0; i < activeOpps.size(); i++) {
            activeOpps[i].Is_Monthly__c = (Math.mod(i, 2) == 0);
            activeOpps[i].Membership_Active__c = true;
            activeOpps[i].Projected_End_Date__c = Date.today() + 5;
        }
        List<Opportunity> oppsToExpire = TestUtilities.createOpportunities(contacts, 1, false);
        for (Integer i = 0; i < oppsToExpire.size(); i++) {
            oppsToExpire[i].Is_Monthly__c = (Math.mod(i, 2) == 0);
            oppsToExpire[i].Membership_Active__c = true;
            oppsToExpire[i].Projected_End_Date__c = Date.today() - 5;
        }
        List<Opportunity> allOpps = new List<Opportunity>(activeOpps);
        allOpps.addAll(oppsToExpire);
        insert allOpps;

        MembershipExpirationBatch meb = new MembershipExpirationBatch();
        meb.failedMembershipReasons.add('Test reason');

        Test.startTest();
            Database.executeBatch(meb, 200);
        Test.stopTest();

        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];

        System.assertEquals(1, errorLogs.size(), 'Should have one error log created');
        
    }
}