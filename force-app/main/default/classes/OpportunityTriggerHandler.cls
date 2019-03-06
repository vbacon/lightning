public with sharing class OpportunityTriggerHandler extends TriggerHandler {

    public override void beforeInsert() {
        populateStandardField((List<Opportunity>) Trigger.new);
        setPricebook((List<Opportunity>) Trigger.new);
    }

    public override void beforeUpdate() {
        List<Opportunity> filteredOpportunities = filterOpportunitiesForPricebookUpdate((List<Opportunity>) Trigger.new, (Map<Id,Opportunity>) Trigger.oldMap);
        setPricebook(filteredOpportunities);
    }

    public override void afterInsert() {
        // VWB - Below is Membership Tier which is being replaced by Membership Level. This takes up a lot of SOQL queries so it's being commented out.
        // rollupContactMembershipTier((List<Opportunity>) Trigger.new);

        Set<Id> oppIds = new Set<Id>();
        for(Opportunity opp : (List<Opportunity>) Trigger.new) {
            oppIds.add(opp.Id);
        }    
        ContactUtilities.recalcAnnualDonationValues((List<Opportunity>) Trigger.new);
    }

    public override void afterUpdate() {
        // VWB - Below is Membership Tier which is being replaced by Membership Level. This takes up a lot of SOQL queries so it's being commented out.
        // List<Opportunity> filteredUpdatedOpportunities = filterOpportunitiesForMembershipTierUpdate((List<Opportunity>)Trigger.new, (Map<Id,Opportunity>)Trigger.oldMap);
        // rollupContactMembershipTier(filteredUpdatedOpportunities);

        Set<Id> oppIds = new Set<Id>();
        for(Opportunity opp : (List<Opportunity>) Trigger.new) {
            oppIds.add(opp.Id);
        }    
        ContactUtilities.recalcAnnualDonationValues((List<Opportunity>) Trigger.new);
    }

    public override void afterDelete() {
        // rollupContactMembershipTier((List<Opportunity>)Trigger.old);
    }

    private List<Opportunity> filterOpportunitiesForPricebookUpdate(List<Opportunity> triggerNew, Map<Id,Opportunity> triggerOldMap) {
        List<Opportunity> oppsToReturn = new List<Opportunity>();
        for (Opportunity anOpp : triggerNew) {
            if (anOpp.Is_Monthly__c != triggerOldMap.get(anOpp.Id).Is_Monthly__c) {
                oppsToReturn.add(anOpp);
            }
        }
        return oppsToReturn;
    }

    // private List<Opportunity> filterOpportunitiesForMembershipTierUpdate(List<Opportunity> triggerNew, Map<Id,Opportunity> triggerOldMap) {
    //     List<Opportunity> filteredUpdatedOpportunities = new List<Opportunity>();
    //     for (Opportunity anOpportunity : triggerNew) {
    //         if ((anOpportunity.Membership_Tier__c != triggerOldMap.get(anOpportunity.Id).Membership_Tier__c) ||
    //                 anOpportunity.Membership_Active__c != triggerOldMap.get(anOpportunity.Id).Membership_Active__c) {
    //             filteredUpdatedOpportunities.add(anOpportunity);
    //         }
    //     }
    //     return filteredUpdatedOpportunities;
    // }

    private void setPricebook(List<Opportunity> opps) {
        for (Opportunity anOpp : opps) {
            if (!anOpp.Is_Monthly__c && PricebookServices.pricebooksByName.containsKey(PricebookServices.ONE_TIME)) {
                anOpp.Pricebook2Id = PricebookServices.pricebooksByName.get(PricebookServices.ONE_TIME);
            }
            else if (anOpp.Is_Monthly__c && PricebookServices.pricebooksByName.containsKey(PricebookServices.SUSTAINER)){
                anOpp.Pricebook2Id = PricebookServices.pricebooksByName.get(PricebookServices.SUSTAINER);
            }
            else {
                anOpp.Pricebook2Id = PricebookServices.pricebooksByName.get('Standard Price Book');
            }
        }
    }

    private void populateStandardField(List<Opportunity> opps) {
        for (Opportunity anOpp : opps) {
            anOpp.Amount = anOpp.Initial_Payment_Amount__c;
        }
    }

    // 2/20/19 - VWB - Membership Tier code no longer needed due to Membership Levels, commenting out.
    // @TestVisible
    // private void rollupContactMembershipTier(List<Opportunity> triggeredOpportunities) {
    //     Set<Id> contactIds = new Set<Id>();

    //     for (Opportunity anOpp : triggeredOpportunities) {
    //         if (anOpp.Contact__c != null) {
    //             contactIds.add(anOpp.Contact__c);
    //         }
    //     }

    //     Map<Id, String> contactTiers = MembershipUtilities.getNewMembershipTiersByContact(contactIds);

    //     List<Contact> contactsToUpdate = new List<Contact>();
    //     for (Id contactId : contactTiers.keySet()) {
    //         Contact newContact = new Contact(Id = contactId);
    //         newContact.Membership_Tier__c = contactTiers.get(contactId);
    //         contactsToUpdate.add(newContact);
    //     }

    //     try {
    //         update contactsToUpdate;
    //     }
    //     catch (DMLException e) {
    //         Map<Id,List<Opportunity>> oppsByContactId = GroupBy.ids('Contact__c', triggeredOpportunities);
    //         for (Integer i = 0; i < e.getNumDml(); i++) {
    //             Contact failedContact = contactsToUpdate[e.getDmlIndex(i)];
    //             for (Opportunity anOpp : oppsByContactId.get(failedContact.Id)) {
    //                 anOpp.addError(e.getDmlMessage(i));
    //             }
    //         }
    //     }
    // }

    // 2/20/19 - VWB - Not seeing this called anywhere, commenting out.
    // @TestVisible
    // private Set<Id> getRelatedContactIds(List<Opportunity> allOpportunities) {
    //     Set<Id> allRelatedContactIds = new Set<Id>();
    //     for (Opportunity anOpp : allOpportunities) {
    //         allRelatedContactIds.add(anOpp.Contact__c);
    //     }
    //     return allRelatedContactIds;
    // }
}