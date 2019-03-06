global class MembershipExpirationBatch implements Database.Batchable<sObject>, Database.Stateful{
    @TestVisible List<String> failedMembershipReasons = new List<String>();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Is_Monthly__c, Projected_End_Date__c,  End_Reason__c FROM Opportunity WHERE '
                      +'Projected_End_Date__c <= TODAY AND '
                      +'Membership_Active__c = true';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        for (Opportunity anOpp : scope) {
            MembershipUtilities.expireOpportunityMembership(anOpp);
        }
        List<Database.SaveResult> sr = Database.update(scope, false);
        for (Database.SaveResult aSaveResult : sr) {
            if (!aSaveResult.isSuccess()) {
                for (Database.Error err : aSaveResult.getErrors()) {
                    failedMembershipReasons.add(aSaveResult.getId() + '; ' + err.getMessage());
                }
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        if (!failedMembershipReasons.isEmpty()) {
            String failedMembershipReasonsString = String.join(failedMembershipReasons, '\n');

            ErrorLog.logError(null, 'MembershipExpirationBatch', failedMembershipReasonsString);
            ErrorLog.commitErrors();
        }
    }

}