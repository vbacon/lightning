public with sharing class QueryUtilities {

    /**
    * @description concatenates all sobject field names given an sobjecttype for use in dynamic soql
    * @param sobjectDescribe a describe object for a given sobject type
    * @return comma separated list of sobject field api names 
    */
    public static String getAllSObjectFields(Schema.DescribeSObjectResult sobjectDescribe) {
        Set<String> fieldNames = sobjectDescribe.fields.getMap().keySet();
        String queryString = String.join(new List<String>(fieldNames), ', ');
        return queryString;
    }

}