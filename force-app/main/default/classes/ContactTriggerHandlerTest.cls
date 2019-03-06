@IsTest
public with sharing class ContactTriggerHandlerTest {
    
    static final Integer NUM_CONTACTS_PER_ACCOUNT = 5;
    static Map<String,String> addressFieldMap = new Map<String,String>{
        'MailingStreet' => 'BillingStreet',
        'MailingCity' => 'BillingCity',
        'MailingState' => 'BillingState',
        'MailingPostalCode' => 'BillingPostalCode',
        'Standardized_Street_1__c' => 'Standardized_Street_1__c',
        'Standardized_Street_2__c' => 'Standardized_Street_2__c',
        'Standardized_City__c' => 'Standardized_City__c',
        'Standardized_State__c' => 'Standardized_State__c',
        'Standardized_Postal_Code__c' => 'Standardized_Postal_Code__c',
        'Standardized_Address_Message__c' => 'Standardized_Address_Message__c'
    };
    
    static testMethod void test_filterContactsWithUpdatedAccount() {
        List<Account> accounts = TestUtilities.createAccounts(2, true);
        List<Contact> contacts = TestUtilities.createContacts(accounts, NUM_CONTACTS_PER_ACCOUNT, true);
        Map<Id,Contact> oldMap = new Map<Id,Contact>(contacts.deepClone(true, true, true));
        Set<Id> expectedResultContactIds = new Set<Id>();
        for (Contact aContact : contacts) {
            if (aContact.AccountId == accounts[0].Id) {
                aContact.AccountId = accounts[1].Id;
                expectedResultContactIds.add(aContact.Id);
            }
        }
        Test.startTest();
            List<Contact> resultContacts = new ContactTriggerHandler().filterContactsWithUpdatedAccount(contacts, oldMap);
        Test.stopTest();
        System.assertEquals(NUM_CONTACTS_PER_ACCOUNT, resultContacts.size(), 'Expect the correct number of resulting contacts');
        for (Contact aContact : resultContacts) {
            System.assert(expectedResultContactIds.contains(aContact.Id),
                'Expect each resulting contact to be in the list of contacts whose accounts changed');
        }
    }

    static testMethod void test_backfillAccountsForContacts() {
        List<Account> accounts = TestUtilities.createAccounts(2, true);
        List<Contact> contacts = TestUtilities.createContacts(accounts, NUM_CONTACTS_PER_ACCOUNT, true);
        List<Account> requeriedAccounts = [SELECT Id FROM Account];
        List<Contact> requeriedContacts = [SELECT Id, AccountId, FirstName, LastName, MailingStreet, MailingCity,
                                            MailingState, MailingPostalCode, MailingCountry,
                                            Standardized_Street_1__c, Standardized_Street_2__c, Standardized_City__c, Standardized_State__c,
                                            Standardized_Postal_Code__c, Standardized_Address_Message__c, Address_Verification_Status__c
                                        FROM Contact];
        Account testAccount = requeriedAccounts[0];
        Account controlAccount = requeriedAccounts[1];
        for (Contact aContact : requeriedContacts) {
            if (aContact.AccountId == testAccount.Id)
                aContact.AccountId = null;
        }
        Test.startTest();
            new ContactTriggerHandler().backfillAccountsForContacts(requeriedContacts);
        Test.stopTest();
        Map<Id,Account> resultAccounts = new Map<Id,Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState,
                                                                BillingPostalCode, BillingCountry, Standardized_Street_1__c, Standardized_Street_2__c,
                                                                Standardized_City__c, Standardized_State__c,
                                                                Standardized_Postal_Code__c, Standardized_Address_Message__c, RecordTypeId
                                                            FROM Account]);
        System.assertEquals(requeriedAccounts.size() + NUM_CONTACTS_PER_ACCOUNT, resultAccounts.values().size(),
            'Expect one new account to have been created for all of the contacts which had no accountId');
        Map<Id,List<Contact>> resultContactsByAcctId = GroupBy.ids('AccountId', requeriedContacts);
        System.assert(!resultContactsByAcctId.containsKey(testAccount.Id),
            'Expect our test account to no longer have any contacts looking up to it');
        System.assertEquals(NUM_CONTACTS_PER_ACCOUNT, resultContactsByAcctId.get(controlAccount.Id).size(),
            'Expect our control account to still have all of its same contacts');
        for (Contact aContact : requeriedContacts) {
            if (aContact.AccountId != controlAccount.Id) {
                Account newAccount = resultAccounts.get(aContact.AccountId);
                System.assertNotEquals(null, AccountUtilities.accountRecordTypeMap.get('Household_Account'), 
                    'Account Household Record Type must not be null');
                System.assertEquals(AccountUtilities.accountRecordTypeMap.get('Household_Account'), 
                    newAccount.recordTypeId,
                    'Expect the new Account to have a Household Record Type');
                System.assert(newAccount.Name.contains(aContact.LastName),
                    'Expect the new account name to reference the contacts surname');
                for (String anAddressField : addressFieldMap.keySet()) {
                    System.assertEquals(newAccount.get(addressFieldMap.get(anAddressField)), aContact.get(anAddressField),
                        'Expect the address fields to be mapped from the contact to the account: ' + anAddressField);
                }
            }
        }
    }

    static testMethod void test_removeAccountsWithNoContacts() {
        List<Account> accounts = TestUtilities.createAccounts(2, true);
        List<Contact> contacts = TestUtilities.createContacts(accounts, NUM_CONTACTS_PER_ACCOUNT, true);
        List<Contact> requeriedContacts = [SELECT Id, AccountId FROM Contact WHERE Id IN :contacts];
        List<Opportunity> opps = TestUtilities.createOpportunities(requeriedContacts, 1, true);
        Account testAccount = accounts[0];
        Account newAccount = accounts[1];
        List<Contact> contactsToUpdate = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id];
        for (Contact aContact : contactsToUpdate) {
            aContact.AccountId = newAccount.Id;
        }
        Test.startTest();
            update contactsToUpdate;
        Test.stopTest();
        List<Account> resultAccounts = [SELECT Id FROM Account];
        System.assertEquals(1, resultAccounts.size(), 'Expect only one account to exist because the contacts belonging to the other account were all reparented');
        System.assert(!Pluck.ids(resultAccounts).contains(testAccount.Id),
            'Expect our result set to not include our test account because it had no contacts');
    }

    static testMethod void test_mergeContacts() {
        // Test deleting one Contact/Account via a merge, and if the Opp is reparented properly
        // The first Account/Contact/Opp created is for the master, the second for the slave
        List<Account> theAccounts = TestUtilities.createAccounts(2, true);
        List<Contact> theContacts = TestUtilities.createContacts(theAccounts, 1, true); 
        List<Opportunity> theOpps = TestUtilities.createOpportunities(theAccounts, 1, true);

        System.assertEquals(theAccounts[0].Id, theOpps[0].AccountId, 'Master Opp should be initially associated to Master Acct');
        System.assertEquals(theAccounts[1].Id, theOpps[1].AccountId, 'Slave Opp should be initially associated to Slave Acct');

        Id masterContactId = theContacts[0].Id;
        Id slaveContactId = theContacts[1].Id;
        Id slaveAccountId = theAccounts[1].Id;
        Id slaveOppId = theOpps[1].Id;

        Test.startTest();
        Database.merge(theContacts[0], theContacts[1].Id);
        Test.stopTest();

        List <Contact> slaveContactsAfterMerge = new List <Contact>([SELECT Id FROM Contact WHERE Id = :slaveContactId]);
        List <Account> slaveAccountsAfterMerge = new List <Account>([SELECT Id FROM Account WHERE Id = :slaveAccountId]);

        System.assertEquals(0, slaveContactsAfterMerge.size(), 'Slave Contact should not be present after the merge.');
        System.assertEquals(0, slaveAccountsAfterMerge.size(), 'Slave Account should not be present after the merge.');

        List<Opportunity> slaveOppsAfterMerge = new List<Opportunity>([SELECT Id, AccountId FROM Opportunity
                WHERE Id = :slaveOppId]);

        System.assertEquals(theAccounts[0].Id, slaveOppsAfterMerge[0].AccountId, 'Slave Opp should be now be associated to Master Acct');
        System.assertEquals(theAccounts[0].Id, theOpps[0].AccountId, 'Master Opp should be initially associated to Master Acct');

        List<Contact> masterContactsAfterMerge = new List<Contact>([SELECT Id, Possible_Duplicate__c FROM Contact
                WHERE Id = :masterContactId]);

        System.assertEquals(false, masterContactsAfterMerge[0].Possible_Duplicate__c, 'Possible Duplicate should be unchekced after the merge.');

    }

    static testMethod void test_insertBackfilledAccounts_success() {
        List<Contact> relatedContacts = TestUtilities.createContacts(5, true);
        for (Contact aContact : relatedContacts) {
            aContact.AccountId = null;
        }
        List<Account> existingAccounts = [SELECT Id FROM Account];
        List<Account> newAccounts = TestUtilities.createAccounts(5, false);
        Test.startTest();
            new ContactTriggerHandler().insertBackfilledAccounts(newAccounts, relatedContacts);
        Test.stopTest();
        List<Account> resultAccounts = [SELECT Id FROM Account WHERE Id NOT IN :existingAccounts];
        System.assertEquals(5, resultAccounts.size(), 'Expect all new accounts to have been inserted correctly');
        List<ApexPages.Message> msgs = ApexPages.getMessages();
        System.assert(msgs.isEmpty(), 'Expect no page message to be added because the dml was successful');
    }

    static testMethod void test_insertBackfilledAccounts_fail() {
        List<Contact> relatedContacts = TestUtilities.createContacts(5, true);
        for (Contact aContact : relatedContacts) {
            aContact.AccountId = null;
        }
        List<Account> existingAccounts = [SELECT Id FROM Account];
        List<Account> newAccounts = TestUtilities.createAccounts(5, false);
        insert newAccounts;
        Test.startTest();
            new ContactTriggerHandler().insertBackfilledAccounts(newAccounts, relatedContacts);
        Test.stopTest();
        List<Account> resultAccounts = [SELECT Id FROM Account WHERE Id NOT IN :existingAccounts];
        System.assertEquals(5, resultAccounts.size(), 'Expect all new accounts to have been inserted correctly');
        List<ApexPages.Message> msgs = ApexPages.getMessages();
        System.assert(!msgs.isEmpty(), 'Expect a page message to be added because the dml failed');
    }

    static testMethod void test_deleteEmptyAccounts_success() {
        List<Account> accounts = TestUtilities.createAccounts(2, true);
        List<Contact> contacts = TestUtilities.createContacts(accounts, NUM_CONTACTS_PER_ACCOUNT, true);
        Map<Id,List<Contact>> contactsByAccount = GroupBy.ids('AccountId', contacts);
        Test.startTest();
            new ContactTriggerHandler().deleteEmptyAccounts(accounts, contactsByAccount);
        Test.stopTest();
        List<ApexPages.Message> msgs = ApexPages.getMessages();
        System.assert(msgs.isEmpty(), 'Expect no page message to be added because the dml was successful');
    }

    static testMethod void test_deleteEmptyAccounts_fail() {
        List<Account> accounts = TestUtilities.createAccounts(2, true);
        List<Contact> contacts = TestUtilities.createContacts(accounts, NUM_CONTACTS_PER_ACCOUNT, true);
        Map<Id,List<Contact>> contactsByAccount = GroupBy.ids('AccountId', contacts);
        delete accounts;
        Test.startTest();
            new ContactTriggerHandler().deleteEmptyAccounts(accounts, contactsByAccount);
        Test.stopTest();
        List<ApexPages.Message> msgs = ApexPages.getMessages();
        System.assert(!msgs.isEmpty(), 'Expect a page message to be added because the dml failed');
    }

    // static testMethod void testRollupAccountMembershipTier_insert() {
    //     List<Account> accounts = TestUtilities.createAccounts(5, true);
    //     List<Contact> leadershipContacts = TestUtilities.createContacts(accounts, 1, false);
    //     List<Contact> basicContacts = TestUtilities.createContacts(accounts, 1, false);
    //     for (Integer i = 0; i < accounts.size(); i++) {
    //         leadershipContacts[i].Membership_Tier__c = MembershipUtilities.CONTACT_MEMBERSHIP_TIER_LEADERSHIP;
    //         basicContacts[i].Membership_Tier__c = MembershipUtilities.CONTACT_MEMBERSHIP_TIER_BASIC;
    //     }
    //     List<Contact> contacts = leadershipContacts;
    //     contacts.addAll(basicContacts);

    //     Test.startTest();
    //         insert contacts;
    //     Test.stopTest();

    //     List<Account> updatedAccounts = [SELECT Id, Membership_Tier__c FROM Account WHERE Id in :accounts];
    //     for (Account anAccount : updatedAccounts) {
    //         System.assertEquals(MembershipUtilities.ACCOUNT_MEMBERSHIP_TIER_LEADERSHIP, anAccount.Membership_Tier__c,
    //             'Each account Membership Tier should be Leadership because the highest tier among its contacts is Leadership');
    //     }
    // }

    // static testMethod void testRollupAccountMembershipTier_updateTier() {
    //     List<Account> accounts = TestUtilities.createAccounts(5, true);
    //     List<Contact> contacts = TestUtilities.createContacts(accounts, 1, false);
    //     for (Integer i = 0; i < accounts.size(); i++) {
    //         contacts[i].Membership_Tier__c = MembershipUtilities.CONTACT_MEMBERSHIP_TIER_LEADERSHIP;
    //     }
    //     insert contacts;
    //     for (Contact aContact : contacts) {
    //         aContact.Membership_Tier__c = MembershipUtilities.CONTACT_MEMBERSHIP_TIER_BASIC;
    //     }

    //     Test.startTest();
    //         update contacts;
    //     Test.stopTest();

    //     List<Account> updatedAccounts = [SELECT Id, Membership_Tier__c FROM Account WHERE Id in :accounts];
    //     for (Account anAccount : updatedAccounts) {
    //         System.assertEquals(MembershipUtilities.ACCOUNT_MEMBERSHIP_TIER_BASIC, anAccount.Membership_Tier__c,
    //             'Each account Membership Tier should be Basic because the contacts tier was downgraded from Leadership to Basic');
    //     }
    // }

    // static testMethod void testRollupAccountMembershipTier_reparent() {
    //     List<Account> accounts = TestUtilities.createAccounts(2, true);
    //     List<Contact> contacts = TestUtilities.createContacts(accounts, 2, false);
    //     for (Contact aContact : contacts) {
    //         aContact.Membership_Tier__c = MembershipUtilities.CONTACT_MEMBERSHIP_TIER_BASIC;
    //     }
    //     insert contacts;
    //     accounts = [SELECT Id, Membership_Tier__c, (SELECT Id FROM Contacts) FROM Account WHERE Id IN :accounts ORDER BY Name ASC];
    //     Account leadershipAccount = accounts[0];
    //     Account basicAccount = accounts[1];
    //     Contact leadershipContact = leadershipAccount.Contacts[0];
    //     leadershipContact.Membership_Tier__c = MembershipUtilities.CONTACT_MEMBERSHIP_TIER_LEADERSHIP;
    //     update leadershipContact;
    //     leadershipContact.AccountId = basicAccount.Id;
    //     Test.startTest();
    //         update leadershipContact;
    //     Test.stopTest();
    //     List<Account> requeriedAccounts = [SELECT Id, Membership_Tier__c FROM Account WHERE Id IN :accounts ORDER BY Name ASC];
    //     System.assertEquals(MembershipUtilities.ACCOUNT_MEMBERSHIP_TIER_BASIC, requeriedAccounts[0].Membership_Tier__c,
    //         'Expect the account with tier of leadership to have a new tier of basic because the leadership contact was reparented to the other account');
    //     System.assertEquals(MembershipUtilities.ACCOUNT_MEMBERSHIP_TIER_LEADERSHIP, requeriedAccounts[1].Membership_Tier__c,
    //         'Expect the account with tier of basic to have a new tier of leadership because the leadership contact was reparented to this account');
    // }

    // static testMethod void testRollupAccountMembershipTier_deleteContacts() {
    //     List<Account> accounts = TestUtilities.createAccounts(5, true);
    //     List<Contact> leadershipContacts = TestUtilities.createContacts(accounts, 1, false);
    //     List<Contact> basicContacts = TestUtilities.createContacts(accounts, 1, false);
    //     for (Integer i = 0; i < accounts.size(); i++) {
    //         leadershipContacts[i].Membership_Tier__c = MembershipUtilities.CONTACT_MEMBERSHIP_TIER_LEADERSHIP;
    //         basicContacts[i].Membership_Tier__c = MembershipUtilities.CONTACT_MEMBERSHIP_TIER_BASIC;
    //     }
    //     List<Contact> contacts = leadershipContacts;
    //     contacts.addAll(basicContacts);
    //     insert contacts;

    //     Test.startTest();
    //         delete leadershipContacts;
    //     Test.stopTest();

    //     List<Account> updatedAccounts = [SELECT Id, Membership_Tier__c FROM Account WHERE Id in :accounts];
    //     for (Account anAccount : updatedAccounts) {
    //         System.assertEquals(MembershipUtilities.ACCOUNT_MEMBERSHIP_TIER_BASIC, anAccount.Membership_Tier__c,
    //             'Each account Membership Tier should be Basic because the Leadership contacts were deleted');
    //     }
    // }

    static testMethod void testBackfillAccountsForContacts_existingAccount() {
        List<Contact> contacts = TestUtilities.createContacts(2, false);
        Contact firstContact = contacts[0];
        Contact secondContact = contacts[1];
        for (String anAddressField : addressFieldMap.keySet()) {
            firstContact.put(anAddressField, 'TEST1');
            secondContact.put(anAddressField, 'TEST2');
        }
        insert firstContact;
        List<Account> backfilledAccount = [SELECT Id, BillingStreet FROM Account];
        secondContact.AccountId = backfilledAccount[0].Id;
        Test.startTest();
            insert secondContact;
        Test.stopTest();        
        List<Account> backfilledAccountNew = [SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                                Standardized_Street_1__c, Standardized_Street_2__c, Standardized_City__c, Standardized_State__c,
                                Standardized_Postal_Code__c, Standardized_Address_Message__c FROM Account];
        System.assertEquals(1, backfilledAccountNew.size(), 'Expect the inserted contact to trigger an update to the existing account');
        for (String anAddressField : addressFieldMap.keySet()) {
            System.assertEquals(secondContact.get(anAddressField), backfilledAccountNew[0].get(addressFieldMap.get(anAddressField)),
                'Expect the address fields to be mapped from the contact to the account: ' + anAddressField);
        }
    }
    
    static testMethod void testResetAccountAddressOnContactReparent() {
        List<Account> accounts = TestUtilities.createAccounts(2, true);
        List<Contact> contacts = TestUtilities.createContacts(2, false);
        Contact firstContact = contacts[0];
        Contact secondContact = contacts[1];
        for (String anAddressField : addressFieldMap.keySet()) {
            firstContact.put(anAddressField, 'TEST1');
            secondContact.put(anAddressField, 'TEST2');
        }
        firstContact.AccountId = accounts[0].Id;
        secondContact.AccountId = accounts[0].Id;
        insert firstContact;
        insert secondContact;
        secondContact.AccountId = accounts[1].Id;
        Test.startTest();
            update secondContact;
        Test.stopTest();        
        Map<Id,Account> updatedAccountNew = new Map<Id,Account>([SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                                Standardized_Street_1__c, Standardized_Street_2__c, Standardized_City__c, Standardized_State__c,
                                Standardized_Postal_Code__c, Standardized_Address_Message__c FROM Account]);
        
        for (String anAddressField : addressFieldMap.keySet()) {
            System.assertEquals(firstContact.get(anAddressField), updatedAccountNew.get(firstContact.AccountId).get(addressFieldMap.get(anAddressField)),
                'Expect the address fields of the first account to be remapped back to the remaining contact: ' + anAddressField);
        }
    }

    static testMethod void testfilterContactsWithUpdatedLevel() {

        List<Account> accounts = TestUtilities.createAccounts(2, true);
        List<Contact> contacts = TestUtilities.createContacts(accounts, NUM_CONTACTS_PER_ACCOUNT, true);
        Map<Id,Contact> oldMap = new Map<Id,Contact>(contacts.deepClone(true, true, true));
        Set<Id> expectedResultContactIds = new Set<Id>();
        for (Contact aContact : contacts) {
            if (aContact.AccountId == accounts[0].Id) {
                aContact.Sum_Annualized_Sustaining_Donations__c = 25;
                expectedResultContactIds.add(aContact.Id);
            }
        }
        Test.startTest();
            List<Contact> resultContacts = new ContactTriggerHandler().filterContactsWithUpdatedLevel(contacts, oldMap);
        Test.stopTest();
        
        System.assertEquals(NUM_CONTACTS_PER_ACCOUNT, resultContacts.size(), 'Expect the correct number of resulting contacts');
        for (Contact aContact : resultContacts) {
            System.assert(expectedResultContactIds.contains(aContact.Id),
                'Expect each resulting contact to be in the list of contacts whose values changed');
        }
    }

    static testMethod void testGetAccountsToDelete() {

        List<Account> accounts = TestUtilities.createAccounts(2, true);
        Contact c = new Contact(LastName = 'Test', AccountId = accounts[1].Id);
        insert c;

        Set<Id> accountIds = new Set<Id>();
        for (Account a : accounts) {
            accountIds.add(a.Id);
        }

        Test.startTest();
            List<Account> accountsToDelete = new ContactTriggerHandler().getAccountsToDelete(accountIds);
        Test.stopTest();

        System.assertEquals(1, accountsToDelete.size(), 'Should only be one Account without Contacts');
        for (Account acct : accountsToDelete) {
            System.assertEquals(accounts[0].Id, acct.Id, 
                'The first Account should be an Account to be deleted.');
            System.assertNotEquals(accounts[1].Id, acct.Id, 
                'The second Account should NOT be an Account to be deleted.');
        }
    }


}