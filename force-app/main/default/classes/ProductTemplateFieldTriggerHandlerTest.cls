@IsTest
private class ProductTemplateFieldTriggerHandlerTest {
    
    @testSetup 
    static void testSetup() {
        Product_Order_Template__c testPOT = new Product_Order_Template__c(Name = 'testPOT',
            Active__c = true);
        insert testPOT;

        Product_Template_Field__c testPTF1 = new Product_Template_Field__c(Field_Name__c = 'Opp Product: Id', 
                Field_Order__c = 1, Product_Order_Template__c = testPOT.Id);    
        Product_Template_Field__c testPTF2 = new Product_Template_Field__c(Field_Name__c = 'Opp Product: Name', 
                Field_Order__c = 2, Product_Order_Template__c = testPOT.Id);    
        Product_Template_Field__c testPTF3 = new Product_Template_Field__c(Field_Name__c = 'Opp Product: Quantity', 
                Field_Order__c = 3, Product_Order_Template__c = testPOT.Id);    
        Product_Template_Field__c testPTF4 = new Product_Template_Field__c(Field_Name__c = 'Opp Product: Date', 
                Field_Order__c = 4, Product_Order_Template__c = testPOT.Id);    
        insert new List<Product_Template_Field__c>{testPTF1, testPTF2, testPTF3, testPTF4};
    }
    
    static testMethod void testGoodInsert() {
    
        Product_Order_Template__c testPOT = [SELECT Id FROM Product_Order_Template__c LIMIT 1];
        
        Product_Template_Field__c newPTF = new Product_Template_Field__c(Field_Name__c = 'Contact: Email', 
            Field_Order__c = 5, Product_Order_Template__c = testPOT.Id);    
        
        Test.startTest();

        Database.SaveResult sr = Database.insert(newPTF, false);
        
        Test.stopTest();

        System.assert(sr.isSuccess(), 'Insert should happen without error.');

        List<Product_Template_Field__c> testPTFs = new List<Product_Template_Field__c>([SELECT Id 
                FROM Product_Template_Field__c WHERE Id != null]);
        Integer numOfPTFs = testPTFs.size();

        System.assertEquals(5, numOfPTFs, 'There should be 5 Product Template Fields at this point.');
    }

    static testMethod void testBadInsert_Order() {
    
        Product_Order_Template__c testPOT = [SELECT Id FROM Product_Order_Template__c LIMIT 1];
        
        Product_Template_Field__c newPTF = new Product_Template_Field__c(Field_Name__c = 'Contact: Email', 
            Field_Order__c = 3, Product_Order_Template__c = testPOT.Id);    
        
        Test.startTest();
        
        Database.SaveResult sr = Database.insert(newPTF, false);

        Test.stopTest();

        System.assert(!sr.isSuccess(), 'Insert should NOT happen.');

        List<Product_Template_Field__c> testPTFs = new List<Product_Template_Field__c>([SELECT Id 
                FROM Product_Template_Field__c WHERE Id != null]);
        Integer numOfPTFs = testPTFs.size();

        System.assertEquals(4, numOfPTFs, 'There should be 4 Product Template Fields at this point.');
    }

    static testMethod void testBadInsert_Field() {
    
        Product_Order_Template__c testPOT = [SELECT Id FROM Product_Order_Template__c LIMIT 1];
        
        Product_Template_Field__c newPTF = new Product_Template_Field__c(Field_Name__c = 'Opp Product: Id', 
            Field_Order__c = 5, Product_Order_Template__c = testPOT.Id);    
        
        Test.startTest();

        Database.SaveResult sr = Database.insert(newPTF, false);

        Test.stopTest();

        System.assert(!sr.isSuccess(), 'Insert should NOT happen.');

        List<Product_Template_Field__c> testPTFs = new List<Product_Template_Field__c>([SELECT Id 
                FROM Product_Template_Field__c WHERE Id != null]);
        Integer numOfPTFs = testPTFs.size();

        System.assertEquals(4, numOfPTFs, 'There should be 4 Product Template Fields at this point.');
    }

