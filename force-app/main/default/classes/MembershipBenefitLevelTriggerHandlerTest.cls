@IsTest
private class MembershipBenefitLevelTriggerHandlerTest {
    
    static testMethod void testGoodInsert() {
    
        Member_Benefit__c mb1 = new Member_Benefit__c (Name = 'Benefit 1', Description__c = 'Benefit 1');
        Member_Benefit__c mb2 = new Member_Benefit__c (Name = 'Benefit 2', Description__c = 'Benefit 2');
        insert new List<Member_Benefit__c>{mb1, mb2};            
        
        Member_Level__c ml1 = new Member_Level__c (Name = 'Level 1', Member_Level_Value__c = 100);
        Member_Level__c ml2 = new Member_Level__c (Name = 'Level 2', Member_Level_Value__c = 200);
        insert new List<Member_Level__c>{ml1, ml2};            
        
        Member_Benefit_Level__c mbl1 = new Member_Benefit_Level__c(Member_Benefit__c = mb1.Id, Member_Level__c = ml1.Id);
        Member_Benefit_Level__c mbl2 = new Member_Benefit_Level__c(Member_Benefit__c = mb2.Id, Member_Level__c = ml2.Id);
        insert new List<Member_Benefit_Level__c>{mbl1, mbl2};   
        
        Member_Benefit_Level__c newMBL1 = new Member_Benefit_Level__c(Member_Benefit__c = mb1.Id, Member_Level__c = ml2.Id);    
        Member_Benefit_Level__c newMBL2 = new Member_Benefit_Level__c(Member_Benefit__c = mb2.Id, Member_Level__c = ml1.Id);    
        
        Test.startTest();
            Database.SaveResult sr1 = Database.insert(newMBL1, false);
            Database.SaveResult sr2 = Database.insert(newMBL2, false);
        Test.stopTest();

        System.assert(sr1.isSuccess(), 'Insert of first MBL should happen without error.');
        System.assert(sr2.isSuccess(), 'Insert of second MBL should happen without error.');

        List<Member_Benefit_Level__c> testMBLs = new List<Member_Benefit_Level__c>([SELECT Id 
                FROM Member_Benefit_Level__c WHERE Id != null]);
        Integer numOfMBLs = testMBLs.size();

        System.assertEquals(4, numOfMBLs, 'There should be 4 Member Benefit Levels at this point.');
    }

    static testMethod void testBadInsert() {

        Member_Benefit__c mb1 = new Member_Benefit__c (Name = 'Benefit 1', Description__c = 'Benefit 1');
        insert new List<Member_Benefit__c>{mb1};            
        
        Member_Level__c ml1 = new Member_Level__c (Name = 'Level 1', Member_Level_Value__c = 100);
        insert new List<Member_Level__c>{ml1};            
        
        Member_Benefit_Level__c mbl1 = new Member_Benefit_Level__c(Member_Benefit__c = mb1.Id, Member_Level__c = ml1.Id);
        insert new List<Member_Benefit_Level__c>{mbl1};   
        
        Member_Benefit_Level__c newMBL1 = new Member_Benefit_Level__c(Member_Benefit__c = mb1.Id, Member_Level__c = ml1.Id);    
        
        Test.startTest();
            Database.SaveResult sr = Database.insert(newMBL1, false);
        Test.stopTest();

        System.assert(!sr.isSuccess(), 'Insert should NOT happen.');

        List<Member_Benefit_Level__c> testMBLs = new List<Member_Benefit_Level__c>([SELECT Id 
                FROM Member_Benefit_Level__c WHERE Id != null]);
        Integer numOfMBLs = testMBLs.size();

        System.assertEquals(1, numOfMBLs, 'There should be 1 Member Benefit Levels at this point.');

    }

    static testMethod void testGoodUpdate() {
    
        Member_Benefit__c mb1 = new Member_Benefit__c (Name = 'Benefit 1', Description__c = 'Benefit 1');
        Member_Benefit__c mb2 = new Member_Benefit__c (Name = 'Benefit 2', Description__c = 'Benefit 2');
        insert new List<Member_Benefit__c>{mb1, mb2};            
        
        Member_Level__c ml1 = new Member_Level__c (Name = 'Level 1', Member_Level_Value__c = 100);
        Member_Level__c ml2 = new Member_Level__c (Name = 'Level 2', Member_Level_Value__c = 200);
        insert new List<Member_Level__c>{ml1, ml2};            
        
        Member_Benefit_Level__c mbl1 = new Member_Benefit_Level__c(Member_Benefit__c = mb1.Id, Member_Level__c = ml1.Id);
        Member_Benefit_Level__c mbl2 = new Member_Benefit_Level__c(Member_Benefit__c = mb2.Id, Member_Level__c = ml2.Id);
        insert new List<Member_Benefit_Level__c>{mbl1, mbl2};   
        
        mbl1.Member_Benefit__c = mb2.Id;
        mbl2.Member_Benefit__c = mb1.Id;

        Test.startTest();
            Database.SaveResult sr1 = Database.update(mbl1, false);
            Database.SaveResult sr2 = Database.update(mbl2, false);
        Test.stopTest();
        
        System.assert(sr1.isSuccess(), 'First update should happen without error.');
        System.assert(sr2.isSuccess(), 'Second update should happen without error.');

    }

    static testMethod void testBadUpdate() {
    
        Member_Benefit__c mb1 = new Member_Benefit__c (Name = 'Benefit 1', Description__c = 'Benefit 1');
        Member_Benefit__c mb2 = new Member_Benefit__c (Name = 'Benefit 2', Description__c = 'Benefit 2');
        insert new List<Member_Benefit__c>{mb1, mb2};            
        
        Member_Level__c ml1 = new Member_Level__c (Name = 'Level 1', Member_Level_Value__c = 100);
        Member_Level__c ml2 = new Member_Level__c (Name = 'Level 1', Member_Level_Value__c = 200);
        insert new List<Member_Level__c>{ml1, ml2};            
        
        Member_Benefit_Level__c mbl1 = new Member_Benefit_Level__c(Member_Benefit__c = mb1.Id, Member_Level__c = ml1.Id);
        Member_Benefit_Level__c mbl2 = new Member_Benefit_Level__c(Member_Benefit__c = mb2.Id, Member_Level__c = ml2.Id);
        insert new List<Member_Benefit_Level__c>{mbl1, mbl2};   
        
        mbl2.Member_Benefit__c = mb1.Id;
        mbl2.Member_Level__c = ml1.Id;

        Test.startTest();
            Database.SaveResult sr = Database.update(mbl2, false);
        Test.stopTest();
        
        System.assert(!sr.isSuccess(), 'Update should NOT happen without error.');

    }

}

