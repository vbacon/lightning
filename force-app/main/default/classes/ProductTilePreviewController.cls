public with sharing class ProductTilePreviewController {
    @AuraEnabled
    public static Product2 getProduct(Id productId) {
        Product2 product = [SELECT Id, Name, ACD_Name__c, Type__c, Sub_Type__c, Product_Specifications__c,
                                    Image_URL__c, Tagline__c, One_Time_Price__c, Sustainer_Price__c, Description__c,
                                    Available_to_Ship_Date__c, Estimated_Shipping_Time__c, Live_on_Web__c
                                FROM Product2 where Id = :productId];
        return product;
    }
}
