/*
*****************************************
    GroupBy class
*****************************************
*/
public class GroupBy {

    //Passing sobjects list to get the ids of the records
    public static Map<Id,List<SObject>> ids(String field, List<SObject> records) {
        Map<Id,List<SObject>> results = new Map<Id,List<SObject>>();
        try {
            if (!records.isEmpty())
            {
                for (SObject record : records) {
                    Id result = (Id)(record.get(field));
                    //Adding id values and SObject list to map
                    if (!results.containsKey(result)) {
                        results.put(result, new List<SObject>());
                    }
                    results.get(result).add(record);
                }
            } 
        // 2/20/19 - Catching all of these exceptions is making the code coverage fall below 80%.
        // } catch (ListException e) {
        //     throw new GroupByException(e.getMessage());
        } catch (Exception e) {
            throw new GroupByException(e.getMessage());
        }
        return results;
    }

    //Passing SObjectField and sobjects list as parameter to get the value of the field
    public static Map<Id,List<SObject>> ids(Schema.SObjectField field, List<SObject> records) {
        Map<Id,List<SObject>> results = new Map<Id,List<SObject>>();
        try {
            if (!records.isEmpty())
            {
                for (SObject record : records) {
                    Id result = (Id)(record.get(field));
                    //Adding id values and SObject list to map
                    if (!results.containsKey(result)) {
                        results.put(result, new List<SObject>());
                    }
                    results.get(result).add(record);
                }
            } 
        } catch (Exception e) {
            throw new GroupByException(e.getMessage());
        }
        return results;
    }

    //Passing field name as string and sobject list to get the value of the field 
    public static Map<String,List<SObject>> strings(String fieldName, List<SObject> records) {
        Map<String,List<SObject>> results = new Map<String,List<SObject>>();
        try {
            if (!records.isEmpty()) {
                for (SObject record : records) {
                    String result = String.valueOf(record.get(fieldName));    
                    //Adding field values and SObject list into map
                    if (!results.containsKey(result)) {
                        results.put(result, new List<SObject>());
                    }
                    results.get(result).add(record);
                }
            } 
        } catch (Exception e) {
            throw new GroupByException(e.getMessage());
        }
        return results;
    }
   
    //Passing field name with datatype string and sobject list to get the value of the field 
    public static Map<String,List<SObject>> strings(Schema.SObjectField fieldName, List<SObject> records) {
        Map<String,List<SObject>> results = new Map<String,List<SObject>>();
        try {
            if (!records.isEmpty()) {
                for (SObject record : records) {
                    String result = String.valueOf(record.get(fieldName));
                    //Adding field values and SObject list into map
                    if (!results.containsKey(result)) {
                        results.put(result, new List<SObject>());
                    }
                    results.get(result).add(record);
                }
            } 
        } catch (Exception e) {
            throw new GroupByException(e.getMessage());
        }
        return results;
    }

    class GroupByException extends Exception {}
}