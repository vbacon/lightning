/**
* @author Adam Gallinat
* @date February 2018
*
* @description Trigger handler on Contact. Extends base TriggerHandler class
*/

public class ContactTriggerHandler extends TriggerHandler {

    public static Boolean isWithinAMerge = false;

    public override void beforeInsert() {
        backfillAccountsForContacts((List<Contact>)Trigger.new);
    }

    public override void beforeUpdate() {
        Map<Member_Level__c, String> memberLevelBenefitStrings = ContactUtilities.getMemberBenefitStrings();
        
        List<Contact> contactsWithUpdatedAccount = filterContactsWithUpdatedAccountOrAddress((List<Contact>)Trigger.new, (Map<Id,Contact>)Trigger.oldMap);
        backfillAccountsForContacts(contactsWithUpdatedAccount);

        List<Contact> contactsWithUpdatedMembershipLevel = 
            filterContactsWithUpdatedLevel((List<Contact>)Trigger.new, (Map<Id,Contact>)Trigger.oldMap);
        System.debug('About to call recalcMembershipLevel');
        recalcMembershipLevel(contactsWithUpdatedMembershipLevel, memberLevelBenefitStrings);

        if (isWithinAMerge) {
            checkForAccountContactMismatch((Map<Id,Contact>)Trigger.oldMap, (Map<Id,Contact>)Trigger.newMap);
            removePossibleDuplicateFlag((List<Contact>)Trigger.new);
            setMembershipTierValues((Trigger.oldMap).keyset());
        }            
    }

    public override void afterInsert() {
        // VWB - Below is Membership Tier which is being replaced by Membership Level. This takes up a lot of SOQL queries so it's being commented out.
        // rollupAccountMembershipTier((List<Contact>)Trigger.new);
    }

    public override void afterUpdate() {
        // swapping filter method params because we need to return the old records, not the new
        List<Contact> contactsWithUpdatedAccount = filterContactsWithUpdatedAccount((List<Contact>)Trigger.old, (Map<Id,Contact>)Trigger.newMap);
        
        // reparenting opportunities must be done here in code so that we are allowed to delete the otherwise empty accounts
        reparentOpportunitiesByContact(contactsWithUpdatedAccount, (Map<Id,Contact>)Trigger.newMap);
        removeOrUpdateOldAccounts(contactsWithUpdatedAccount, (Map<Id,Contact>) Trigger.newMap);
        List<Contact> contactsWithUpdatedMembershipTier = filterContactsWithUpdatedTier((List<Contact>)Trigger.new, (Map<Id,Contact>)Trigger.oldMap);
        // VWB - Below is Membership Tier which is being replaced by Membership Level. This takes up a lot of SOQL queries so it's being commented out.
        // rollupAccountMembershipTier(contactsWithUpdatedMembershipTier, (Map<Id,Contact>)Trigger.oldMap);
    }
    
    public override void afterDelete() {
        // Below is needed to make sure any Accounts deleted via a merge don't have Opportunities
        reparentOpportunitiesPriorToMerge((List<Contact>)Trigger.old, (Map<Id,Contact>)Trigger.newMap);

        removeOrUpdateOldAccounts((List<Contact>)Trigger.old);
        rollupAccountMembershipTier((List<Contact>)Trigger.old);
    }

    private void setMembershipTierValues(Set <Id> oldContactIds) {
        Map <Id, String> newMembershipTierValues =  
                MembershipUtilities.getNewMembershipTiersByContact(oldContactIds);
        for (Contact c : (List<Contact>)Trigger.new) {
            if (newMembershipTierValues.containsKey(c.Id)) { 
                c.Membership_Tier__c = newMembershipTierValues.get(c.Id);
            }
        }
    }

    private void checkForAccountContactMismatch(Map<Id,Contact> triggerOldMap, Map<Id,Contact> triggerNewMap) {
        for (Id theId : triggerOldMap.keyset()) {
            if (triggerOldMap.get(theId).accountId != triggerNewMap.get(theId).accountId) {
                triggerNewMap.get(theId).addError('When merging records the Account to merge into must be the Master Contact\'s Account.');
            }
        }
    }
    
