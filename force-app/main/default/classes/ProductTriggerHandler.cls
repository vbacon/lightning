/**
* @author Adam Gallinat
* @date December 2017
*
* @description Trigger handler on Product2. Extends base TriggerHandler class
*/

public class ProductTriggerHandler extends TriggerHandler {

    public static final String MISSING_PBE_ERROR = 'Web store Pricebook Entries missing for this Product';
    public static final String EMPTY_FIELDS_ERROR = 'Fields required for activation are missing: ';
    public static List<Schema.SObjectField> requiredProductFields {
        get {
            if (requiredProductFields == null) {
                requiredProductFields = new List<Schema.SObjectField>{
                                            Product2.ACD_Name__c, Product2.Vendor__c,
                                            Product2.Distributor__c, Product2.Type__c,
                                            Product2.Image_Url__c, Product2.One_Time_Price__c,
                                            Product2.Sustainer_Price__c
                                        };
            }
            return requiredProductFields;
        }
        private set;
    }

    public static List<String> webPricebookNames = new List<String>{'OneTime', 'Monthly'};
    
    public override void afterInsert() {
        upsertPricebookEntries((List<Product2>) Trigger.new);
    }

    public override void beforeUpdate() {
        updateProductFieldValue((List<Product2>) Trigger.new, (Map<Id,Product2>) Trigger.oldMap, (Map<Id,Product2>) Trigger.newMap);
    }

    public override void afterUpdate() {
        List<Product2> filteredProducts = filterProductsByUpdatedPrice((List<Product2>) Trigger.new, (Map<Id,Product2>) Trigger.oldMap);
        upsertPricebookEntries(filteredProducts);
    }

    @TestVisible
    private void updateProductFieldValue(List<Product2> newList, Map<Id,Product2> oldMap, Map<Id,Product2> newMap) {
        Map<Id, Set<Id>> productIdMap = new Map<Id, Set<Id>>();
        Map<Id, Product_Schedule__c> existingScheduleMap = new Map<ID, Product_Schedule__c>( [
            SELECT Id, Product__r.Id FROM Product_Schedule__c
            WHERE Product__c IN :newMap.keySet()
        ]);
        for (Product_Schedule__c aProductSchedule : existingScheduleMap.values()) { 
            //Checking product id with ProductSchedule product records
            if (productIdMap.ContainsKey(aProductSchedule.Product__c)) {
                Set<Id> productIdSet = productIdMap.get(aProductSchedule.Product__c);
                //adding productschedule id from product 
                productIdSet.add(aProductSchedule.Id);
                productIdMap.put(aProductSchedule.Product__c, productIdSet);
            } else {
                //Putting product id(lookup field) and product schedule id in map
                productIdMap.put(aProductSchedule.Product__c, new Set<Id>{aProductSchedule.Id});
            }
        }
        Set<Id> productIdSetUpdate = new Set<Id> ();
        for (Product2 aProduct : newList) {
            Product2 oldProduct = oldMap.get(aProduct.Id);
            //if product contains product schedule records, preventing product field Live_On_Web__c value update from True to False 
            if (aProduct.Live_On_Web__c == false) {
                if (productIdMap.containsKey(aProduct.Id)) {
                    productIdSetUpdate = productIdMap.get(aProduct.Id);
                    // Throwing exception if product contains product schedule records
                    aProduct.addError('This product contains product schedule record'); 
                }
            }
        }   
    }

    
    @TestVisible
    private List<Product2> filterProductsByUpdatedPrice(List<Product2> newList, Map<Id,Product2> oldMap) {
        List<Product2> filteredProducts = new List<Product2>();
        for (Product2 aProduct : newList) {
            Product2 oldProduct = oldMap.get(aProduct.Id);
            if (aProduct.One_Time_Price__c != oldProduct.One_Time_Price__c ||
                aProduct.Sustainer_Price__c != oldProduct.Sustainer_Price__c) {
                    filteredProducts.add(aProduct);
            }
        }
        return filteredProducts;
    }

    public void upsertPricebookEntries(List<Product2> products) {
        // need standard pricebookentry before can create custom pricebookentries.
        List<PricebookEntry> pbesToUpsert = new List<PricebookEntry>();
        Map<Id, List<PricebookEntry>> existingPbes = GroupBy.ids('Product2Id', [
            SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry
            WHERE Product2Id IN :products
        ]);
        for (Product2 aProduct : products) {
            for (String aPricebookName : PricebookServices.pricebookToProductField.keySet()) {
                PricebookEntry newPbe = buildOrFindPbe(aProduct, aPricebookName, existingPbes.get(aProduct.Id));
                if (newPbe != null) pbesToUpsert.add(newPbe);
            }
        }
        try {
            upsert pbesToUpsert;
        }
        catch (DMLException e) {
            Map<Id,Product2> productMap = new Map<Id,Product2>(products);
            for (Integer i = 0; i < e.getNumDml(); i++) {
                PricebookEntry failedPbe = pbesToUpsert[e.getDmlIndex(i)];
                Product2 failedProduct = productMap.get(failedPbe.Product2Id);
                failedProduct.addError(e.getDmlMessage(i));
            }
        }
    }

    private PricebookEntry buildOrFindPbe(Product2 aProduct, String pricebookName, List<PricebookEntry> existingPbes) {
        PricebookEntry pbeToReturn;
        Id pricebookId = PricebookServices.pricebooksByName.get(pricebookName);
        if (pricebookId != null) {
            PricebookEntry existingPricebookEntry;
            if (existingPbes != null) {
                for (PricebookEntry aPbe : existingPbes) {
                    if (aPbe.Pricebook2Id == pricebookId) {
                        existingPricebookEntry = aPbe;
                        break;
                    }
                }
            }
            if (existingPricebookEntry == null) {
                pbeToReturn = new PricebookEntry();
                pbeToReturn.Product2Id = aProduct.Id;
                pbeToReturn.Pricebook2Id = pricebookId;
                pbeToReturn.IsActive = true;
                pbeToReturn.UseStandardPrice = false;
            }
            else {
                pbeToReturn = existingPricebookEntry;
            }
            Decimal price = (Decimal) aProduct.get(PricebookServices.pricebookToProductField.get(pricebookName));
            pbeToReturn.UnitPrice = price == null ? 0 : price;
        }
        return pbeToReturn;
    }
}
