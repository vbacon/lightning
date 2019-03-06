/*
*****************************************
    Pluck class
*****************************************
*/
public class Pluck {

    //Passing sobject list to get the ids of the records 
    public static Set<Id> ids(List<SObject> records) {
        Set<Id> results = new Set<Id>();
        try{
             if (!records.isEmpty()) {
                for (SObject record : records) {
                    Id result = (Id)(record.get('Id'));
                    if (result != null) 
                        //Adding id values from list to set 
                        results.add(result);
                }
            }
        // 2/20/19 - Catching all of these exceptions is making the code coverage fall below 80%.
        //} catch (ListException e) {
		// throw new PluckException(e.getMessage());
        }
        catch (Exception e) {
            throw new PluckException(e.getMessage());
        }
        return results;
    }

    //Passing field name as string and sobject list as parameter to get the value of the field 
    public static Set<Id> ids(String fieldName, List<SObject> records) {
        Set<Id> results = new Set<Id>();
        try {
            if (!records.isEmpty()) {
                for (SObject record : records) {
                    Id result = (Id)(record.get(fieldName));
                    if (result != null)
                        //Adding SObjectField values into set 
                        results.add(result);
                }
            } 
        } catch (Exception e) {
          throw new PluckException(e.getMessage());
        }
        return results;
    }

    //Passing field name with datatype id and sobject list as parameter to get the value of the field 
    public static Set<Id> ids(Schema.SObjectField fieldName, List<SObject> records) {
        Set<Id> results = new Set<Id>();
        try {
            if (!records.isEmpty()) {
                for (SObject record : records) {
                    Id result = (Id)(record.get(fieldName));
                    if (result != null)
                        //Adding SObjectField values into set 
                        results.add(result);
                }
            } 
        } catch (Exception e) {
          throw new PluckException(e.getMessage());
        }
        return results;
    }

    //Passing field name as string and sobject list to get the value of the field 
    public static Set<String> strings(String fieldName, List<SObject> records) {
        Set<String> results = new Set<String>();
        try {
            if (!records.isEmpty()) {
                for (SObject record : records) {
                    String result = String.valueOf(record.get(fieldName));    
                    if (result != null) 
                        //Adding field values into set
                        results.add(result);
                }
            } 
        } catch (Exception e) {
            throw new PluckException(e.getMessage());
        }
        return results;
    }
   
    //Passing field name with datatype string and sobject list to get the value of the field 
    public static Set<String> strings(Schema.SObjectField fieldName, List<SObject> records) {
        Set<String> results = new Set<String>();
        try {
            if (!records.isEmpty()) {
                for (SObject record : records) {
                    String result = String.valueOf(record.get(fieldName));
                    if (result != null)
                        //Adding SObjectField values into set 
                        results.add(result);
                }
            } 
        } catch (Exception e) {
            throw new PluckException(e.getMessage());
        }
        return results;
    }
    
    //Passing field name as string and sobject list to get the value of the field 
    public static Set<Integer> integers(String fieldName, List<SObject> records) {
        Set<Integer> results = new Set<Integer>();
        try {
            if (!records.isEmpty()) {
                for (SObject record : records) {
                    Integer result = Integer.valueOf(record.get(fieldName));
                    if (result != null)
                        //Adding SObjectField values into set 
                        results.add(result);
                }
            } 
        } catch (Exception e) {
            throw new PluckException(e.getMessage());
        }
        return results;
    }

    //Passing field name with datatype integer and sobject list to get the value of the field 
    public static Set<Integer> integers(Schema.SObjectField fieldName, List<SObject> records) {
        Set<Integer> results = new Set<Integer>();
        try {
            if (!records.isEmpty()) {
                for (SObject record : records) {
                    Integer result = Integer.valueOf(record.get(fieldName));
                    if (result != null)
                        //Adding SObjectField values into set 
                        results.add(result);
                }
            } 
        } catch (Exception e) {
            throw new PluckException(e.getMessage());
        }
        return results;
    }

    //Passing field name as string and sobject list to get the values of the field 
    public static Set<Decimal> decimals(String fieldName, List<SObject> records) {
        Set<Decimal> results = new Set<Decimal>();
        try {
            if (!records.isEmpty()) {
                for (SObject record : records) {
                    Decimal result = (Decimal)(record.get(fieldName));
                    if (result != null) 
                        //Adding SObjectField values into set
                        results.add(result);
                }
            }
        } catch (Exception e) {
            throw new PluckException(e.getMessage());
        }
        return results;
    }

    //Passing field name with datatype decimal and sobject list to get the values of the field 
    public static Set<Decimal> decimals(Schema.SObjectField fieldName, List<SObject> records) {
        Set<Decimal> results = new Set<Decimal>();
        try {
            if (!records.isEmpty()) {
                for (SObject record : records) {
                    Decimal result = (Decimal)(record.get(fieldName));
                    if (result != null) 
                        //Adding SObjectField values into set
                        results.add(result);
                }
            }
        } catch (Exception e) {
            throw new PluckException(e.getMessage());
        }
        return results;
    }

    //Passing field name as string and sobject list to get the values of the field 
    public static Set<Double> doubles(String fieldName, List<SObject> records) {
        Set<Double> results = new Set<Double>();
        try{
            if (!records.isEmpty()) {
                for (SObject record : records) {
                    Double result = Double.valueOf(record.get(fieldName));
                    if (result != null) 
                        //Adding SObjectField value into set
                        results.add(result);
                }
            } 
        } catch (Exception e) {
            throw new PluckException(e.getMessage());
        }
        return results;
    }

    //Passing field name with datatype double and sobject list to get the values of the field 
    public static Set<Double> doubles(Schema.SObjectField fieldName, List<SObject> records) {
        Set<Double> results = new Set<Double>();
        try{
            if (!records.isEmpty()) {
                for (SObject record : records) {
                    Double result = Double.valueOf(record.get(fieldName));
                    if (result != null) 
                        //Adding SObjectField value into set
                        results.add(result);
                }
            } 
        } catch (Exception e) {
            throw new PluckException(e.getMessage());
        }
        return results;
    }

    //Passing field name as string and sobject list to get the values of the field 
    public static Set<Boolean> booleans(String fieldName, List<SObject> records) {
        Set<Boolean> results = new Set<Boolean>();
        try{
            if (!records.isEmpty()) {
                for (SObject record : records) {
                    Boolean result = Boolean.valueOf(record.get(fieldName));
                    if (result != null) 
                        //Adding SObjectField value into set
                        results.add(result);
                }
            }
        } catch (Exception e) {
            throw new PluckException(e.getMessage());
        }
        return results;
    }
    
    //Passing field name with datatype Boolean and sobject list to get the values of the field 
    public static Set<Boolean> booleans(Schema.SObjectField fieldName, List<SObject> records) {
        Set<Boolean> results = new Set<Boolean>();
        try{
            if (!records.isEmpty()) {
                for (SObject record : records) {
                    Boolean result = Boolean.valueOf(record.get(fieldName));
                    if (result != null) 
                        //Adding SObjectField value into set
                        results.add(result);
                }
            }
        } catch (Exception e) {
            throw new PluckException(e.getMessage());
        }
        return results;
    }
    class PluckException extends Exception {}
}