    private void removePossibleDuplicateFlag(List<Contact> triggerNew) {
        for (Contact c : triggerNew) {
            c.Possible_Duplicate__c = false;
        }
    }

    /**
    * @description Given a list of contacts, creates a parent account for every
    * contact that does not have one. Update addresses for accounts that already exist
    * @param triggerNew List of contacts to evaluate creating Accounts for
    */
    @TestVisible
    private void backfillAccountsForContacts(List<Contact> triggerNew) {
        List<Contact> contactsWithoutAccount = new List<Contact>();
        List<Contact> contactsWithAccount = new List<Contact>();
        for (Contact aContact : triggerNew) {
            if (String.isBlank(aContact.AccountId)) {
                contactsWithoutAccount.add(aContact);
            }
            else {
                contactsWithAccount.add(aContact);
            }
        }
        if (!contactsWithoutAccount.isEmpty()) {
            createAccountsForContacts(contactsWithoutAccount);
        }
        if (!contactsWithAccount.isEmpty()) {
            updateAccountsForContacts(contactsWithAccount);
        }
    }

    /**
    * @description Creates and inserts a parent account for every incoming
    * contact. Also sets account lookup on those contacts
    * @param contacts List of contacts to create an Account for
    */
    @TestVisible
    private void createAccountsForContacts(List<Contact> contacts) {
        List<Account> accounts = new List<Account>();
        Id householdRecordTypeId;
        if (AccountUtilities.accountRecordTypeMap != null &&
                AccountUtilities.accountRecordTypeMap.containsKey('Household_Account')) {
            householdRecordTypeId = AccountUtilities.accountRecordTypeMap.get('Household_Account');
        } else {
            contacts[0].addError('Could not find Household Account Record Type.');
            return;
        }
        for (Integer i = 0; i < contacts.size(); i++) {
            Account newAccount = createAccountForContact(contacts[i]);
            newAccount.Name = contacts[i].LastName + ' Household';
            newAccount.recordTypeId = householdRecordTypeId;
            accounts.add(newAccount);
        }
        insertBackfilledAccounts(accounts, contacts);
        for (Integer j = 0; j < contacts.size(); j++) {
            contacts[j].AccountId = accounts[j].Id;
        }
    }

    @TestVisible
    private void insertBackfilledAccounts(List<Account> accounts, List<Contact> contacts) {
        try {
            insert accounts;
        }
        catch (DMLException e) {
            for (Integer i = 0; i < e.getNumDml(); i++) {
                contacts[e.getDmlIndex(i)].addError(e.getDmlMessage(i));
            }
        }
    }

    /**
    * @description Builds and returns an account to be associated with a
    * given contact
    * @param theContact
    * @return the newly built account
    */
    @TestVisible
    private Account createAccountForContact(Contact theContact) {
        Account newAccount = new Account();
        newAccount.BillingStreet = theContact.MailingStreet;
        newAccount.BillingCity = theContact.MailingCity;
        newAccount.BillingState = theContact.MailingState;
        newAccount.BillingPostalCode = theContact.MailingPostalCode;
        newAccount.BillingCountry = theContact.MailingCountry;
        newAccount.Standardized_Street_1__c = theContact.Standardized_Street_1__c;
        newAccount.Standardized_Street_2__c = theContact.Standardized_Street_2__c;
        newAccount.Standardized_City__c = theContact.Standardized_City__c;
        newAccount.Standardized_State__c = theContact.Standardized_State__c;
        newAccount.Standardized_Postal_Code__c = theContact.Standardized_Postal_Code__c;
        newAccount.Standardized_Address_Message__c = theContact.Standardized_Address_Message__c;
        newAccount.Address_Verification_Status__c = theContact.Address_Verification_Status__c;

        return newAccount;
    }

