/*
    This class is used to test the funtionalities in Pluck class.
*/
@isTest
class PluckTest {

    @isTest 
    private static void testIdsWithList() {

        // Create a new account 
        Account acc = new Account();
        acc.Name = 'Test1';
        insert acc;
        List<Account> accList = new List<Account>{acc};
        Test.startTest();
            //Getting Id values from account list
            Set<Id> resultSet = Pluck.ids(accList);
        Test.stopTest();
        System.assert(!resultSet.isEmpty(),'We expect the resultSet should be populated.');
        System.assert(resultSet.contains(acc.Id),'We expect the value of accounts Id field to be contained within our set.'); 
    }

    @isTest 
    private static void testIds() {

        String field = 'Id';
        // Create a new account 
        Account acc = new Account();
        acc.Name = 'Test1';
        insert acc;
        List<Account> accList = new List<Account>{acc};
        Test.startTest();
            //Getting Id values from account list
            Set<Id> resultSet = Pluck.ids(field,accList);
        Test.stopTest();
        System.assert(!resultSet.isEmpty(),'We expect the resultSet should be populated.');
        System.assert(resultSet.contains(acc.Id),'We expect the value of accounts Id field to be contained within our set.'); 
    }

    @isTest 
    private static void testIdsWithSchemaField() {

        // Create a new account 
        Account acc = new Account();
        acc.Name = 'Test1';
        insert acc;
        List<Account> accList = new List<Account>{acc};
        Test.startTest();
            //Getting Id values from account list
            Set<Id> resultSet = Pluck.ids(Schema.Account.Id,accList);
        Test.stopTest();
        System.assert(!resultSet.isEmpty(),'We expect the resultSet should be populated.');
        System.assert(resultSet.contains(acc.Id),'We expect the value of accounts Id field to be contained within our set.'); 
    }
    
    @isTest 
    private static void testStrings() {

        String field = 'Name';
        // Create a new account 
        Account acc = new Account();
        acc.Name = 'Test3';
        insert acc;
        List<Account> accList   = new List<Account>{acc};
        Test.startTest();
            //Getting Name values from account list by passing field name as string
            Set<String> resultSet = Pluck.strings(field,accList);
        Test.stopTest();
        System.assert(!resultSet.isEmpty(),'We expect the resultSet should be populated.');
        System.assert(resultSet.contains(acc.Name),'We expect the value of accounts Name field to be contained within our set.'); 
    } 

    @isTest 
    private static void testStringsWithSchemaField() {
        
        // Create a new account 
        Account acc = new Account();
        acc.Name = 'Test5';
        acc.Industry = 'Banking';
        insert acc;
        List<Account> accList   = new List<Account>{acc};
        Test.startTest();
            //Getting field values as string from account list
            Set<String> resultSet = Pluck.strings(Schema.Account.Industry,accList);
        Test.stopTest();
        System.assert(!resultSet.isEmpty(),'We expect the resultSet should be populated.');
        System.assert(resultSet.contains(acc.Industry),'We expect the value of accounts Industry field to be contained within our set.');  
    } 

    @isTest 
    private static void testIntegers() {

        String field = 'NumberOfEmployees';
        // Create a new account
        Account acc = new Account();
        acc.Name = 'Test6';
        acc.NumberOfEmployees = 50;
        insert acc;
        List<Account> accList   = new List<Account>{acc};
        Test.startTest();
            //Getting field values as Integer from account list
            Set<Integer> resultSet = Pluck.integers(field,accList);
        Test.stopTest();   
        System.assert(!resultSet.isEmpty(),'We expect the resultSet should be populated.');
        System.assert(resultSet.contains(acc.NumberOfEmployees),'We expect the value of accounts NumberOfEmployees field to be contained within our set.');  
    } 

    @isTest 
    private static void testIntegersWithSchemaField() {

        // Create a new account
        Account acc = new Account();
        acc.Name = 'Test6';
        acc.NumberOfEmployees = 50;
        insert acc;
        List<Account> accList   = new List<Account>{acc};
        Test.startTest();
            //Getting field values as Integer from account list
            Set<Integer> resultSet = Pluck.integers(Schema.Account.NumberOfEmployees,accList);
        Test.stopTest();   
        System.assert(!resultSet.isEmpty(),'We expect the resultSet should be populated.');
        System.assert(resultSet.contains(acc.NumberOfEmployees),'We expect the value of accounts NumberOfEmployees field to be contained within our set.');  
    } 

