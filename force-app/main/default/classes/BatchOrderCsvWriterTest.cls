@IsTest
public class BatchOrderCsvWriterTest {

    @testSetup
    static void testSetup() {
        Product_Order_Template__c emptyTemplate = new Product_Order_Template__c(
            Name = 'Empty Template',
            Active__c = true
        );

        Product_Order_Template__c completeTemplate = new Product_Order_Template__c(
            Name = 'Complete Template',
            Active__c = true
        );

        Product_Order_Template__c smallerTemplate = new Product_Order_Template__c(
            Name = 'Smaller Template',
            Active__c = true
        );

        insert new List<Product_Order_Template__c> {emptyTemplate, smallerTemplate, completeTemplate};

        Product_Template_Field__c oppProductId = new Product_Template_Field__c(Field_Name__c = 'Opp Product: Id',
                Field_Order__c = 1, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c oppProductName = new Product_Template_Field__c(Field_Name__c = 'Opp Product: Name',
                Field_Order__c = 2, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c oppProductProductCode = new Product_Template_Field__c(Field_Name__c = 'Opp Product: ProductCode',
                Field_Order__c = 3, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c oppProductQuantity = new Product_Template_Field__c(Field_Name__c = 'Opp Product: Quantity',
                Field_Order__c = 4, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c oppProductDate = new Product_Template_Field__c(Field_Name__c = 'Opp Product: Date',
                Field_Order__c = 5, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c oppProductCreatedDate = new Product_Template_Field__c(Field_Name__c = 'Opp Product: Created Date',
                Field_Order__c = 6, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c oppProductLastModDate = new Product_Template_Field__c(Field_Name__c = 'Opp Product: Last Mod Date',
                Field_Order__c = 7, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c contactFirstName = new Product_Template_Field__c(Field_Name__c = 'Contact: First Name',
                Field_Order__c = 12, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c contactLastName = new Product_Template_Field__c(Field_Name__c = 'Contact: Last Name',
                Field_Order__c = 13, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c contactEmail = new Product_Template_Field__c(Field_Name__c = 'Contact: Email',
                Field_Order__c = 14, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c productId = new Product_Template_Field__c(Field_Name__c = 'Product: Id',
                Field_Order__c = 15, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c productAvailableToShipDate = new Product_Template_Field__c(Field_Name__c = 'Product: Available To Ship Date',
                Field_Order__c = 16, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c productCost = new Product_Template_Field__c(Field_Name__c = 'Product: Cost',
                Field_Order__c = 17, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c productDistributor = new Product_Template_Field__c(Field_Name__c = 'Product: Distributor',
                Field_Order__c = 18, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c productEstimatedShipTime = new Product_Template_Field__c(Field_Name__c = 'Product: Estimated Ship Time',
                Field_Order__c = 19, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c productProductCode = new Product_Template_Field__c(Field_Name__c = 'Product: Product Code',
                Field_Order__c = 21, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c productStockKeepingUnit = new Product_Template_Field__c(Field_Name__c = 'Product: Stock Keeping Unit',
                Field_Order__c = 22, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c productShippingMethod = new Product_Template_Field__c(Field_Name__c = 'Product: Shipping Method',
                Field_Order__c = 23, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c productType = new Product_Template_Field__c(Field_Name__c = 'Product: Type',
                Field_Order__c = 24, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c opportunityId = new Product_Template_Field__c(Field_Name__c = 'Opportunity: Id',
                Field_Order__c = 25, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c opportunityAccountNumber = new Product_Template_Field__c(Field_Name__c = 'Opportunity: Account Number',
                Field_Order__c = 26, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c opportunityCloseDate = new Product_Template_Field__c(Field_Name__c = 'Opportunity: Close Date',
                Field_Order__c = 27, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c oppShippingStreet = new Product_Template_Field__c(Field_Name__c = 'Opportunity: Shipping Street',
                Field_Order__c = 8, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c oppShippingCity = new Product_Template_Field__c(Field_Name__c = 'Opportunity: Shipping City',
                Field_Order__c = 9, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c oppShippingState = new Product_Template_Field__c(Field_Name__c = 'Opportunity: Shipping State',
                Field_Order__c = 10, Product_Order_Template__c = completeTemplate.Id);
        Product_Template_Field__c oppShippingPostalCode = new Product_Template_Field__c(Field_Name__c = 'Opportunity: Shipping Postal Code',
                Field_Order__c = 11, Product_Order_Template__c = completeTemplate.Id);

        Product_Template_Field__c oppProductName_2 = new Product_Template_Field__c(Field_Name__c = 'Opp Product: Name',
                Field_Order__c = 1, Product_Order_Template__c = smallerTemplate.Id);
        Product_Template_Field__c oppShippingStreet2 = new Product_Template_Field__c(Field_Name__c = 'Opportunity: Shipping Street',
                Field_Order__c = 2, Product_Order_Template__c = smallerTemplate.Id);

        insert new List<Product_Template_Field__c>{
            oppProductId, oppProductName, oppProductProductCode, oppProductQuantity, oppProductDate,
            oppProductCreatedDate, oppProductLastModDate, oppShippingStreet, oppShippingCity,
            oppShippingState, oppShippingPostalCode, contactFirstName, contactLastName, contactEmail,
            productId, productAvailableToShipDate, productCost, productDistributor, productEstimatedShipTime,
            productProductCode, productStockKeepingUnit, productShippingMethod, productType, opportunityId,
            opportunityAccountNumber, opportunityCloseDate, oppProductName_2, oppShippingStreet2
        };

        Account vendorAccountComplete = TestUtilities.createVendors(1, false)[0];
        Account vendorAccountSmaller = TestUtilities.createVendors(1, false)[0];
        Account vendorAccountEmpty = TestUtilities.createVendors(1, false)[0];

        vendorAccountComplete.Name = 'Complete Vendor';
        vendorAccountSmaller.Name = 'Smaller Vendor';
        vendorAccountEmpty.Name = 'Empty Vendor';
        vendorAccountComplete.Product_Order_Template__c = completeTemplate.Id;
        vendorAccountSmaller.Product_Order_Template__c = smallerTemplate.Id;
        vendorAccountEmpty.Product_Order_Template__c = emptyTemplate.Id;

        insert new List<Account>{vendorAccountComplete, vendorAccountSmaller, vendorAccountEmpty};

        Account customerAccount = TestUtilities.createAccounts(1, true)[0];
        Contact customerContact = TestUtilities.createContacts(new List<Account>{customerAccount})[0];
        Opportunity customerOpportunity = TestUtilities.createOpportunities(new List<Contact>{customerContact}, 1, false)[0];

        Product2 vendorCompleteProduct = TestUtilities.createProducts(1, vendorAccountComplete.Id, false)[0];
        Product2 vendorSmallerProduct = TestUtilities.createProducts(1, vendorAccountSmaller.Id, false)[0];
        insert new List<Product2>{vendorCompleteProduct, vendorSmallerProduct};

        customerOpportunity.Pricebook2Id = Test.getStandardPricebookId();
        insert customerOpportunity;

        List<PricebookEntry> pbEntriesComplete = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2Id = :vendorCompleteProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId()];
        List<PricebookEntry> pbEntriesSmaller = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2Id = :vendorSmallerProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId()];

        List<OpportunityLineItem> completeOLIs = TestUtilities.createOpportunityLineItems(new List<Opportunity>{customerOpportunity}, pbEntriesComplete, 1, true);
        List<OpportunityLineItem> smallerOLIs = TestUtilities.createOpportunityLineItems(new List<Opportunity>{customerOpportunity}, pbEntriesSmaller, 1, true);
    }

    static testMethod void testFullFlow() {
        Product_Order_Template__c completeTemplate = [SELECT Id FROM Product_Order_Template__c WHERE Name = 'Complete Template'];
        Account vendor = [SELECT Id, Name FROM Account WHERE Name = 'Complete Vendor' LIMIT 1];
        List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem WHERE Product2.Vendor__c = :vendor.Id];

        Batch_Order__c batchOrder = new Batch_Order__c(Vendor__c = vendor.Id);
        insert batchOrder;

        Test.startTest();
            BatchOrderCsvWriter writer = new BatchOrderCsvWriter(vendor.Id, vendor.Name, completeTemplate.Id, olis, batchOrder.Id);
            System.enqueueJob(writer);
        Test.stopTest();

        List<ContentDocument> newContentDocuments = [SELECT Id from ContentDocument];
        System.assertEquals(1, newContentDocuments.size(), 'There should be a new Content Document');

        List<ContentDocumentLink> cdls = [
                SELECT LinkedEntityId
                FROM ContentDocumentLink
                WHERE ContentDocumentId = :newContentDocuments[0].Id
                AND LinkedEntityId = :batchOrder.Id
        ];
        System.assert(!cdls.isEmpty(), 'Expect the content document to be linked to the batch order');

        List<OpportunityLineItem> updatedOLIs = [
            SELECT Order_Status__c, Batch_Order__c from OpportunityLineItem
            WHERE Id IN :olis
        ];
        for (OpportunityLineItem anOli : updatedOlis) {
            System.assertEquals(OpportunityProductUtilities.GENERATED_ORDER_STATUS, anOli.Order_Status__c,
                    'The related products should have a status of generated');
            System.assertEquals(batchOrder.Id, anOli.Batch_Order__c,
                    'The related products should be assigned to a batch order');
        }
    }

    static testMethod void testEmptyTemplate() {
        Product_Order_Template__c emptyTemplate = [SELECT Id FROM Product_Order_Template__c WHERE Name='Empty Template' LIMIT 1];
        Account vendor = [SELECT Id, Name FROM Account WHERE Name = 'Empty Vendor' LIMIT 1];
        List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem WHERE Product2.Vendor__c = :vendor.Id];

        Batch_Order__c batchOrder = new Batch_Order__c(Vendor__c = vendor.Id);
        insert batchOrder;

        Test.startTest();
            BatchOrderCsvWriter writer = new BatchOrderCsvWriter(vendor.Id, vendor.Name, emptyTemplate.Id, olis, batchOrder.Id);
            System.enqueueJob(writer);
        Test.stopTest();

        List<ContentDocument> newContentDocuments = [SELECT Id from ContentDocument];
        System.assert(newContentDocuments.isEmpty(), 'There should be no new Content Documents');
        System.assert([SELECT Id FROM Error_Log__c].isEmpty(), 'There should be no error logs');

        List<OpportunityLineItem> updatedOLIs = [
            SELECT Order_Status__c, Batch_Order__c from OpportunityLineItem
            WHERE Id IN :olis
        ];
        for (OpportunityLineItem anOli : updatedOlis) {
            System.assertEquals(OpportunityProductUtilities.NEW_ORDER_STATUS, anOli.Order_Status__c,
                    'The related products should still have a status of generated');
            System.assertEquals(null, anOli.Batch_Order__c,
                    'The related products should not be assigned to a batch order');
        }
    }

    static testMethod void testWriteHeaderRow() {
        Product_Order_Template__c smallerTemplate = [SELECT Id FROM Product_Order_Template__c WHERE Name='Smaller Template' LIMIT 1];
        List<Product_Template_Field__c> templateFields = new List<Product_Template_Field__c>([
            SELECT Field_Name__c, Field_Order__c FROM Product_Template_Field__c
            WHERE Product_Order_Template__c = :smallerTemplate.Id
            ORDER BY Field_Order__c
        ]);
        Account vendor = [SELECT Id, Name FROM Account WHERE Name = 'Smaller Vendor' LIMIT 1];

        BatchOrderCsvWriter writer = new BatchOrderCsvWriter(vendor.Id, vendor.Name, smallerTemplate.Id, null, null);
        Test.startTest();
            String headerLine = writer.generateHeaderRow(templateFields);
        Test.stopTest();

        System.assertEquals(headerLine, 'Opp Product: Name, Opportunity: Shipping Street\n',
                'Expect header row to contain specified field names separated by commas, terminated by a newline');
    }

    static testMethod void testWriteBodyRows() {
        Product_Order_Template__c smallerTemplate = [SELECT Id FROM Product_Order_Template__c WHERE Name='Smaller Template' LIMIT 1];
        List<Product_Template_Field__c> templateFields = [
            SELECT Field_Name__c, Field_Order__c FROM Product_Template_Field__c
            WHERE Product_Order_Template__c = :smallerTemplate.Id
            ORDER BY Field_Order__c
        ];
        Account vendor = [SELECT Id, Name FROM Account WHERE Name = 'Smaller Vendor' LIMIT 1];
        List<OpportunityLineItem> olis = [
            SELECT Name, Opportunity.Shipping_Street__c
            FROM OpportunityLineItem
            WHERE Product2.Vendor__c = :vendor.Id LIMIT 1
        ];

        Batch_Order__c batchOrder = new Batch_Order__c(Vendor__c = vendor.Id);
        insert batchOrder;

        Map<String, String> labelToApiName = new Map<String, String>();
        Map<String, String> labelToDataType = new Map<String, String>();
        Product_Template_Name_Map__mdt[] PTN_Mappings = [
            SELECT Field_Label__c, Field_API_Name__c, Data_Type__c
            FROM Product_Template_Name_Map__mdt
        ];
        for (Product_Template_Name_Map__mdt PTN : PTN_Mappings) {
            labelToApiName.put(PTN.Field_Label__c, PTN.Field_API_Name__c);
            labelToDataType.put(PTN.Field_Label__c, PTN.Data_Type__c);
        }

        //TODO: requery OLIs, and update assertion
        BatchOrderCsvWriter writer = new BatchOrderCsvWriter(vendor.Id, vendor.Name, smallerTemplate.Id, olis, batchOrder.Id);
        Test.startTest();
            String bodyRow = writer.generateBodyRows(olis, templateFields, labelToApiName, labelToDataType);
        Test.stopTest();

        System.assertEquals(bodyRow, olis[0].Name + ', ' + olis[0].Opportunity.Shipping_Street__c + '\n',
            'Expect body row to contain specified fields separated by commas, terminated by a newline');
    }
}