    /**
    * @description Deletes a list of accounts, and handles errors by
    * associating the error with the accounts child contacts
    * @param accountsToDelete
    * @param acctToContactsMap the contacts to associate errors to, grouped
    * by accountId
    */
    @TestVisible
    private void deleteEmptyAccounts(List<Account> accountsToDelete, Map<Id,List<Contact>> acctToContactsMap) {
        try {
            delete accountsToDelete;
        }
        catch (DMLException e) {
            for (Integer i = 0; i < e.getNumDml(); i++) {
                Account failedContact = accountsToDelete[e.getDmlIndex(i)];
                for (Contact aContact : acctToContactsMap.get(failedContact.Id)) {
                    aContact.addError(e.getDmlMessage(i));
                }
            }
        }
    }

    /**
    * @description Filters a given list of contacts by those whose account ids 
    * or standardized address fields have changed
    * @param contactsToFilter the collection of records to return the subset of
    * @param filterAgainst the collection of records to filter against
    * @return the filtered contacts
    */
    public List<Contact> filterContactsWithUpdatedAccountOrAddress(List<Contact> contactsToFilter, Map<Id,Contact> filterAgainst) {
        List<Contact> filteredContacts = new List<Contact>();
        for (Contact aContact : contactsToFilter) {
            if ((aContact.AccountId != filterAgainst.get(aContact.Id).AccountId) || 
                (aContact.Standardized_Street_1__c != filterAgainst.get(aContact.Id).Standardized_Street_1__c) || 
                (aContact.Standardized_Street_2__c != filterAgainst.get(aContact.Id).Standardized_Street_2__c) ||
                (aContact.Standardized_City__c != filterAgainst.get(aContact.Id).Standardized_City__c) || 
                (aContact.Standardized_State__c != filterAgainst.get(aContact.Id).Standardized_State__c) ||
                (aContact.Standardized_Postal_Code__c != filterAgainst.get(aContact.Id).Standardized_Postal_Code__c) ||
                (aContact.Address_Verification_Status__c != filterAgainst.get(aContact.Id).Address_Verification_Status__c)) {
                filteredContacts.add(aContact);
            }
        }
        return filteredContacts;
    }

    /**
    * @description Filters a given list of contacts by those whose account ids 
    * have changed
    * @param contactsToFilter the collection of records to return the subset of
    * @param filterAgainst the collection of records to filter against
    * @return the filtered contacts
    */
    public List<Contact> filterContactsWithUpdatedAccount(List<Contact> contactsToFilter, Map<Id,Contact> filterAgainst) {
        List<Contact> filteredContacts = new List<Contact>();
        for (Contact aContact : contactsToFilter) {
            if (aContact.AccountId != filterAgainst.get(aContact.Id).AccountId) {
                filteredContacts.add(aContact);
            }
        }
        return filteredContacts;
    }

    /**
    * @description Returns a list of accounts for which there are no longer any contacts
    * @param accountIds Ids of the accounts to filter
    * @return the accounts included in the set that have no contacts
    */
    @TestVisible
    private List<Account> getAccountsToDelete(Set<Id> accountIds) {
        List<Account> accounts = [
            SELECT Id,
                (SELECT Id FROM Contacts)
            FROM Account
            WHERE Id IN :accountIds
        ];
        List<Account> accountsToDelete = new List<Account>();
        for (Account anAccount : accounts) {
            if (anAccount.Contacts.isEmpty()) {
                accountsToDelete.add(anAccount);
            }
        }
        return accountsToDelete;
    }

