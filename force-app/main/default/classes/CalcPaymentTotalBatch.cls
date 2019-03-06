global class CalcPaymentTotalBatch implements Database.Batchable<sObject>, Database.Stateful {
	
    @TestVisible List<ID> failedList = new List<ID>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
      
        String query = 'SELECT Id, Opportunity__r.Contact__c, Opportunity__r.Is_Monthly__c, Amount__c' 
                        		+ ' FROM Payment__c'
                                + ' WHERE Status__c NOT IN (\'' + PaymentServices.CANCELLED_STATUS + '\''
                                + ' , \'' + PaymentServices.FAILED_STATUS + '\''
                                + ' , \'' + PaymentServices.PENDING_STATUS + '\''
                                + ' , \'' + PaymentServices.DECLINED_STATUS + '\')'
                                + ' AND Opportunity__r.CloseDate = LAST_N_DAYS:' + OpportunityServices.DAYS_TO_QUERY
                                // The next two lines cover one-time donations and inactive recurring donations, respectively.
                                + ' AND ((Opportunity__r.Is_Monthly__c = false)'
                                + ' OR (Opportunity__r.Is_Monthly__c = true AND Opportunity__r.Membership_Active__c = false))';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Payment__c> scope){
        
        Map<Id, Id> opportunityToContact = new Map<Id, Id>(); 
        for (Payment__c paym: scope) {
            opportunityToContact.put(paym.Opportunity__c, paym.Opportunity__r.Contact__c);
        }   
        Map<Id, Contact> contactsInBatch = new Map<Id, Contact>([SELECT Id, Sum_One_Time_Last_Year_Donations__c,
                Sum_Inactive_Last_Year_Donations__c
                FROM Contact WHERE Id IN :OpportunityToContact.values()]);
                
        for (Payment__c paym: scope) {
            if (paym.Opportunity__r.Is_Monthly__c == false) {  // Is a payment from a one-time donation
                contactsInBatch.get(opportunityToContact.get(paym.Opportunity__c)).Sum_One_Time_Last_Year_Donations__c = 
                    Utilities.add(contactsInBatch.get(opportunityToContact.get(paym.Opportunity__c)).Sum_One_Time_Last_Year_Donations__c, 
                    paym.Amount__c); 
            } else {  // Must be a payment associated with an inactive, recurring Opportunity given the initial query
                contactsInBatch.get(opportunityToContact.get(paym.Opportunity__c)).Sum_Inactive_Last_Year_Donations__c = 
                    Utilities.add(contactsInBatch.get(opportunityToContact.get(paym.Opportunity__c)).Sum_Inactive_Last_Year_Donations__c, 
                    paym.Amount__c); 
            }        
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
        if (!failedList.isEmpty()) {
            String failedListString;
        
            for (Id theId : failedList) {
                failedListString += theId + ', ';
            }

            ErrorLog.logError(null, 'CalcPaymentTotalBatch', failedListString);
            ErrorLog.commitErrors();
        }
        
        CalcOpportunityTotalBatch batch = new CalcOpportunityTotalBatch();
        database.executebatch(batch);
    }

}

