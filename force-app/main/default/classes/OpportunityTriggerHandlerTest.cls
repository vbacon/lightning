@IsTest
public class OpportunityTriggerHandlerTest {
    
    @testSetup
    static void testSetup() {
        Pricebook2 testOneTimePb = new Pricebook2(Name = PricebookServices.ONE_TIME);
        Pricebook2 testSustainerPb = new Pricebook2(Name = PricebookServices.SUSTAINER);
        insert new List<Pricebook2>{testOneTimePb, testSustainerPb};
    }

    static testMethod void testPopulatePricebook_insert() {
        List<Account> testAccounts = TestUtilities.createAccounts(1, true);
        List<Opportunity> testOpps = TestUtilities.createOpportunities(testAccounts, 10, false);
        for (Integer i = 0; i < testOpps.size(); i++) {
            testOpps[i].Is_Monthly__c = (Math.mod(i, 2) == 0);
        }
        Test.startTest();
            insert testOpps;
        Test.stopTest();
        List<Opportunity> requeriedOpps = [SELECT Id, Pricebook2Id, Is_Monthly__c FROM Opportunity];
        Boolean hasMonthly = false;
        Boolean hasOneTime = false;
        for (Opportunity anOpp : requeriedOpps) {
            
            if (anOpp.Is_Monthly__c) {
                hasMonthly = true;
                System.assertEquals(PricebookServices.pricebooksByName.get(PricebookServices.SUSTAINER), anOpp.Pricebook2Id,
                    'Expect the sustainer pricebook to be assigned to montly opportunities');
            }
            else {
                hasOneTime = true;
                System.assertEquals(PricebookServices.pricebooksByName.get(PricebookServices.ONE_TIME), anOpp.Pricebook2Id,
                    'Expect the one time pricebook to be assigned to one time opportunities');
            }
        }
        System.assert(hasMonthly, 'Expect at least one opp to be sustaining');
        System.assert(hasOneTime, 'Expect at least one opp to be one time');
    }
    
    static testMethod void testPopulatePricebook_update() {
        List<Account> testAccounts = TestUtilities.createAccounts(1, true);
        List<Opportunity> testOpps = TestUtilities.createOpportunities(testAccounts, 10, false);
        for (Integer i = 0; i < testOpps.size(); i++) {
            testOpps[i].Is_Monthly__c = (Math.mod(i, 2) == 0);
        }
        insert testOpps;
        for (Opportunity anOpp : testOpps) {
            anOpp.Is_Monthly__c = !(anOpp.Is_Monthly__c);
        }
        Test.startTest();
            update testOpps;
        Test.stopTest();
        List<Opportunity> requeriedOpps = [SELECT Id, Pricebook2Id, Is_Monthly__c FROM Opportunity];
        Boolean hasMonthly = false;
        Boolean hasOneTime = false;
        for (Opportunity anOpp : requeriedOpps) {
            if (anOpp.Is_Monthly__c) {
                hasMonthly = true;
                System.assertEquals(PricebookServices.pricebooksByName.get(PricebookServices.SUSTAINER), anOpp.Pricebook2Id,
                    'Expect the sustainer pricebook to be assigned to montly opportunities');
            }
            else {
                hasOneTime = true;
                System.assertEquals(PricebookServices.pricebooksByName.get(PricebookServices.ONE_TIME), anOpp.Pricebook2Id,
                    'Expect the one time pricebook to be assigned to one time opportunities');
            }
        }
        System.assert(hasMonthly, 'Expect at least one opp to be sustaining');
        System.assert(hasOneTime, 'Expect at least one opp to be one time');
    }