    private void reparentOpportunitiesPriorToMerge(List <Contact> triggerOldContacts, Map<Id,Contact> newMap) {
        // When Contacts are deleted via merge, reparent any Opportunities to the merge Contact/Account that will stay.
        // The 'slave' Contact/Account is the one being deleted as a result of the merge.  The 'master' is the one that is staying.
        List <Contact> contactsDeletedViaMerge = filterMergeContactsDeleted(triggerOldContacts); // Get only those contacts being merged
        if (contactsDeletedViaMerge.isEmpty()) {
            return;
        } else {
            isWithinAMerge = true;
        }

        Map<Id, Id> contactSlaveToAccountSlaveMap = createContactSlaveToAccountSlave(contactsDeletedViaMerge); // Contact/Account map of Contacts being deleted
        Map<Id, Id> contactMasterToAccountMasterMap = createContactMasterToAccountMasterMap(contactsDeletedViaMerge); // Contact/Account map of Contacts staying
        Map<Id, Id> contactSlaveToContactMasterMap = createContactSlaveToContactMasterMap(contactsDeletedViaMerge); // Contact/Contact, survivor then master
        Map<Id, Id> accountSlaveToAccountMasterMap = 
                createAccountSlaveToAccountMasterMap(contactSlaveToAccountSlaveMap, contactMasterToAccountMasterMap, contactSlaveToContactMasterMap);

        Set<Id> accountsToBeReparented = accountSlaveToAccountMasterMap.keyset();
        List<Opportunity> oppsBeingReparented = [SELECT Id, Contact__c, AccountId FROM Opportunity WHERE AccountId IN :accountsToBeReparented];

        for (Opportunity opp : oppsBeingReparented) {
            Id originalAccountId = opp.AccountId;
            opp.AccountId = accountSlaveToAccountMasterMap.get(originalAccountId);
        }
        try {
            if (!oppsBeingReparented.isEmpty()) {
                update oppsBeingReparented;
            }    
        }
        catch (DMLException e) {
            for (Integer i = 0; i < e.getNumDml(); i++) {
                Opportunity failedOpp = oppsBeingReparented[e.getDmlIndex(i)];
                Contact failedContact = newMap.get(failedOpp.Contact__c);
                failedContact.addError(e.getDmlMessage(i));
            }
        }
    }

    /* Returns those contacts that are about to be deleted via a merge */
    public List<Contact> filterMergeContactsDeleted(List<Contact> contactsToFilter) {
        List<Contact> filteredContacts = new List<Contact>();
        for (Contact aContact : contactsToFilter) {
            if (aContact.MasterRecordId != null) {
                filteredContacts.add(aContact);
            }
        }
        return filteredContacts;
    }

    private Map<Id, Id> createContactSlaveToAccountSlave(List <Contact> contactsBeingDeleted) {  // before or after delete
        // This returns a map of the Contacts and their Accounts that are being deleted as a result of the merge.
        Map<Id, Id> contactSlaveToAccountSlaveMap = new Map<Id, Id>();
        for (Contact c : contactsBeingDeleted) {
            contactSlaveToAccountSlaveMap.put(c.Id, c.AccountId);  
        }
        return contactSlaveToAccountSlaveMap;
    }

    private Map<Id, Id> createContactMasterToAccountMasterMap(List <Contact> contactsBeingDeleted) {  // only after delete
        // This returns are the master Contacts/Accounts that are staying after a merge is being done.
        Map<Id, Id> contactMasterToAccountMasterMap = new Map<Id, Id>();
        Set<Id> contactMasterIdSet = new Set<Id>();
        for (Contact c : contactsBeingDeleted) {
            contactMasterIdSet.add(c.MasterRecordId);  
        }
        
        List<Contact> masterContactList = [SELECT Id, AccountId FROM Contact WHERE Id in :contactMasterIdSet];
        for (Contact c : masterContactList) {
            contactMasterToAccountMasterMap.put(c.Id, c.AccountId);
        }

        return contactMasterToAccountMasterMap;
    }

    private Map<Id, Id> createContactSlaveToContactMasterMap(List <Contact> mergeContactSlaves) { 
        // This returns a map of the the deleted Contacts and the master Contacts they are being merged into.
        Map<Id, Id> contactSlaveToContactMasterMap = new Map<Id, Id>();
        for (Contact c : mergeContactSlaves) {
            contactSlaveToContactMasterMap.put(c.Id, c.MasterRecordId);
        }

        return contactSlaveToContactMasterMap;
    }

