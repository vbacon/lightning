@isTest
public with sharing class ProductTilePreviewControllerTest {
   static testMethod void testProductTilePreview() {
        List<Account> testVendors = TestUtilities.createVendors(1, true);
        List<Product2> testProduct = TestUtilities.createProducts(1, testVendors[0].Id, true);
        Test.startTest();
           Product2 product = ProductTilePreviewController.getProduct(testProduct[0].Id);
        Test.stopTest();
        System.assertEquals(testProduct[0].Id, product.Id);
    }
}