    static testMethod void testPopulateStandardField_insert_withOLI() {
        List<Account> testAccounts = TestUtilities.createAccounts(1, true);
        List<Account> testVendors = TestUtilities.createVendors(1, true);
        List<Opportunity> testOpps = TestUtilities.createOpportunities(testAccounts, 10, false);
        List<Product2> testProducts = TestUtilities.createProducts(4, testVendors[0].Id, true);
        Test.startTest();
            insert testOpps;
            Id pricebookId = [SELECT Pricebook2Id FROM Opportunity WHERE Id = :testOpps[0].Id].Pricebook2Id;
            PricebookEntry pbe = [SELECT Id, UnitPrice FROM PricebookEntry WHERE
                                    Pricebook2Id = :pricebookId AND
                                    Product2Id = :testProducts[0].Id];
            OpportunityLineItem theOli = new OpportunityLineItem(OpportunityId = testOpps[0].Id);
            theOli.Product2Id = testProducts[0].Id;
            theOli.UnitPrice = pbe.UnitPrice;
            theOli.Quantity = 1;
            insert theOli;
        Test.stopTest();
        List<Opportunity> requeriedOpps = [SELECT Id, Amount, Initial_Payment_Amount__c FROM Opportunity];
        System.assertNotEquals(requeriedOpps[0].Amount, requeriedOpps[0].Initial_Payment_Amount__c);
    }

    static testMethod void testPopulateStandardField_insert_withoutOLI() {
        List<Account> testAccounts = TestUtilities.createAccounts(1, true);
        List<Opportunity> testOpps = TestUtilities.createOpportunities(testAccounts, 10, false);
        Test.startTest();
            insert testOpps;
        Test.stopTest();
        List<Opportunity> requeriedOpps = [SELECT Id, Amount, Initial_Payment_Amount__c FROM Opportunity];
        for (Opportunity anOpp : requeriedOpps) {
            System.assertEquals(anOpp.Amount, anOpp.Initial_Payment_Amount__c);
        }
    }

    // static testMethod void testRollupContactMembershipTier_insert() {
    //     List<Account> accounts = TestUtilities.createAccounts(2, true);
    //     List<Contact> contacts = TestUtilities.createContacts(accounts, 2, true);
    //     List<Contact> requeriedContacts = [SELECT Id, AccountId FROM Contact WHERE Id IN :contacts];

    //     List<Opportunity> opps = TestUtilities.createOpportunities(requeriedContacts, 2, false);
    //     for (Opportunity anOpp : opps) {
    //         anOpp.Membership_Tier__c = MembershipUtilities.MEMBERSHIP_TIER_BASIC;
    //     }
    //     Test.startTest();
    //         insert opps;
    //     Test.stopTest();

    //     List<Contact> updatedContacts = new List<Contact>([SELECT Id, AccountId, Membership_Tier__c
    //             FROM Contact WHERE Id in :contacts]);
    //     for (Contact c : updatedContacts) {
    //         System.assertEquals(MembershipUtilities.CONTACT_MEMBERSHIP_TIER_BASIC, c.Membership_Tier__c, 'Contact Membership Tier should be Basic');
    //     }

    //     List<Account> updatedAccounts = new List<Account>([SELECT Id, Membership_Tier__c
    //             FROM Account WHERE Id in :accounts]);
    //     for (Account a : updatedAccounts) {
    //         System.assertEquals(MembershipUtilities.ACCOUNT_MEMBERSHIP_TIER_BASIC, a.Membership_Tier__c, 'Account Membership Tier should be Basic');
    //     }
    // }

    // static testMethod void testRollupContactMembershipTier_updateTier() {
    //     List<Account> accounts = TestUtilities.createAccounts(2, true);
    //     List<Contact> contacts = TestUtilities.createContacts(accounts, 2, true);
    //     List<Contact> requeriedContacts = [SELECT Id, AccountId FROM Contact WHERE Id IN :contacts];

    //     List<Opportunity> controlOpps = TestUtilities.createOpportunities(contacts, 1, false);
    //     List<Opportunity> updatedOpps = TestUtilities.createOpportunities(contacts, 1, false);
    //     List<Opportunity> allOpps = controlOpps;
    //     allOpps.addAll(updatedOpps);
    //     for (Opportunity anOpp : allOpps) {
    //         anOpp.Membership_Tier__c = MembershipUtilities.MEMBERSHIP_TIER_BASIC;
    //     }
    //     insert allOpps;