    private Map<Id, Id> createAccountSlaveToAccountMasterMap(Map<Id, Id> contactSlaveToAccountSlave, Map<Id, Id> contactMasterToAccountMasterMap, 
            Map<Id, Id> contactSlaveToContactMasterMap) {

        // This returns the old and new Account Ids for Opportunity repairing.
        Map<Id, Id> accountSlaveToAccountMasterMap = new Map<Id, Id>();
        
        for (Id slaveContactId : contactSlaveToContactMasterMap.keySet()) {  // Iterating through the map 
            Id masterContactId = contactSlaveToContactMasterMap.get(slaveContactId);  // the second part of each map element
            accountSlaveToAccountMasterMap.put((contactSlaveToAccountSlave.get(slaveContactId)), // first part of the map is the slave Account Id
                (contactMasterToAccountMasterMap.get(masterContactId)));  // second part of the map is the master Account Id
        }

        return accountSlaveToAccountMasterMap;
    }

    @TestVisible
    private void reparentOpportunitiesByContact(List<Contact> contacts, Map<Id,Contact> newMap) {
        List<Opportunity> opps = [SELECT Id, Contact__c, AccountId FROM Opportunity WHERE Contact__c IN :contacts];
        Map<Id,List<Opportunity>> oppsByContact = GroupBy.ids('Contact__c', opps);
        for (Contact aContact : contacts) {
            Id newAccountId = newMap.get(aContact.Id).AccountId;
            if (oppsByContact.containsKey(aContact.Id)) {
                for (Opportunity anOpp : oppsByContact.get(aContact.Id)) {
                    anOpp.AccountId = newAccountId;
                }
            }
        }
        try {
            update opps;
        }
        catch (DMLException e) {
            for (Integer i = 0; i < e.getNumDml(); i++) {
                Opportunity failedOpp = opps[e.getDmlIndex(i)];
                Contact failedContact = newMap.get(failedOpp.Contact__c);
                failedContact.addError(e.getDmlMessage(i));
            }
        }
    }

    /**
    * @description Given a collection of old contacts, removes all related accounts
    * for which there are no longer any child contacts, or replace the address on
    * the account with the address of a remaining contact
    * @param triggerOld old contacts in the trigger context
    * @param triggerNewMap new contacts in the trigger context,
    *     required for adding errors in case of DML exception
    */
    @TestVisible
    private void removeOrUpdateOldAccounts(List<Contact> triggerOld, Map<Id,Contact> triggerNewMap) {
        Map<Id,List<Contact>> acctToContactsMap = GroupBy.ids('AccountId', triggerOld);
        List<Account> accounts = [
            SELECT Id,
                (SELECT Id, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,
                        Standardized_Street_1__c, Standardized_Street_2__c, Standardized_City__c,
                        Standardized_State__c, Standardized_Postal_Code__c, Standardized_Address_Message__c,
                        Address_Verification_Status__c
                        FROM Contacts ORDER BY CreatedDate DESC)
            FROM Account
            WHERE Id IN :acctToContactsMap.keySet()
        ];
        List<Account> accountsToDelete = new List<Account>();
        List<Account> accountsToUpdate = new List<Account>();
        for (Account anAccount : accounts) {
            if (anAccount.Contacts.isEmpty()) {
                accountsToDelete.add(anAccount);
            }
            else {
                accountsToUpdate.add(anAccount);
            }
        }

        // If in an update scenario, replace the old contacts in the map with new contacts so we can add errors to them
        if (triggerNewMap != null) {
            Map<Id,List<Contact>> oldAcctToNewContactsMap = new Map<Id,List<Contact>>();
            for (Id anAccountId : acctToContactsMap.keySet()) {
                if (!oldAcctToNewContactsMap.containsKey(anAccountId)) {
                    oldAcctToNewContactsMap.put(anAccountId, new List<Contact>());
                }
                for (Contact aContact : acctToContactsMap.get(anAccountId)) {
                    oldAcctToNewContactsMap.get(anAccountId).add(triggerNewMap.get(aContact.Id));
                }
            }
            acctToContactsMap = oldAcctToNewContactsMap;
        }
        updateAddressOfOldAccounts(accountsToUpdate, acctToContactsMap);
        deleteEmptyAccounts(accountsToDelete, acctToContactsMap);
    }

