@IsTest
public class QueryUtilitiesTest {

    static testMethod void testGetAllSObjectFields() {
        Schema.DescribeSObjectResult accountDescribe = Schema.SObjectType.Account;
        Map<String,Schema.SObjectField> dfrs = accountDescribe.fields.getMap();
        Test.startTest();
            String fieldString = QueryUtilities.getAllSObjectFields(accountDescribe);
        Test.stopTest();
        for (String aFieldName : dfrs.keySet()) {
            System.assert(fieldString.contains(aFieldName), 'Expect the field string to contain every field name on this sobject');
        }
    }

}