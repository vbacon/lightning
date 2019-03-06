public class DonationCancelController {
    
    @AuraEnabled
    public static Opportunity getDonation(Id opportunityId) {
        return [SELECT Id, Is_Monthly__c, Is_Cancelled__c FROM Opportunity WHERE Id = :opportunityId];
    }

    @AuraEnabled
    public static Opportunity cancelDonation(Opportunity opp) {
        return OpportunityServices.cancelDonation(opp);
    }
}