    @TestVisible
    private void removeOrUpdateOldAccounts(List<Contact> triggerOld) {
        removeOrUpdateOldAccounts(triggerOld, null);
    }

    @TestVisible
    private void rollupAccountMembershipTier(List<Contact> contactsWithMembershipTierChange) {
        rollupAccountMembershipTier(contactsWithMembershipTierChange, null);
    }

    @TestVisible
    private void rollupAccountMembershipTier(List<Contact> contactsWithMembershipTierChange, Map<Id,Contact> oldMap) {
        Set<Id> accountIds = new Set<Id>();
        for (Contact aContact : contactsWithMembershipTierChange) {
            accountIds.add(aContact.AccountId);
            if (oldMap != null) { // in case of reparent during update, rollup old parents as well
                accountIds.add(oldMap.get(aContact.Id).AccountId);
            }
        }

        List<Contact> allRelatedContacts = new List<Contact>([SELECT Id, Membership_Tier__c, AccountId
                FROM Contact WHERE AccountId in :accountIds]);

        Map <Id, String> accountTiers = new Map<Id, String>();  // Id is Account Id
        // Start by assuming all Accounts now have no memberships at all
        for (Contact aContact : allRelatedContacts) {
            accountTiers.put(aContact.AccountId, MembershipUtilities.ACCOUNT_MEMBERSHIP_TIER_NONE);
        }

        Map<String,List<Contact>> relatedContactsByTier = GroupBy.strings('Membership_Tier__c', allRelatedContacts);
        if (relatedContactsByTier.containsKey(MembershipUtilities.CONTACT_MEMBERSHIP_TIER_BASIC)) {
            for (Contact aContact : relatedContactsByTier.get(MembershipUtilities.CONTACT_MEMBERSHIP_TIER_BASIC)) {
                accountTiers.put(aContact.AccountId, MembershipUtilities.ACCOUNT_MEMBERSHIP_TIER_BASIC);
            }
        }
        if (relatedContactsByTier.containsKey(MembershipUtilities.CONTACT_MEMBERSHIP_TIER_LEADERSHIP)) {
            for (Contact aContact : relatedContactsByTier.get(MembershipUtilities.CONTACT_MEMBERSHIP_TIER_LEADERSHIP)) {
                accountTiers.put(aContact.AccountId, MembershipUtilities.ACCOUNT_MEMBERSHIP_TIER_LEADERSHIP);
            }
        }
        
        List <Account> accountsToUpdate = new List<Account>();
        for (Id accountId : accountTiers.keySet()) {
            Account newAccount = new Account(Id = accountId);
            newAccount.Membership_Tier__c = accountTiers.get(accountId);
            accountsToUpdate.add(newAccount);
        }

        try {
            update accountsToUpdate;
        }
        catch (DMLException e) {
            for (Integer i = 0; i < e.getNumDml(); i++) {
                Map<Id,List<Contact>> contactsByAccountId = GroupBy.ids('AccountId', contactsWithMembershipTierChange);
                Account failedAccount = accountsToUpdate[e.getDmlIndex(i)];
                for (Contact aContact : contactsByAccountId.get(failedAccount.Id)) {
                    aContact.addError(e.getDmlMessage(i));
                }
            }
        }
    }

