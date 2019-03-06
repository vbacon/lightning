@IsTest
public class ProductTriggerHandlerTest {

    // todo: move this getter into testutils
    static Map<String, Id> productRecordTypes {
        get {
            List<RecordType> recordTypes = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Product2' AND IsActive = true];
            Map<String, Id> returnMap = new Map<String, Id>();
            for (RecordType aRT : recordTypes) {
                returnMap.put(aRT.DeveloperName, aRT.Id);
            }
            return returnMap;
        }
        private set;
    }

    @testSetup
    static void testSetup() {
        Pricebook2 testOneTimePb = new Pricebook2(Name = PricebookServices.ONE_TIME);
        Pricebook2 testSustainerPb = new Pricebook2(Name = PricebookServices.SUSTAINER);
        insert new List<Pricebook2>{testOneTimePb, testSustainerPb};
    }

    static testMethod void testInsertPricebookEntries() {
        Integer numProducts = 5;
        Account testVendor = TestUtilities.createVendors(1, true)[0];
        List<Product2> newProducts = TestUtilities.createProducts(numProducts, testVendor.Id, false);
        Test.startTest();
            insert newProducts;
        Test.stopTest();
        List<PricebookEntry> pbes = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id IN :newProducts];
        System.assertEquals((numProducts * 3), pbes.size(), 'Expect one pricebookentry to be created for each product for one time, sustainer, and standard');
        Map<Id,Product2> productMap = new Map<Id,Product2>(newProducts);
        Map<Id,List<PricebookEntry>> pbesByPricebookId = GroupBy.ids('Pricebook2Id', pbes);
        for (PricebookEntry aPbe : pbesByPricebookId.get(PricebookServices.pricebooksByName.get(PricebookServices.ONE_TIME))) {
            System.assertEquals(aPbe.UnitPrice, productMap.get(aPbe.Product2Id).One_Time_Price__c,
                'Expect the one time pricebook entry\'s unit price to map to the products one time price');
        }
        for (PricebookEntry aPbe : pbesByPricebookId.get(PricebookServices.pricebooksByName.get(PricebookServices.SUSTAINER))) {
            System.assertEquals(aPbe.UnitPrice, productMap.get(aPbe.Product2Id).Sustainer_Price__c,
                'Expect the sustainer pricebook entry\'s unit price to map to the products sustainer price');
        }
    }

    static testMethod void testUpdatePricebookEntries() {
        Integer numProducts = 5;
        Account testVendor = TestUtilities.createVendors(1, true)[0];
        List<Product2> newProducts = TestUtilities.createProducts(numProducts, testVendor.Id, true);
        List<PricebookEntry> pbes = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id IN :newProducts];
        for (Product2 aProduct : newProducts) {
            aProduct.One_Time_Price__c = aProduct.One_Time_Price__c * 2;
            aProduct.Sustainer_Price__c = aProduct.Sustainer_Price__c * 2;
        }
        Test.startTest();
            update newProducts;
        Test.stopTest();
        List<PricebookEntry> updatedPbes = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id IN :newProducts];
        System.assertEquals(pbes.size(), updatedPbes.size(), 'Expect the same number of pricebookentries before and after the update');
        Set<Id> originalPbeIds = Pluck.ids(pbes);
        for (PricebookEntry aPbe : updatedPbes) {
            System.assert(originalPbeIds.contains(aPbe.Id), 'Expect the pricebook entries to have the same ids before and after the update');
        }
        Map<Id,Product2> productMap = new Map<Id,Product2>(newProducts);
        Map<Id,List<PricebookEntry>> pbesByPricebookId = GroupBy.ids('Pricebook2Id', updatedPbes);
        for (PricebookEntry aPbe : pbesByPricebookId.get(PricebookServices.pricebooksByName.get(PricebookServices.ONE_TIME))) {
            System.assertEquals(aPbe.UnitPrice, productMap.get(aPbe.Product2Id).One_Time_Price__c,
                'Expect the one time pricebook entry\'s unit price to map to the products one time price');
        }
        for (PricebookEntry aPbe : pbesByPricebookId.get(PricebookServices.pricebooksByName.get(PricebookServices.SUSTAINER))) {
            System.assertEquals(aPbe.UnitPrice, productMap.get(aPbe.Product2Id).Sustainer_Price__c,
                'Expect the sustainer pricebook entry\'s unit price to map to the products sustainer price');
        }
    }

    static testMethod void updateProductFieldValueFail() {
        Integer numProducts = 1;
        Account testVendor = TestUtilities.createVendors(1, true)[0];
        List<Product2> newProducts = TestUtilities.createProducts(numProducts, testVendor.Id, true);
        Product_Schedule__c theProductSchedule = new Product_Schedule__c();
            theProductSchedule.Fiscal_Year__c = '2020';
            theProductSchedule.Product__c = newProducts[0].Id ;
            theProductSchedule.Start_Date__C = Date.today();
            theProductSchedule.End_Date__c = Date.today() + 1;
        insert theProductSchedule;	
        
        for (Product2 aProduct : newProducts) {
            aProduct.Live_On_Web__c = false;
        }
        Test.startTest();
        try {
            update newProducts;
        } catch(Exception e) {
            System.debug(e.getMessage());
            System.Assert(e.getMessage().contains('Update failed'), 'Product with product schedule should not update');
        }
        Test.stopTest();
        List<Product2> products = [SELECT Id, Live_On_Web__c FROM Product2 WHERE Id IN :newProducts];
        System.assertEquals(true, products[0].Live_On_Web__c, 'Expect Product field Live_On_Web__c should not be updated if product contains product schedule');
    }

    static testMethod void updateProductFieldValueSuccess() {
        Integer numProducts = 1;
        Account testVendor = TestUtilities.createVendors(1, true)[0];
        List<Product2> newProducts = TestUtilities.createProducts(numProducts, testVendor.Id, true);        
        for (Product2 aProduct : newProducts) {
            aProduct.Live_On_Web__c = false;
        }
        Test.startTest();
            update newProducts;
        Test.stopTest();
        List<Product2> products = [SELECT Id, Live_On_Web__c FROM Product2 WHERE Id IN :newProducts];
        System.assertEquals(false, products[0].Live_On_Web__c, 'Expect Product field Live_On_Web__c should be updated');
    }
}
