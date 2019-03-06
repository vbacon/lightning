@isTest
public class BatchOrderGeneratorTest {

    @testSetup
    static void testSetup() {

        Product_Order_Template__c template1 = new Product_Order_Template__c(Name = 'Template 1',
            Active__c = true);
        Product_Order_Template__c template2 = new Product_Order_Template__c(Name = 'Template 2',
            Active__c = true);
        insert new List<Product_Order_Template__c>{template1, template2};

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
        Product_Template_Field__c template2PTF1 = new Product_Template_Field__c(Field_Name__c = 'Opp Product: Name',
                Field_Order__c = 1, Product_Order_Template__c = template2.Id);
        Product_Template_Field__c template2PTF2 = new Product_Template_Field__c(Field_Name__c = 'Opportunity: Shipping Street',
                Field_Order__c = 2, Product_Order_Template__c = template2.Id);
        Product_Template_Field__c template2PTF3 = new Product_Template_Field__c(Field_Name__c = 'Product: Available To Ship Date',
                Field_Order__c = 3, Product_Order_Template__c = template2.Id);
        Product_Template_Field__c template2PTF4 = new Product_Template_Field__c(Field_Name__c = 'Product: Cost',
                Field_Order__c = 4, Product_Order_Template__c = template2.Id);
        Product_Template_Field__c template2PTF5 = new Product_Template_Field__c(Field_Name__c = 'Product: Estimated Ship Time',
                Field_Order__c = 5, Product_Order_Template__c = template2.Id);
        insert new List<Product_Template_Field__c>{
            template1PTF1, template1PTF2, template1PTF3, template1PTF4, template1PTF5,
            template2PTF1, template2PTF2, template2PTF3, template2PTF4, template2PTF5
        };

        List<Account> vendors = TestUtilities.createVendors(2, false);
        Account vendor1 = vendors[0];
        Account vendor2 = vendors[1];
        vendor1.Name = 'Vendor 1';
        vendor2.Name = 'Vendor 2';
        vendor1.Product_Order_Template__c = template1.Id;
        vendor2.Product_Order_Template__c = template2.Id;
        insert vendors;

        Account household = TestUtilities.createAccounts(1, true)[0];
        Contact donor = TestUtilities.createContacts(new List<Account>{household}, 1, true)[0];
        Opportunity donation = TestUtilities.createOpportunities(new List<Contact>{donor}, 1, false)[0];
        donation.Pricebook2Id = Test.getStandardPricebookId();
        insert donation;

        Product2 vendor1Product = TestUtilities.createProducts(1, vendor1.Id, false)[0];
        Product2 vendor2Product = TestUtilities.createProducts(1, vendor2.Id, false)[0];
        insert new List<Product2>{vendor1Product, vendor2Product};

        Map<Id,List<PricebookEntry>> pbEntries = GroupBy.ids('Product2Id', [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry]);

        OpportunityLineItem product1Oli = TestUtilities.createOpportunityLineItems(new List<Opportunity>{donation}, pbEntries.get(vendor1Product.Id), 1, false)[0];
        OpportunityLineItem product2Oli = TestUtilities.createOpportunityLineItems(new List<Opportunity>{donation}, pbEntries.get(vendor2Product.Id), 1, false)[0];
        product1Oli.Order_Status__c = OpportunityProductUtilities.NEW_ORDER_STATUS;
        product2Oli.Order_Status__c = OpportunityProductUtilities.NEW_ORDER_STATUS;
        insert new List<OpportunityLineItem>{product1Oli, product2Oli};
    }

    static testMethod void multipleVendorTest() {

        Test.startTest();
            BatchOrderGenerator generator = new BatchOrderGenerator();
            generator.generateBatchOrders();
        Test.stopTest();

        List<ContentDocument> newContentDocuments = new List<ContentDocument>([SELECT Id from ContentDocument]);
        System.assertEquals(2, newContentDocuments.size(), 'There should be two new Content Documents');

        List<Batch_Order__c> newBatchOrders = new List<Batch_Order__c>([SELECT Id from Batch_Order__c]);
        System.assertEquals(2, newBatchOrders.size(), 'There should be two new atttachments');

        List<OpportunityLineItem> updatedOLIs = new List<OpportunityLineItem>([SELECT Id, Order_Status__c from OpportunityLineItem
                WHERE Order_Status__c = :OpportunityProductUtilities.GENERATED_ORDER_STATUS]);
        System.assertEquals(2, updatedOLIs.size(), 'Two OLIs should now have a status of -Generated-');
    }

    static testMethod void singleVendorTest() {
        Account theVendor = [SELECT Id FROM Account WHERE Name = 'Vendor 1'];
        Product_Order_Template__c theTemplate = [SELECT Id FROM Product_Order_Template__c WHERE Name = 'Template 1'];

        Test.startTest();
            BatchOrderGenerator generator = new BatchOrderGenerator(theVendor.Id, theTemplate.Id);
            generator.generateBatchOrders();
        Test.stopTest();

        List<ContentDocument> newContentDocuments = new List<ContentDocument>([SELECT Id from ContentDocument]);
        System.assertEquals(1, newContentDocuments.size(), 'There should one new Content Document.');

        List<Batch_Order__c> newBatchOrders = new List<Batch_Order__c>([SELECT Id from Batch_Order__c]);
        System.assertEquals(1, newBatchOrders.size(), 'There should one new Batch Order.');

        List<OpportunityLineItem> updatedOLIs = new List<OpportunityLineItem>([SELECT Id, Order_Status__c,
                Batch_Order__c FROM OpportunityLineItem WHERE Order_Status__c = :OpportunityProductUtilities.GENERATED_ORDER_STATUS]);
        System.assertEquals(1, updatedOLIs.size(), 'One OLI should now have a status of -Generated-');
        System.assertNotEquals(null, updatedOLIs[0].Batch_Order__c, 'Linked Batch Order should not be null.');
    }
}
