@IsTest
public class ProductTilesControllerTest {

    static final Integer NUM_PRODUCTS = 20;
    static final Integer MAX_ONE_TIME = 410;

    static List<Product2> scheduledProducts;
    static List<Product2> unscheduledProducts;
    static List<Product2> allProducts;
    static void testSetup() {
        Account vendor = TestUtilities.createVendors(1, true)[0];
        scheduledProducts = TestUtilities.createProducts(NUM_PRODUCTS, vendor.Id, false);
        unscheduledProducts = TestUtilities.createProducts(NUM_PRODUCTS, vendor.Id, false);
        allProducts = new List<Product2>(scheduledProducts);
        allProducts.addAll(unscheduledProducts);
        for (Integer i = 0; i < allProducts.size(); i++) {
            Product2 thisProduct = allProducts[i];
            thisProduct.One_Time_Price__c = MAX_ONE_TIME - ((i+1)*10);
            thisProduct.Sustainer_Price__c = thisProduct.One_Time_Price__c / 10;
            // VWB - Changing the below line to accommodate the new rule that Product must be Live on Web.
            //thisProduct.Live_on_Web__c = (Math.mod(i,2) != 0);
            thisProduct.Live_on_Web__c = true;
        }
        insert allProducts;
        List<Product_Schedule__c> productSchedules = new List<Product_Schedule__c>();
        for (Product2 aProduct : scheduledProducts) {
            for (Integer i = 1; i <= 4; i++) {
                Product_Schedule__c aSchedule = new Product_Schedule__c(Product__c = aProduct.Id);
                aSchedule.Quarter__c = String.valueOf(i);
                aSchedule.Fiscal_Year__c = String.valueOf(Date.today().year());
                productSchedules.add(aSchedule);
            }
            for (Integer i = 1; i <= 4; i++) {
                Product_Schedule__c aSchedule = new Product_Schedule__c(Product__c = aProduct.Id);
                aSchedule.Quarter__c = String.valueOf(i);
                aSchedule.Fiscal_Year__c = String.valueOf(Date.today().year() + 1);
                productSchedules.add(aSchedule);
            }
        }
        insert productSchedules;
    }

    static testMethod void testGetQualifyingProducts() {
        testSetup();
        Test.startTest();
            Map<Boolean,List<Product2>> responseMap = ProductTilesController.getQualifyingProducts();
        Test.stopTest();
        // VWB - Modifying below asserts by removing the divided by two.  All scheduled products now must by Live on Web.
        System.assertEquals(allProducts.size(), responseMap.get(true).size(), 'Expect each product that is live on web to be represented in monthly');
        System.assertEquals(allProducts.size(), responseMap.get(false).size(), 'Expect each product that is live on web to be represented in one time');
        Set<Id> scheduledProdIds = Pluck.ids(scheduledProducts);
        Set<Id> unscheduledProdIds = Pluck.ids(unscheduledProducts);
        List<Product2> monthlyProds = responseMap.get(true);
        for (Integer i = 0; i < monthlyProds.size() / 2; i++) {
            System.assert(scheduledProdIds.contains(monthlyProds[i].Id), 'Expect scheduled products to be returned first');
            if (i > 0) {
                System.assert(monthlyProds[i].Sustainer_Price__c <= monthlyProds[i-1].Sustainer_Price__c, 'Expect products with schedules to be sorted by price');
            }
        }
        for (Integer i = (monthlyProds.size() / 2 + 1); i < monthlyProds.size(); i++) {
            System.assert(unscheduledProdIds.contains(monthlyProds[i].Id), 'Expect unscheduled products to be returned second');
            if (i > (monthlyProds.size() / 2 + 1)) {
                System.assert(monthlyProds[i].Sustainer_Price__c <= monthlyProds[i-1].Sustainer_Price__c, 'Expect products with schedules to be sorted by price');
            }
        }
    }
}