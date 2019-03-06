@IsTest
public class MembershipUtilitiesTest {

    static List<Opportunity> theOpps;
    static Opportunity basicOTOpp;
    static Opportunity basicMonthlyOpp;
    static Opportunity leadershipOTOpp;
    static Opportunity leadershipMonthlyOpp;
    static Opportunity leadershipOTOpp2;

    static void createInitialData() {

        List<Account> myAccounts = TestUtilities.createAccounts(5, true);
        List<Contact> myContacts = TestUtilities.createContacts(myAccounts, 1, true);
        theOpps = TestUtilities.createOpportunities(myContacts, 1, false);

        theOpps[0].Name = 'Basic, One-Time Donation';
        theOpps[0].Initial_Payment_Amount__c = MembershipUtilities.MINIMUM_OT_LEADERSHIP > 10 ? MembershipUtilities.MINIMUM_OT_LEADERSHIP - 5 : 5;
        theOpps[0].Membership_Tier__c = MembershipUtilities.MEMBERSHIP_TIER_BASIC;
        theOpps[0].Is_Monthly__c = false;

        theOpps[1].Name = 'Basic, Monthly Donation';
        theOpps[1].Initial_Payment_Amount__c = MembershipUtilities.MINIMUM_SG_LEADERSHIP > 5 ? MembershipUtilities.MINIMUM_OT_LEADERSHIP - 2 : 3;
        theOpps[1].Membership_Tier__c = MembershipUtilities.MEMBERSHIP_TIER_BASIC;
        theOpps[1].Is_Monthly__c = true;

        theOpps[2].Name = 'Leadership, One-Time Donation';
        theOpps[2].Initial_Payment_Amount__c = MembershipUtilities.MINIMUM_OT_LEADERSHIP + 100;
        theOpps[2].Membership_Tier__c = MembershipUtilities.MEMBERSHIP_TIER_LEADERSHIP;
        theOpps[2].Is_Monthly__c = false;

        theOpps[3].Name = 'Leadership, Monthly Donation';
        theOpps[3].Initial_Payment_Amount__c = MembershipUtilities.MINIMUM_SG_LEADERSHIP + 10;
        theOpps[3].Membership_Tier__c = MembershipUtilities.MEMBERSHIP_TIER_LEADERSHIP;
        theOpps[3].Is_Monthly__c = true;

        theOpps[4].Name = 'Leadership, One-Time Donation (2)';
        theOpps[4].Initial_Payment_Amount__c = MembershipUtilities.MINIMUM_OT_LEADERSHIP + 100;
        theOpps[4].Membership_Tier__c = MembershipUtilities.MEMBERSHIP_TIER_LEADERSHIP;
        theOpps[4].Is_Monthly__c = false;

        insert theOpps;

        basicOTOpp = theOpps[0];
        basicMonthlyOpp = theOpps[1];
        leadershipOTOpp = theOpps[2];
        leadershipMonthlyOpp = theOpps[3];
        leadershipOTOpp2 = theOpps[4];
        
    }

    static testMethod void testExpireOpportunityMembership() {

        createInitialData();
        
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        
        Test.startTest();
            MembershipUtilities.expireOpportunityMembership(basicOTOpp);
            MembershipUtilities.expireOpportunityMembership(basicMonthlyOpp);
            oppsToUpdate.add(basicOTOpp);    
            oppsToUpdate.add(basicMonthlyOpp);
            update oppsToUpdate;    
        Test.stopTest();

        Opportunity basicOTOppUpdated = [SELECT Id, Name, End_Reason__c FROM Opportunity WHERE Name = 'Basic, One-Time Donation'];
        Opportunity basicMonthlyOppUpdated = [SELECT Id, Name, End_Reason__c FROM Opportunity WHERE Name = 'Basic, Monthly Donation'];

        System.assertEquals(MembershipUtilities.END_REASON_ONE_TIME_DEFAULT, basicOTOppUpdated.End_Reason__c,
            'The end reason should now be the default value for one time donations.');
        System.assertEquals(MembershipUtilities.END_REASON_SUSTAINER_DEFAULT, basicMonthlyOppUpdated.End_Reason__c,
            'The end reason should now be the default value for sustaining donations.');
    }    

    // static testMethod void testRecalculateContactMembershipTier() {

    //     createInitialData();

    //     Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, Membership_Tier__c, AccountId FROM Contact]);
        
    //     Contact basicOTCont = contactMap.get(basicOTOpp.Contact__c);
    //     Contact basicMonthlyCont = contactMap.get(basicMonthlyOpp.Contact__c); 
    //     Contact leadershipOTCont = contactMap.get(leadershipOTOpp.Contact__c);
    //     Contact leadershipMonthlyCont = contactMap.get(leadershipMonthlyOpp.Contact__c);
    //     Contact leadershipOTCont2 = contactMap.get(leadershipOTOpp2.Contact__c); 

