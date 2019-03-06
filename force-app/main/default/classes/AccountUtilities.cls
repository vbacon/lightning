public with sharing class AccountUtilities {

    public static Map<String, Id> accountRecordTypeMap {
        get {
            if (accountRecordTypeMap == null) {
                Map<String, Id> accountRecordTypeMap = new Map<String, Id>();
                List <RecordType> accountRecordTypes = [SELECT Id, DeveloperName FROM RecordType 
                    WHERE sObjectType = 'Account' AND IsActive = true];
                for (RecordType rt : accountRecordTypes) {
                    accountRecordTypeMap.put(rt.DeveloperName, rt.Id);                                                         
                }
                return accountRecordTypeMap;
            } 
            return accountRecordTypeMap;
        }
        private set;
    }

    // Adding test comment
}
