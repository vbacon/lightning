global class CalcOpportunityTotalBatch implements Database.Batchable<sObject>, Database.Stateful {
	
    @TestVisible List<ID> failedList = new List<ID>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
      
        // TO DO - In MER-730 two new fields will be generated to capture the amount of a one time donation
        // or the recurring payment amount.  The Initial_Payment_Amount__c field below should be changed to the 
        // field where the amount of the next recurring donation will be stored.
        String query = 'SELECT Id, Contact__c, Initial_Payment_Amount__c' 
                        		+ ' FROM Opportunity'
                                + ' WHERE Is_Monthly__c = true AND Membership_Active__c = true';
                                // Close Date is not relevant.  Only concern is if Opp is recurring and active.
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> scope){
        
        Map<Id, Id> opportunityToContact = new Map<Id, Id>(); 
        for (Opportunity opp : scope) {
            opportunityToContact.put(opp.Id, opp.Contact__c);
        }   
        
        Map<Id, Contact> contactsInBatch = new Map<Id, Contact>([SELECT Id, Sum_Annualized_Sustaining_Donations__c
                FROM Contact WHERE Id IN :OpportunityToContact.values()]);
        for (Opportunity opp : scope) {
            contactsInBatch.get(opportunityToContact.get(opp.Id)).Sum_Annualized_Sustaining_Donations__c = 
                Utilities.add(contactsInBatch.get(opportunityToContact.get(opp.Id)).Sum_Annualized_Sustaining_Donations__c, 
                opp.Initial_Payment_Amount__c * 12);
        }   

        Database.SaveResult[] sr = Database.Update(contactsInBatch.values(),false);

        for(Integer i=0;i<sr.size();i++){
            if (!sr.get(i).isSuccess()){
                // DML operation failed
                contactsInBatch.values().get(i);
                //capturing the failed payments
                failedList.add(contactsInBatch.values().get(i).Id);
            }
        }
    } 

    global void finish(Database.BatchableContext bc) {
        String failedListString;
        if (!failedList.isEmpty()) {
        
            for (Id theId : failedList) {
                failedListString += theId + ', ';
            }

            ErrorLog.logError(null, 'CalcOpportunityTotalBatch', failedListString);
            ErrorLog.commitErrors();
        }
        // Send admin an email upon success??
    }

}

