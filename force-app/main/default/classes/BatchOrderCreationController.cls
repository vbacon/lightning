public with sharing class BatchOrderCreationController {

    @AuraEnabled
    public static Id getProductTemplateId(Id vendorId) {
        try {
            Account vendorAcct = [SELECT Id, Product_Order_Template__c FROM Account
                                        WHERE Id =: vendorId];
            if (vendorAcct.Product_Order_Template__c != null) {
                return vendorAcct.Product_Order_Template__c;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return null;
    }

    @AuraEnabled
    public static Boolean checkForNewOpportunityProducts(Id vendorId) {
        List<OpportunityLineItem> newOLIs = new List<OpportunityLineItem>();
        try {
            newOLIs = [SELECT Id FROM OpportunityLineItem WHERE Product2.Vendor__c = :vendorId AND Order_Status__c = 'New'];
            if (newOLIs.size() > 0) {
                return true;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return false;
    }

    @AuraEnabled
    public static void createBatchOrder(Id vendorId, Id templateId) {
        BatchOrderGenerator generator = new BatchOrderGenerator(vendorId, templateId); 
        generator.generateBatchOrders();
    }
}