    @TestVisible
    private void recalcMembershipLevel(List<Contact> contactsWithMembershipLevelChange, Map<Member_Level__c, String> memberLevelBenefitStrings) {

        // Get the map of Membership Levels to Strings showing those benefits.
        //Map<Member_Level__c, String> memberLevelBenefitStrings = ContactUtilities.getMemberBenefitStrings();

        List <Member_Level__c> memberLevels = new List<Member_Level__c>([SELECT Name, Member_Level_Value__c 
                 FROM Member_Level__c ORDER BY Member_Level_Value__c DESC]);

        // Then, calculate this Contact's Member Level and associated benefit string.
        for (Contact c : contactsWithMembershipLevelChange) {
            for (Member_Level__c memberLevel : memberLevels) {
              if (c.Total_Annualized_Donation_Value__c >= memberLevel.Member_Level_Value__c) {
                  c.Membership_Level__c = memberLevel.Id;
                  c.Membership_Benefits__c = memberLevelBenefitStrings.get(memberLevel);
                  break;
              }    
            }
        }

    }

    @TestVisible
    private List<Contact> filterContactsWithUpdatedTier(List<Contact> newList, Map<Id,Contact> oldMap) {
        List<Contact> contactsWithMembershipTierChange = new List<Contact>();
        for (Contact aContact : newList) {
            Contact oldContact = oldMap.get(aContact.Id);
            if ((aContact.Membership_Tier__c != oldContact.Membership_Tier__c) || 
                    aContact.AccountId != oldContact.AccountId) {
                contactsWithMembershipTierChange.add(aContact);
            }
        }   
        return contactsWithMembershipTierChange;
    }


    @TestVisible
    private List<Contact> filterContactsWithUpdatedLevel(List<Contact> newList, Map<Id,Contact> oldMap) {
        List<Contact> contactsWithMembershipLevelChange = new List<Contact>();
        for (Contact aContact : newList) {
            Contact oldContact = oldMap.get(aContact.Id);
            if (aContact.Sum_Annualized_Sustaining_Donations__c != oldContact.Sum_Annualized_Sustaining_Donations__c || 
                    aContact.Sum_Inactive_Last_Year_Donations__c != oldContact.Sum_Inactive_Last_Year_Donations__c ||
                    aContact.Sum_One_Time_Last_Year_Donations__c != oldContact.Sum_One_Time_Last_Year_Donations__c) {
                contactsWithMembershipLevelChange.add(aContact);
            }
        }   
        return contactsWithMembershipLevelChange;
    }
    
    @TestVisible
    private void updateAccountsForContacts(List<Contact> contacts) {
        Map<Id,Account> accounts = new Map<Id,Account>();
        for (Integer i = 0; i < contacts.size(); i++) {
            Account acctToUpdate = createAccountForContact(contacts[i]);
            acctToUpdate.Id = contacts[i].AccountId;
            accounts.put(acctToUpdate.Id, acctToUpdate);
        }
        updateRelatedAccounts(accounts, contacts);
    }

    @TestVisible
    private void updateRelatedAccounts(Map<Id,Account> accounts, List<Contact> contacts) {
        List<Account> acctList = accounts.values();
        try {
            update acctList;
        }
        catch (DMLException e) {
            Map<Id,List<Contact>> acctToContactsMap = GroupBy.ids('AccountId', contacts);
            for (Integer i = 0; i < e.getNumDml(); i++) {
                Account failedAcct = acctList[e.getDmlIndex(i)];
                for (Contact aContact : acctToContactsMap.get(failedAcct.Id)) {
                    aContact.addError(e.getDmlMessage(i));
                }
            }
        }
    }
    
    private void updateAddressOfOldAccounts(List<Account> accountsToUpdate, Map<Id,List<Contact>> acctToContactsMap) {
        List<Account> acctsToUpdate = new List<Account>();
        for (Account anAccount : accountsToUpdate) {
            Account acctToUpdate = createAccountForContact(anAccount.Contacts[0]);
            acctToUpdate.Id = anAccount.Id;
            acctsToUpdate.add(acctToUpdate);
        }
        try {
            update acctsToUpdate;
        }
        catch (DMLException e) {
            for (Integer i = 0; i < e.getNumDml(); i++) {
                Account failedAccount = acctsToUpdate[e.getDmlIndex(i)];
                for (Contact aContact : acctToContactsMap.get(failedAccount.Id)) {
                    aContact.addError(e.getDmlMessage(i));
                }
            }
        }
    }
}