    //     for (Opportunity anOpp : updatedOpps) {
    //         anOpp.Membership_Tier__c = MembershipUtilities.MEMBERSHIP_TIER_LEADERSHIP;
    //     }
    //     Test.startTest();
    //         update updatedOpps;
    //     Test.stopTest();

    //     List<Contact> updatedContacts = new List<Contact>([SELECT Id, AccountId, Membership_Tier__c
    //             FROM Contact WHERE Id in :contacts]);
    //     for (Contact c : updatedContacts) {
    //         System.assertEquals(MembershipUtilities.CONTACT_MEMBERSHIP_TIER_LEADERSHIP, c.Membership_Tier__c,
    //             'Contact Membership Tier should be Leadership because it is highest tier among related opportunities');
    //     }

    //     List<Account> updatedAccounts = new List<Account>([SELECT Id, Membership_Tier__c
    //             FROM Account WHERE Id in :accounts]);
    //     for (Account a : updatedAccounts) {
    //         System.assertEquals(MembershipUtilities.ACCOUNT_MEMBERSHIP_TIER_LEADERSHIP, a.Membership_Tier__c, 'Account Membership Tier should be Leadership');
    //     }
    // }

    // static testMethod void testRollupContactMembershipTier_updateIsActive() {
    //     List<Account> accounts = TestUtilities.createAccounts(2, true);
    //     List<Contact> contacts = TestUtilities.createContacts(accounts, 2, true);
    //     List<Contact> requeriedContacts = [SELECT Id, AccountId FROM Contact WHERE Id IN :contacts];

    //     List<Opportunity> controlOpps = TestUtilities.createOpportunities(contacts, 1, false);
    //     List<Opportunity> updatedOpps = TestUtilities.createOpportunities(contacts, 1, false);

    //     for (Opportunity anOpp : controlOpps) {
    //         anOpp.Membership_Tier__c = MembershipUtilities.MEMBERSHIP_TIER_BASIC;
    //     }
    //     for (Opportunity anOpp : updatedOpps) {
    //         anOpp.Membership_Tier__c = MembershipUtilities.MEMBERSHIP_TIER_LEADERSHIP;
    //     }
    //     List<Opportunity> allOpps = controlOpps;
    //     allOpps.addAll(updatedOpps);
    //     insert allOpps;

    //     for (Opportunity o : updatedOpps) {
    //         o.Membership_Active__c = false;
    //     }

    //     Test.startTest();
    //         update updatedOpps;
    //     Test.stopTest();

    //     List<Contact> updatedContacts = new List<Contact>([SELECT Id, AccountId, Membership_Tier__c
    //             FROM Contact WHERE Id in :contacts]);
    //     List<Account> updatedAccounts = new List<Account>([SELECT Id, Membership_Tier__c
    //             FROM Account WHERE Id in :accounts]);
        
    //     for (Contact c : updatedContacts) {
    //         System.assertEquals(MembershipUtilities.CONTACT_MEMBERSHIP_TIER_BASIC, c.Membership_Tier__c,
    //             'Contact Membership Status should be Basic if Leadership opportunity is deactivated');
    //     }
    //     for (Account a : updatedAccounts) {
    //         System.assertEquals(MembershipUtilities.ACCOUNT_MEMBERSHIP_TIER_BASIC, a.Membership_Tier__c,
    //             'Account Membership Status should be Basic if all Contacts tier is basic') ;
    //     }
    // }

    // static testMethod void testRollupContactMembershipTier_delete() {
    //     List<Account> accounts = TestUtilities.createAccounts(2, true);
    //     List<Contact> contacts = TestUtilities.createContacts(accounts, 2, true);
    //     List<Contact> requeriedContacts = [SELECT Id, AccountId FROM Contact WHERE Id IN :contacts];

