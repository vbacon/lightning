public class OpportunityServices {
    
    public static final INTEGER DAYS_TO_QUERY = 365;
    
    public static Opportunity cancelDonation(Opportunity opp) {
        opp = [SELECT Id,
                    (SELECT Id FROM Payments__r WHERE Status__c = :PaymentServices.PENDING_STATUS)
                FROM Opportunity
                WHERE Id = :opp.Id];
        for (Payment__c aPayment : opp.Payments__r) {
            aPayment.Status__c = PaymentServices.CANCELLED_STATUS;
        }
        opp.End_Reason__c = MembershipUtilities.END_REASON_CANCELLED;
        opp.Is_Cancelled__c = true;
        Savepoint sp = Database.setSavepoint();
        try {
            if (!opp.Payments__r.isEmpty()) update opp.Payments__r;
            update opp;
        }
        catch (DMLException e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getDmlMessage(0));
        }
        return opp;
    }
}