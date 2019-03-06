public with sharing class ProductTemplateFieldTriggerHandler extends TriggerHandler {

    public override void beforeInsert() {
        checkForDuplicatesInsert((List<Product_Template_Field__c>)Trigger.new);
    }

    public override void beforeUpdate() {
        checkForDuplicatesUpdate(((List<Product_Template_Field__c>)Trigger.old), ((List<Product_Template_Field__c>)Trigger.new)); 
    }

    private void checkForDuplicatesInsert(List<Product_Template_Field__c> thePTFs) {
        // Only validate single-row inserts. The code is not bulk-safe
        if (thePTFs.size() > 1) return;

        List<Product_Template_Field__c> existingPTFs = new List<Product_Template_Field__c>([SELECT Id
                FROM Product_Template_Field__c 
                    WHERE (Field_Order__c = :thePTFs[0].Field_Order__c OR
                            Field_Name__c = :thePTFs[0].Field_Name__c)
                    AND Product_Order_Template__c = :thePTFs[0].Product_Order_Template__c]);
        If (existingPTFs.size() > 0) {
            thePTFs[0].AddError('Neither the Field Name nor the Field Order can already be present for this template.');
        }
    
    }

    private void checkForDuplicatesUpdate(List<Product_Template_Field__c> oldPTFs, List<Product_Template_Field__c> newPTFs) {
       // Only validate single-row updates. The code is not bulk-safe
        if (newPTFs.size() > 1) return;

        List<Product_Template_Field__c> existingPTFs = new List<Product_Template_Field__c>();
        
        // Need to determine what has been changed and query appropriately
        if (oldPTFs[0].Field_Order__c != newPTFs[0].Field_Order__c) {  // Order has been changed
            if (oldPTFs[0].Field_Name__c != newPTFs[0].Field_Name__c) {  // Order AND Field Name have been changed
                existingPTFs = ([SELECT Id FROM Product_Template_Field__c 
                    WHERE (Field_Order__c = :newPTFs[0].Field_Order__c OR
                            Field_Name__c = :newPTFs[0].Field_Name__c)
                        AND Product_Order_Template__c = :newPTFs[0].Product_Order_Template__c]);
            } else { // ONLY Field Order has changed
                existingPTFs = ([SELECT Id FROM Product_Template_Field__c 
                    WHERE Field_Order__c = :newPTFs[0].Field_Order__c
                        AND Product_Order_Template__c = :newPTFs[0].Product_Order_Template__c]);
            }
        } else {  //  Order has NOT been changed
            if (oldPTFs[0].Field_Name__c != newPTFs[0].Field_Name__c) {  // Only Field Name has been changed
                existingPTFs = ([SELECT Id FROM Product_Template_Field__c 
                    WHERE Field_Name__c = :newPTFs[0].Field_Name__c
                        AND Product_Order_Template__c = :newPTFs[0].Product_Order_Template__c]);
            } // Nothing will happen if nothing has changed.
        }

        If (existingPTFs != null && existingPTFs.size() > 0) {
            newPTFs[0].AddError('Neither the Field Name nor the Field Order can already be present for this template.');
        }

    }    

}