    //     List<Opportunity> controlOpps = TestUtilities.createOpportunities(contacts, 1, false);
    //     List<Opportunity> deletedOpps = TestUtilities.createOpportunities(contacts, 1, false);

    //     for (Opportunity anOpp : controlOpps) {
    //         anOpp.Membership_Tier__c = MembershipUtilities.MEMBERSHIP_TIER_BASIC;
    //     }
    //     for (Opportunity anOpp : deletedOpps) {
    //         anOpp.Membership_Tier__c = MembershipUtilities.MEMBERSHIP_TIER_LEADERSHIP;
    //     }
    //     List<Opportunity> allOpps = controlOpps;
    //     allOpps.addAll(deletedOpps);
    //     insert allOpps;

    //     Test.startTest();
    //         delete deletedOpps;
    //     Test.stopTest();

    //     List<Contact> updatedContacts = new List<Contact>([SELECT Id, AccountId, Membership_Tier__c
    //             FROM Contact WHERE Id in :contacts]);
    //     List<Account> updatedAccounts = new List<Account>([SELECT Id, Membership_Tier__c
    //             FROM Account WHERE Id in :accounts]);
        
    //     for (Contact c : updatedContacts) {
    //         System.assertEquals(MembershipUtilities.CONTACT_MEMBERSHIP_TIER_BASIC, c.Membership_Tier__c,
    //             'Contact Membership Tier should be Basic if the Leadership opportunity is deleted');
    //     }
    //     for (Account a : updatedAccounts) {
    //         System.assertEquals(MembershipUtilities.ACCOUNT_MEMBERSHIP_TIER_BASIC, a.Membership_Tier__c,
    //             'Account Membership Tier should be Basic if all related contacts tier is basic');
    //     }
    // }

    // static testMethod void testRollupContactMembershipTier_deleteAll() {
    //     List<Account> accounts = TestUtilities.createAccounts(2, true);
    //     List<Contact> contacts = TestUtilities.createContacts(accounts, 2, true);
    //     List<Contact> requeriedContacts = [SELECT Id, AccountId FROM Contact WHERE Id IN :contacts];

    //     List<Opportunity> controlOpps = TestUtilities.createOpportunities(contacts, 1, false);
    //     List<Opportunity> deletedOpps = TestUtilities.createOpportunities(contacts, 1, false);

    //     for (Opportunity anOpp : controlOpps) {
    //         anOpp.Membership_Tier__c = MembershipUtilities.MEMBERSHIP_TIER_BASIC;
    //     }
    //     for (Opportunity anOpp : deletedOpps) {
    //         anOpp.Membership_Tier__c = MembershipUtilities.MEMBERSHIP_TIER_LEADERSHIP;
    //     }
    //     List<Opportunity> allOpps = controlOpps;
    //     allOpps.addAll(deletedOpps);
    //     insert allOpps;

    //     Test.startTest();
    //         delete allOpps;
    //     Test.stopTest();

    //     List<Contact> updatedContacts = new List<Contact>([SELECT Id, Membership_Tier__c
    //             FROM Contact WHERE Id in :contacts]);
    //     List<Account> updatedAccounts = new List<Account>([SELECT Id, Membership_Tier__c
    //             FROM Account WHERE Id in :accounts]);

    //     for (Contact c : updatedContacts) {
    //         System.assertEquals(MembershipUtilities.CONTACT_MEMBERSHIP_TIER_NONE, c.Membership_Tier__c,
    //             'Contact Membership Tier should be None if all Opportunities are deleted');
    //     }
    //     for (Account a : updatedAccounts) {
    //         System.assertEquals(MembershipUtilities.ACCOUNT_MEMBERSHIP_TIER_NONE, a.Membership_Tier__c,
    //             'Account Membership Tier should be None if related Contacts tier is None');
    //     }
    // }

}