    //     Account basicOTAcct = [SELECT Id FROM Account WHERE Id = :basicOTCont.AccountId];

    //     Set<Id> contactIds = new Set<Id>();
        
    //     contactIds.add(basicOTCont.Id);
    //     contactIds.add(basicMonthlyCont.Id);
    //     contactIds.add(leadershipOTCont.Id);
    //     contactIds.add(leadershipMonthlyCont.Id);
    //     contactIds.add(leadershipOTCont2.Id);

    //     List <Opportunity> oppsToUpdate = new List<Opportunity>();

    //     // TEST 1 - Cause the "basic OT Contact" to become leadership by having them make a second, big donation
    //     Opportunity newBigOpp = new Opportunity(Account = basicOTAcct, Initial_Payment_Amount__c = 500, Contact__c = basicOTCont.Id,
    //         StageName = 'Closed Won', CloseDate = Date.today(), Name = 'New Big Opp 1', 
    //                 Membership_Active__c = true, Membership_Tier__c = MembershipUtilities.MEMBERSHIP_TIER_LEADERSHIP);
    //     insert newBigOpp;

    //     // TEST 2 - Change the amount of the Opportunity associated with the "basic Monthly Contact" to make it a leadership Opportunity
    //     basicMonthlyOpp.Initial_Payment_Amount__c = 30;
    //     basicMonthlyOpp.Membership_Tier__c = MembershipUtilities.MEMBERSHIP_TIER_LEADERSHIP;
    //     oppsToUpdate.add(basicMonthlyOpp);

    //     // TEST 3 - Remove the Opportunity associated with the "leadership OT Contact" so that they have no Opportunities.
    //     delete leadershipOTOpp;  // i.e. set associated Contact back to no membership level.

    //     // TEST 4 - Deactivate the Opportunity associated with the "leadership Monthly Contact" so that they have no Active Opportunities.
    //     leadershipMonthlyOpp.Membership_Active__c = false;
    //     oppsToUpdate.add(leadershipMonthlyOpp);

    //     // TEST 5 - Reduce the amount of the Opportunity associated with the "leadership OT Contact (2)" so that they move to Basic.
    //     leadershipOTOpp2.Initial_Payment_Amount__c = 25;
    //     leadershipOTOpp2.Membership_Tier__c = MembershipUtilities.MEMBERSHIP_TIER_BASIC;
    //     oppsToUpdate.add(leadershipOTOpp2);

    //     update oppsToUpdate;

    //     Test.startTest();

    //         MembershipUtilities.getNewMembershipTiersByContact(contactIds);

    //     Test.stopTest();

    //     Map<Id, Contact> updatedContactMap = new Map<Id, Contact>([SELECT Id, Membership_Tier__c FROM Contact]);

    //     Contact basicOTContUpdated = updatedContactMap.get(basicOTCont.Id); 
    //     Contact basicMonthlyContUpdated = updatedContactMap.get(basicMonthlyCont.Id); 
    //     Contact leadershipOTContUpdated = updatedContactMap.get(leadershipOTCont.Id); 
    //     Contact leadershipMonthlyContUpdated = updatedContactMap.get(leadershipMonthlyCont.Id); 
    //     Contact leadershipOTCont2Updated = updatedContactMap.get(leadershipOTCont2.Id); 

    //     System.assertEquals(MembershipUtilities.CONTACT_MEMBERSHIP_TIER_LEADERSHIP, basicOTContUpdated.Membership_Tier__c,
    //         'Contact membership tier should now be ' + MembershipUtilities.CONTACT_MEMBERSHIP_TIER_LEADERSHIP);  /* TEST 1 */

    //     System.assertEquals(MembershipUtilities.CONTACT_MEMBERSHIP_TIER_LEADERSHIP, basicMonthlyContUpdated.Membership_Tier__c,
    //         'Contact membership tier should now be ' + MembershipUtilities.CONTACT_MEMBERSHIP_TIER_LEADERSHIP);  /* TEST 2 */

    //     System.assertEquals(MembershipUtilities.CONTACT_MEMBERSHIP_TIER_NONE, leadershipOTContUpdated.Membership_Tier__c,
    //         'Contact membership tier should now be  ' + MembershipUtilities.CONTACT_MEMBERSHIP_TIER_NONE); /* TEST 3 */

    //     System.assertEquals(MembershipUtilities.CONTACT_MEMBERSHIP_TIER_NONE, leadershipMonthlyContUpdated.Membership_Tier__c,
    //         'Contact membership tier should now be ' + MembershipUtilities.CONTACT_MEMBERSHIP_TIER_NONE); /* TEST 4 */

    //     System.assertEquals(MembershipUtilities.CONTACT_MEMBERSHIP_TIER_BASIC, leadershipOTCont2Updated.Membership_Tier__c,
    //         'Contact membership tier should now be Basic'); /* TEST 5 */

    // }    

}    