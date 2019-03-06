@IsTest
public with sharing class BatchOrderTriggerHandlerTest {
    
    @testSetup
    static void testSetup() {
        final Integer NUM_OPPORTUNITIES = 10;
        List<Account> testAccount = TestUtilities.createAccounts(1, true);
        List<Account> testVendor = TestUtilities.createVendors(1, true);
        List<Opportunity> testOpps = TestUtilities.createOpportunities(testAccount, NUM_OPPORTUNITIES, true);
        List<Product2> testProducts = TestUtilities.createProducts(NUM_OPPORTUNITIES, testVendor[0].Id, true);
        List<PricebookEntry> pbes = [SELECT Id FROM PricebookEntry WHERE Product2Id IN :testProducts AND Pricebook2Id = :Test.getStandardPricebookId()];
        List<OpportunityLineItem> testOlis = TestUtilities.createOpportunityLineItems(testOpps, pbes, NUM_OPPORTUNITIES, true);
    }

    static testMethod void testUpdateRelatedOliStatus() {
        List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem];
        Batch_Order__c testBatchOrder = new Batch_Order__c();
        insert testBatchOrder;
        for (OpportunityLineItem anOli : olis) {
            anOli.Batch_Order__c = testBatchOrder.Id;
            anOli.Order_Status__c = 'Generated';
        }
        update olis;
        testBatchOrder.Status__c = 'Sent to Vendor';
        Test.startTest();
            update testBatchOrder;
        Test.stopTest();
        List<OpportunityLineItem> requeriedOlis = [SELECT Id, Order_Status__c FROM OpportunityLineItem WHERE Id IN :olis];
        for (OpportunityLineItem anOli : requeriedOlis) {
            System.assertEquals(testBatchOrder.Status__c, anOli.Order_Status__c, 'Expect all child OLI statuses to update to the parent batch order\'s status');
        }
    }
}