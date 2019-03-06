global class ZeroOutAnnualContactFieldsBatch implements Database.Batchable<sObject> {
	
    global Database.QueryLocator start(Database.BatchableContext BC) {
      
        String query = 'SELECT Id, Sum_One_Time_Last_Year_Donations__c, Sum_Annualized_Sustaining_Donations__c,'
                                + ' Sum_Inactive_Last_Year_Donations__c'
                        		+ ' FROM Contact';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Contact> scope){
        
        List<Contact> contactsToUpdate = new List<Contact>();

        for (Contact c : scope) {
            c.Sum_One_Time_Last_Year_Donations__c = null;
            c.Sum_Annualized_Sustaining_Donations__c = null;
            c.Sum_Inactive_Last_Year_Donations__c = null;
            contactsToUpdate.add(c);
        }   
  
        try {
            update contactsToUpdate;
        } catch (DMLException ex) {
            ErrorLog.logError(ex, 'ZeroOutAnnualContactFields', 'Error updating Contact values.');
            ErrorLog.commitErrors();
        }    

    }  

    global void finish(Database.BatchableContext bc) {
        CalcPaymentTotalBatch batch = new CalcPaymentTotalBatch();
        database.executebatch(batch);
    }

}