    @isTest 
    private static void testDecimals() {

        String field = 'NumberOfEmployees';
        // Create a new account
        Account acc = new Account();
        acc.Name = 'Test6';
        acc.NumberOfEmployees = 50;
        insert acc;
        List<Account> accList   = new List<Account>{acc};
        Test.startTest();
            //Getting field values as Decimal from account list
            Set<Decimal> resultSet = Pluck.decimals(field,accList);
        Test.stopTest();  
        System.assert(!resultSet.isEmpty(),'We expect the resultSet should be populated.');
        System.assert(resultSet.contains(acc.NumberOfEmployees),'We expect the value of accounts NumberOfEmployees field to be contained within our set.');  
    } 
    @isTest 
    private static void testDecimalsWithSchemaField() {

        // Create a new account
        Account acc = new Account();
        acc.Name = 'Test6';
        acc.NumberOfEmployees = 50;
        insert acc;
        List<Account> accList   = new List<Account>{acc};
        Test.startTest();
            //Getting field values as Decimal from account list
            Set<Decimal> resultSet = Pluck.decimals(Schema.Account.NumberOfEmployees,accList);
        Test.stopTest();  
        System.assert(!resultSet.isEmpty(),'We expect the resultSet should be populated.');
        System.assert(resultSet.contains(acc.NumberOfEmployees),'We expect the value of accounts NumberOfEmployees field to be contained within our set.');  
    } 

    @isTest 
    private static void testDoubles() {
        
        String field = 'NumberOfEmployees';
        // Create a new account
        Account acc = new Account();
        acc.Name = 'Test6';
        acc.NumberOfEmployees = 50;
        insert acc;
        List<Account> accList   = new List<Account>{acc};
        Test.startTest();
            //Getting field values as Double from account list
            Set<Double> resultSet = Pluck.doubles(field,accList);
        Test.stopTest();
        System.assert(!resultSet.isEmpty(),'We expect the resultSet should be populated.');
        System.assert(resultSet.contains(acc.NumberOfEmployees),'We expect the value of accounts NumberOfEmployees field to be contained within our set.');       
    } 

    @isTest 
    private static void testDoublesWithSchemaField() {
        
        // Create a new account
        Account acc = new Account();
        acc.Name = 'Test6';
        acc.NumberOfEmployees = 50;
        insert acc;
        List<Account> accList   = new List<Account>{acc};
        Test.startTest();
            //Getting field values as Double from account list
            Set<Double> resultSet = Pluck.doubles(Schema.Account.NumberOfEmployees,accList);
        Test.stopTest();
        System.assert(!resultSet.isEmpty(),'We expect the resultSet should be populated.');
        System.assert(resultSet.contains(acc.NumberOfEmployees),'We expect the value of accounts NumberOfEmployees field to be contained within our set.');       
    } 

    @isTest 
    private static void testBooleans() {

        String field = 'IsActive';
        // Create a new product 
        Product2 prod = new Product2();
        prod.Name = 'Hoodie';
        prod.IsActive = true;
        insert prod;
        List<Product2> prodList = new List<Product2>{prod};
        Test.startTest();
            //Getting field values as Boolean from Product2 list
            Set<Boolean> resultSet = Pluck.booleans(field,prodList);
        Test.stopTest(); 
        System.assert(!resultSet.isEmpty(),'We expect the resultSet should be populated.');
        System.assert(resultSet.contains(prod.IsActive),'We expect the value of products IsActive field to be contained within our set.');    
    } 

    @isTest 
    private static void testBooleansWithSchemaField() {

        // Create a new product 
        Product2 prod = new Product2();
        prod.Name = 'Hoodie';
        prod.IsActive = true;
        insert prod;
        List<Product2> prodList = new List<Product2>{prod};
        Test.startTest();
            //Getting field values as Boolean from Product2 list
            Set<Boolean> resultSet = Pluck.booleans(Schema.Product2.IsActive,prodList);
        Test.stopTest(); 
        System.assert(!resultSet.isEmpty(),'We expect the resultSet should be populated.');
        System.assert(resultSet.contains(prod.IsActive),'We expect the value of products IsActive field to be contained within our set.');    
    } 
}