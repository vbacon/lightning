global class DonationFormPaymentBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    @TestVisible List<ID> failedList = new List<ID>();
	
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Scheduled_Post_Date__c, Status__c, Opportunity__c, Opportunity__r.Id, Amount__c,' 
								+ ' Worldpay_Token__c'
                        		+ ' FROM Payment__c where Status__c=\'Pending\' and Scheduled_Post_Date__c = LAST_N_DAYS:7';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Payment__c> scope){
        List<Payment__c> pmtList = new List<Payment__c>(); 
        
        for (Payment__c payment : scope) {
           //Starting vantiv sale callout
            Payment__c thePayment = VantivUtilities.performSale(payment);
            pmtList.add(thePayment);   
        }
        Database.SaveResult[] sr = Database.Update(pmtList,false);
        
        for(Integer i=0;i<sr.size();i++){
            if (!sr.get(i).isSuccess()){
                // DML operation failed
                pmtList.get(i);
                //capturing the failed payments
                failedList.add(pmtList.get(i).Id);
            }
        }
    }  

    global void finish(Database.BatchableContext bc) {
        if (!failedList.isEmpty()) {
            String failedListString;
        
            for (Id theId : failedList) {
                failedListString += theId + ', ';
            }

            ErrorLog.logError(null, 'DonationFormPaymentBatch', failedListString);
            ErrorLog.commitErrors();
        }
    }

}
