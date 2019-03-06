/*
    This class is used to test the funtionalities in GroupBy class.
*/
@isTest
class GroupByTest {

    @isTest 
    private static void testIds() {

        String field = 'AccountId';
        List<Account> accList = new List<Account>();
        for(Integer i=0;i<10;i++) {
            Account acct = new Account(Name='TestAccount' + i);
            accList.add(acct);
        }
        insert accList;
        List<Contact> conList = new List<Contact>();
        // For each account just inserted, add opportunities
        for (Account acc : accList) {
            for(Integer j=0;j<10;j++){
                conList.add(new Contact(FirstName='test'+j,
                                    LastName='Smith',
                                    Phone='123.555.1212',
                                    AccountId=acc.Id));
            }
        }
        // Insert all contacts for all accounts.
        insert conList;
        List<Contact> contactList = [select Id,AccountId from contact];
        Test.startTest();
            //Getting AccountId values from contact list
            Map<Id,List<SObject>> resultMap = GroupBy.ids(field,contactList);
        Test.stopTest();
        System.assert(!resultMap.isEmpty(),'We expect the resultMap should be populated.');
        for(Account acc : accList){
            System.assert(resultMap.containsKey(acc.Id),
                    'We expect the value of accountId field to be contained within our map.'); 
        }
    }

    @isTest 
    private static void testIdsWithSchemaField() {

        List<Account> accList = new List<Account>();
        for(Integer i=0;i<10;i++) {
            Account acct = new Account(Name='TestAccount' + i);
            accList.add(acct);
        }
        insert accList;
        List<Contact> conList = new List<Contact>();
        // For each account just inserted, add contacts
        for (Account acc : accList) {
            for(Integer j=0;j<10;j++){
                conList.add(new Contact(FirstName='test'+j,
                                    LastName='Smith',
                                    Phone='123.555.1212',
                                    AccountId=acc.Id));
            }
        }
        insert conList;
        List<Contact> contactList = [select Id,AccountId from contact];
        Test.startTest();
            //Getting AccountId values from contact list
             Map<Id,List<SObject>> resultMap = GroupBy.ids(Schema.Contact.AccountId,contactList);
        Test.stopTest();
        System.assert(!resultMap.isEmpty(),'We expect the resultMap should be populated.');
        for(Account acc : accList){
             System.assert(resultMap.containsKey(acc.Id),
                    'We expect the value of accountId field to be contained within our map.'); 
        }
    }

    @isTest 
    private static void testStrings() {

        String field = 'Industry';
        List<Account> accList = new List<Account>();
        for(Integer i=0;i<10;i++) {
            Account acct = new Account(Name='TestAccount' + i,Industry ='KQED');
            accList.add(acct);
        }
        insert accList;
        List<Account> accountList = [select Id,Industry from account];
        Test.startTest();
            //Getting Industry values from account list by passing field name as string
            Map<String,List<SObject>> resultMap = GroupBy.strings(field,accountList);
        Test.stopTest();
        System.assert(!resultMap.isEmpty(),'We expect the resultMap should be populated.');
        for(Account acct : accountList){
            System.assert(resultMap.containsKey(acct.Industry),
                    'We expect the value of accounts Industry field to be contained within our map.'); 
        }
    } 

    @isTest 
    private static void testStringsWithSchemaField() {
        
        List<Account> accList = new List<Account>();
        for(Integer i=0;i<10;i++) {
            Account acct = new Account(Name='TestAccount' + i,Industry ='KQED');
            accList.add(acct);
        }
        insert accList;
        List<Account> accountList = [select Id,Industry from account];
        Test.startTest();
            //Getting Industry values from account list by passing field name as string
            Map<String,List<SObject>> resultMap = GroupBy.strings(Schema.Account.Industry,accList);
        Test.stopTest();
        System.assert(!resultMap.isEmpty(),'We expect the resultMap should be populated.');
        for(Account acct : accountList){
            System.assert(resultMap.containsKey(acct.Industry),
                    'We expect the value of accounts Industry field to be contained within our map.');  
        }
    } 
}