    static testMethod void testGoodUpdate_Order() {
    
        Product_Order_Template__c testPOT = [SELECT Id FROM Product_Order_Template__c LIMIT 1];
        
        Product_Template_Field__c existingPTF = [SELECT Id FROM Product_Template_Field__c 
            WHERE Field_Order__c = 1 LIMIT 1];
        
        existingPTF.Field_Order__c = 5;    
        
        Test.startTest();

        Database.SaveResult sr = Database.update(existingPTF, false);

        Test.stopTest();

        System.assert(sr.isSuccess(), 'Update should happen successfully.');

        List<Product_Template_Field__c> testPTFs = new List<Product_Template_Field__c>([SELECT Id 
                FROM Product_Template_Field__c WHERE Field_Order__c = 5]);
        Integer numOfPTFs = testPTFs.size();

        System.assertEquals(1, numOfPTFs, 'There should be a test PTF that now has Field Order 5.');
    }

    static testMethod void testGoodUpdate_Field() {
    
        Product_Order_Template__c testPOT = [SELECT Id FROM Product_Order_Template__c LIMIT 1];
        
        Product_Template_Field__c existingPTF = [SELECT Id FROM Product_Template_Field__c 
            WHERE Field_Name__c = 'Opp Product: Name' LIMIT 1];
        
        ExistingPTF.Field_Name__c = 'Contact: Email';    
        
        Test.startTest();

        Database.SaveResult sr = Database.update(existingPTF, false);

        Test.stopTest();

        System.assert(sr.isSuccess(), 'Update should happen successfully.');

        List<Product_Template_Field__c> testPTFs = new List<Product_Template_Field__c>([SELECT Id 
                FROM Product_Template_Field__c WHERE Field_Name__c = 'Contact: Email']);
        Integer numOfPTFs = testPTFs.size();

        System.assertEquals(1, numOfPTFs, 'There should be a test PTF that now has Field Name \'Contact: Email\'.');
    }

    static testMethod void testGoodUpdate_OrderAndField() {
    
        Product_Order_Template__c testPOT = [SELECT Id FROM Product_Order_Template__c LIMIT 1];
        
        Product_Template_Field__c existingPTF = [SELECT Id FROM Product_Template_Field__c 
            WHERE Field_Name__c = 'Opp Product: Name' LIMIT 1];
        
        ExistingPTF.Field_Name__c = 'Contact: Email';
        ExistingPTF.Field_Order__c = 5;    
        
        Test.startTest();
        
        Database.SaveResult sr = Database.update(existingPTF, false);

        Test.stopTest();

        System.assert(sr.isSuccess(), 'Update should happen successfully.');

        List<Product_Template_Field__c> testPTFs = new List<Product_Template_Field__c>([SELECT Id 
                FROM Product_Template_Field__c WHERE Field_Name__c = 'Contact: Email'
                AND Field_Order__c = 5]);
        Integer numOfPTFs = testPTFs.size();

        System.assertEquals(1, numOfPTFs, 'One PTF has Field Name = \'Contact: Email\' and Field Order = 5.');
    }

    static testMethod void testBadUpdate_Order() {
    
        Product_Order_Template__c testPOT = [SELECT Id FROM Product_Order_Template__c LIMIT 1];
        
        Product_Template_Field__c existingPTF = [SELECT Id FROM Product_Template_Field__c 
            WHERE Field_Order__c = 1 LIMIT 1];
        
        ExistingPTF.Field_Order__c = 2;    

        Test.startTest();

        Database.SaveResult sr = Database.update(existingPTF, false);

        Test.stopTest();

        System.assert(!sr.isSuccess(), 'Update should NOT happen successfully.');

        List<Product_Template_Field__c> testPTFs = new List<Product_Template_Field__c>([SELECT Id 
                FROM Product_Template_Field__c WHERE Field_Order__c = 2]);
        Integer numOfPTFs = testPTFs.size();

        System.assertEquals(1, numOfPTFs, 'Only 1 PTF should have Field Order = 2.');
    }
}
