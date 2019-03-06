@IsTest
public with sharing class BatchOrderCreationControllerTest {

    @testSetup
    static void testSetup() {
        Product_Order_Template__c template1 = new Product_Order_Template__c(Name = 'Template 1',
            Active__c = true);
        insert template1;

        Product_Template_Field__c template1PTF1 = new Product_Template_Field__c(Field_Name__c = 'Opp Product: Id',
                Field_Order__c = 1, Product_Order_Template__c = template1.Id);
        Product_Template_Field__c template1PTF2 = new Product_Template_Field__c(Field_Name__c = 'Opp Product: Name',
                Field_Order__c = 2, Product_Order_Template__c = template1.Id);
        Product_Template_Field__c template1PTF3 = new Product_Template_Field__c(Field_Name__c = 'Opp Product: ProductCode',
                Field_Order__c = 3, Product_Order_Template__c = template1.Id);
        Product_Template_Field__c template1PTF4 = new Product_Template_Field__c(Field_Name__c = 'Opp Product: Quantity',
                Field_Order__c = 4, Product_Order_Template__c = template1.Id);
        Product_Template_Field__c template1PTF5 = new Product_Template_Field__c(Field_Name__c = 'Opp Product: Date',
                Field_Order__c = 5, Product_Order_Template__c = template1.Id);
        insert new List<Product_Template_Field__c>{
            template1PTF1, template1PTF2, template1PTF3, template1PTF4, template1PTF5
        };

        List<Account> vendorAccount1 = TestUtilities.createVendors(1, true);
        List<Account> vendorAccount2 = TestUtilities.createVendors(1, true);
        List<Account> nonVendorAccount = TestUtilities.createAccounts(1, true);

        vendorAccount1[0].Name = 'Vendor 1';
        vendorAccount1[0].Product_Order_Template__c = template1.Id;
        vendorAccount2[0].Name = 'Vendor 2';
        vendorAccount2[0].Product_Order_Template__c = template1.Id;
        nonVendorAccount[0].Name = 'Non Vendor';

        List<Account> theAccounts = new List<Account>{vendorAccount1[0], vendorAccount2[0], nonVendorAccount[0]};
        update theAccounts;

        List<Account> customerAccount = TestUtilities.createAccounts(1, true);
        List<Contact> customerContact = TestUtilities.createContacts(customerAccount);
        List<Opportunity> customerOpportunities = TestUtilities.createOpportunities(customerAccount, 1, true);

        List<Product2> vendorProduct1 = TestUtilities.createProducts(1, vendorAccount1[0].Id, true);

        Pricebook2 pb = TestUtilities.createPricebook('pb', true);
        customerOpportunities[0].Pricebook2Id = pb.Id;
        update customerOpportunities[0];

        List<PricebookEntry> pbEntries1 = TestUtilities.createPricebookEntries(vendorProduct1, pb.Id, true);

        List<OpportunityLineItem> newOLIs = TestUtilities.createOpportunityLineItems(customerOpportunities, pbEntries1, 1, true);
        List<OpportunityLineItem> generatedOLIs = TestUtilities.createOpportunityLineItems(customerOpportunities, pbEntries1, 1, true);

        for (OpportunityLineItem oli : newOLIs) {
            oli.Order_Status__c = 'New';
        }
        update newOLIs;

        for (OpportunityLineItem oli : newOLIs) {
            oli.Order_Status__c = 'Generated';
        }
        update generatedOLIs;
    }

    static testMethod void testGetProductTemplateId_Good() {
        Account theVendor = [SELECT Id FROM Account WHERE Name = 'Vendor 1'];

        Test.startTest();
            Id templateId = BatchOrderCreationController.getProductTemplateId(theVendor.Id);
        Test.stopTest();

        System.assertNotEquals(null, templateId, 'Should return a non-null template Id');
    }

    static testMethod void testGetProductTemplateId_Bad() {
        Account theVendor = [SELECT Id FROM Account WHERE Name = 'Non Vendor'];

        Test.startTest();
            Id templateId = BatchOrderCreationController.getProductTemplateId(theVendor.Id);
        Test.stopTest();

        System.assertEquals(null, templateId, 'Should return a null value');
    }

    static testMethod void checkForNewOpportunityProducts_Good() {
        Account theVendor = [SELECT Id FROM Account WHERE Name = 'Vendor 1'];

        Test.startTest();
            Boolean hasNewOLIs = BatchOrderCreationController.checkForNewOpportunityProducts(theVendor.Id);
        Test.stopTest();

        System.assert(hasNewOLIs, 'Should report that -New- OLIs do exist for this vendor.');
    }

    static testMethod void checkForNewOpportunityProducts_Bad() {
        Account theVendor = [SELECT Id FROM Account WHERE Name = 'Vendor 2'];

        Test.startTest();
            Boolean hasNewOLIs = BatchOrderCreationController.checkForNewOpportunityProducts(theVendor.Id);
        Test.stopTest();

        System.assert(!hasNewOLIs, 'Should report that NO -New- OLIs do exist for this vendor.');
    }

    static testMethod void testCreateBatchOrder() {
        Account theVendor = [SELECT Id FROM Account WHERE Name = 'Vendor 1'];
        Product_Order_Template__c theTemplate = [SELECT Id FROM Product_Order_Template__c WHERE Name = 'Template 1'];

        Test.startTest();
            BatchOrderCreationController.createBatchOrder(theVendor.Id, theTemplate.Id);
        Test.stopTest();

        List<ContentDocument> newContentDocuments = new List<ContentDocument>([SELECT Id from ContentDocument]);
        System.assertEquals(1, newContentDocuments.size(), 'There should one new Content Document.');

        List<Batch_Order__c> newBatchOrders = new List<Batch_Order__c>([SELECT Id from Batch_Order__c]);
        System.assertEquals(1, newBatchOrders.size(), 'There should one new Batch Order.');

        List<OpportunityLineItem> updatedOLIs = new List<OpportunityLineItem>([SELECT Id, Order_Status__c from OpportunityLineItem
                WHERE Order_Status__c = 'Generated']);
        System.assertEquals(2, updatedOLIs.size(), 'Two OLIs should now have a status of -Generated-.');  // One 'generated' OLI created for testing
    }
}
