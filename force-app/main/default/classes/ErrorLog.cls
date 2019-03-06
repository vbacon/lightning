global class ErrorLog {

    @TestVisible
    private static List<Error_Log__c> errors {
        get {
            if (errors == null) {
                errors = new List<Error_Log__c>();
            }
            return errors;
        }
        private set;
    }
    
    public static void logError(Exception e) {
        logError(e, null, null);
    }

    public static void logError(Exception e, String className) {
        logError(e, className, null);
    }

    public static void logError(Exception e, String className, String customMsg) {
        Error_Log__c newError = new Error_Log__c();
        if (e != null) {
            newError.Line_Number__c = e.getLineNumber();
            newError.Message__c = e.getMessage();
            newError.Stack_Trace_String__c = e.getStackTraceString();
            newError.Type_Name__c = e.getTypeName();
        }
        newError.Class_Name__c = className;
        newError.Custom_Message__c = customMsg;
        errors.add(newError);
    }

    public static void commitErrors() {
        try {
            if (errors.isEmpty()) {
                return;
            }
            
            if (Limits.getDmlRows() < Limits.getLimitDmlRows() &&
                Limits.getDmlStatements() < Limits.getLimitDmlStatements()) {
                    upsert errors;
            }
            else {
                System.debug('Governor limits exhausted before error logs could be inserted');
            }
        }
        catch (DmlException e) {
            // Nothing to do here.
            System.debug('Dml Exception while trying to insert error logs: ' + e.getMessage());
        }
    }
}