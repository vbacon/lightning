public with sharing class MemberBenefitLevelTriggerHandler extends TriggerHandler {

    public override void beforeInsert() {
        checkForDuplicatesInsert((List<Member_Benefit_Level__c>)Trigger.new);
    }

    public override void beforeUpdate() {
        checkForDuplicatesUpdate(((List<Member_Benefit_Level__c>)Trigger.old), ((List<Member_Benefit_Level__c>)Trigger.new)); 
    }

    private void checkForDuplicatesInsert(List<Member_Benefit_Level__c> theMBLs) {
        // Only validate single-row inserts. The code is not bulk-safe
        if (theMBLs.size() > 1) return;

        List<Member_Benefit_Level__c> existingMBLs = new List<Member_Benefit_Level__c>([SELECT Id
                FROM Member_Benefit_Level__c 
                WHERE Member_Benefit__c = :theMBLs[0].Member_Benefit__c 
                AND Member_Level__c = :theMBLs[0].Member_Level__c]);
        If (existingMBLs.size() > 0) {
            theMBLs[0].AddError('A Member Benefit Level with this Level and this Benefit already exists.');
        }
    }

    private void checkForDuplicatesUpdate(List<Member_Benefit_Level__c> oldMBLs, List<Member_Benefit_Level__c> newMBLs) {
       // Only validate single-row updates. The code is not bulk-safe
        if (newMBLs.size() > 1) return;

        List<Member_Benefit_Level__c> existingMBLs = new List<Member_Benefit_Level__c>();

        existingMBLs = ([SELECT Id FROM Member_Benefit_Level__c 
                WHERE Member_Level__c = :newMBLs[0].Member_Level__c 
                AND Member_Benefit__c = :newMBLs[0].Member_Benefit__c]);

        if (existingMBLs != null && existingMBLs.size() > 0) {
            newMBLs[0].AddError('A Member Benefit Level with this Level and this Benefit already exists.');
        }
    }    

}

