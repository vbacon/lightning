public with sharing class BatchOrderCsvWriter implements Queueable {

    // NOTE: This code requires the manual synchronization of three items:
    //      - The code in the execute method below.
    //      - The picklist items in the field Product_Order_Template__c.Field_Name__c.
    //      - The items in the custom metadata object Product Template Name Map.
    // Additions to the picklist field must be accommodated in the other two locations to work properly.

    Id vendorId;
    String vendorName;
    Id productOrderTemplateId;
    List<OpportunityLineItem> olis;
    Id batchOrderId;

    public BatchOrderCsvWriter(Id vendorId, String vendorName, Id productOrderTemplateId, List<OpportunityLineItem> olis, Id batchOrderId) {
        this.vendorId = vendorId;
        this.vendorName = vendorName;
        this.productOrderTemplateId = productOrderTemplateId;
        this.batchOrderId = batchOrderId;
        this.olis = olis;
    }

    private List<OpportunityLineItem> requeryOlis(List<OpportunityLineItem> olis, List<Product_Template_Field__c> queryFields, Map<String,String> labelToApiName) {
        if (queryFields.size() < 1) {
            return null;
        }

        Set<String> queryFieldNames = new Set<String>{'Id'};
        for (Integer i = 0; i < queryFields.size(); i++) {
            if (labelToApiName.get(queryFields[i].Field_Name__c) != null) {
                queryFieldNames.add(labelToApiName.get(queryFields[i].Field_Name__c));
            }
        }

        // Begin constructing the query
        String query = 'SELECT ';
        query += String.join(new List<String>(queryFieldNames), ', ');
        query += ' FROM OpportunityLineItem ';
        query += ' WHERE Id IN :oliIds';

        Set<Id> oliIds = Pluck.ids(olis);
        return Database.query(query);
    }

    public void execute(QueueableContext qc) {
        String csvString = buildCsvString();
        if (String.isBlank(csvString)) {
            return;
        }
        Date thisDate = Date.today();
        String dateString = thisDate.month() + '_' + thisDate.day() + '_' + thisDate.year();
        String sanitizedVendorName = this.vendorName.replace(' ', '');  // Don't want spaces in the file name
        String contentName = sanitizedVendorName + '_' + dateString;

        // Create the ContentVersion which automatically creates and links to a ContentDocument
        ContentVersion cv = new ContentVersion(
            VersionData = Blob.valueOf(csvString),
            Title = contentName,
            PathOnClient = contentName + '.csv'
        );
        Savepoint sp = Database.setSavepoint();
        try {
            insert cv;
        }
        catch (DMLException e) {
            ErrorLog.logError(e, 'BatchOrderCsvWriter', 'Error inserting content version');
            ErrorLog.commitErrors();
            return;
        }
        ContentVersion requeriedCv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = requeriedCv.ContentDocumentId,
            LinkedEntityId = batchOrderId,
            ShareType = 'V'
        );
        try {
            insert cdl;
        }
        catch (DMLException e) {
            Database.rollback(sp);
            ErrorLog.logError(e, 'BatchOrderCsvWriter', 'Error inserting content document link');
            ErrorLog.commitErrors();
        }
        for (OpportunityLineItem anOli : olis) {
            anOli.Batch_Order__c = batchOrderId;
            anOli.Order_Status__c = OpportunityProductUtilities.GENERATED_ORDER_STATUS;
        }
        try {
            update olis;
        }
        catch (DMLException e) {
            Database.rollback(sp);
            ErrorLog.logError(e, 'BatchOrderCsvWriter', 'Error updating opportunity products');
            ErrorLog.commitErrors();
        }
    }

    private String buildCsvString() {
        List<Product_Template_Field__c> fieldsInTemplate = new List<Product_Template_Field__c>([
            SELECT Field_Name__c, Field_Order__c
                FROM Product_Template_Field__c
                WHERE Product_Order_Template__c	= :this.productOrderTemplateId
                ORDER BY Field_Order__c
        ]);
        if (fieldsInTemplate.isEmpty()) {
            return null;
        }

        // Creating two static maps from custom metadata object Product Template Name Map
        // First maps field labels to API name.  Second maps field labels to Data Type.
        Map<String, String> labelToApiName = new Map<String, String>();
        Map<String, String> labelToDataType = new Map<String, String>();

        Product_Template_Name_Map__mdt[] PTN_Mappings = [
            SELECT Field_Label__c, Field_API_Name__c, Data_Type__c
            FROM Product_Template_Name_Map__mdt
        ];
        for (Product_Template_Name_Map__mdt PTN : PTN_Mappings) {
            labelToApiName.put(PTN.Field_Label__c, PTN.Field_API_Name__c);
            labelToDataType.put(PTN.Field_Label__c, PTN.Data_Type__c);
        }

        List<OpportunityLineItem> requeriedOlis = requeryOlis(this.olis, fieldsInTemplate, labelToApiName);

        String fullCSVString = '';
        fullCsvString += generateHeaderRow(fieldsInTemplate);

        if (!requeriedOlis.isEmpty()) {
            fullCSVString += generateBodyRows(requeriedOlis, fieldsInTemplate, labelToApiName, labelToDataType);
        }
        return fullCSVString;
    }

    @TestVisible
    private String generateHeaderRow(List<Product_Template_Field__c> queryFields) {
        String headerLine = '';
        if (queryFields.size() > 0) {
            for (Integer i = 0; i < (queryFields.size() - 1); i++) {
                headerLine += queryFields[i].Field_Name__c + ', ';
            }
            headerLine += queryFields[queryFields.size() - 1].Field_Name__c + '\n';
        }

        return headerLine;
    }

    @TestVisible
    private String generateBodyRows(List<OpportunityLineItem> olis,
            List<Product_Template_Field__c> queryFields, Map<String, String> labelToApiName,
            Map<String, String> labelToDataType) {

        String vendorCSVString = '';

        for (OpportunityLineItem anOLI : olis) {  // for every OLI retrieved by the query

            String csvLine = '';
            for (Product_Template_Field__c aPTF : queryFields) {  // for every field selected
                // The 'get' function can only be used on OLI items.  The others must be hard-coded.
                String aString;
                String fieldApiName = labelToApiName.get(aPTF.Field_Name__c);
                // Need to treat Date fields, Decimal fields, and others separately to convert to a string.
                if (labelToDataType.get(aPTF.Field_Name__c) == 'Date') {
                    Date aDate;
                    DateTime aDateTime;
                    if (fieldApiName == 'ServiceDate') {
                        aDate = (Date) anOLI.ServiceDate;
                    } else if (fieldApiName == 'LastModifiedDate') {
                        aDateTime = (DateTime) anOLI.LastModifiedDate;
                        aDate = aDateTime.date();
                    } else if (fieldApiName == 'CreatedDate') {
                        aDateTime = (DateTime) anOLI.CreatedDate;
                        aDate = aDateTime.date();
                    } else if (fieldApiName == 'Opportunity.CloseDate') {
                        aDate = (Date) anOLI.Opportunity.CloseDate;
                    } else if (fieldApiName == 'Product2.Available_to_Ship_Date__c') {
                        aDate = (Date) anOLI.Product2.Available_to_Ship_Date__c;
                    }

                    if (aDate != null) {
                        aString = aDate.format();
                    }

                } else if (labelToDataType.get(aPTF.Field_Name__c) == 'Decimal') {
                    Decimal aDecimal;
                    if (fieldApiName == 'Quantity') {
                        aDecimal = (Decimal) anOLI.Quantity;
                    } else if (fieldApiName == 'Product2.Cost__c') {
                        aDecimal = (Decimal) anOLI.Product2.Cost__c;
                    }

                    if (aDecimal != null) {
                        aString = aDecimal.format();
                    }

                } else {
                    if (fieldApiName == 'Id' || fieldApiName == 'Name' ||
                            fieldApiName == 'ProductCode') {
                        // The 'get' function here can only be used on OLI fields, not parents.
                        aString = String.valueOf(anOLI.get(fieldApiName));
                    } else if (fieldApiName == 'Opportunity.Shipping_Street__c') {
                        aString = String.valueOf(anOLI.Opportunity.Shipping_Street__c);
                    } else if (fieldApiName == 'Opportunity.Shipping_City__c') {
                        aString = String.valueOf(anOLI.Opportunity.Shipping_City__c);
                    } else if (fieldApiName == 'Opportunity.Shipping_State__c') {
                        aString = String.valueOf(anOLI.Opportunity.Shipping_State__c);
                    } else if (fieldApiName == 'Opportunity.Shipping_Postal_Code__c') {
                        aString = String.valueOf(anOLI.Opportunity.Shipping_Postal_Code__c);
                    } else if (fieldApiName == 'Opportunity.Contact__r.FirstName') {
                        aString = String.valueOf(anOLI.Opportunity.Contact__r.FirstName);
                    } else if (fieldApiName == 'Opportunity.Contact__r.LastName') {
                        aString = String.valueOf(anOLI.Opportunity.Contact__r.LastName);
                    } else if (fieldApiName == 'Opportunity.Contact__r.Email') {
                        aString = String.valueOf(anOLI.Opportunity.Contact__r.Email);
                    } else if (fieldApiName == 'Product2.Id') {
                        aString = String.valueOf(anOLI.Product2.Id);
                    } else if (fieldApiName == 'Product2.Distributor__c') {
                        aString = String.valueOf(anOLI.Product2.Distributor__c);
                    } else if (fieldApiName == 'Product2.Estimated_Shipping_Time__c') {
                        aString = String.valueOf(anOLI.Product2.Estimated_Shipping_Time__c);
                    } else if (fieldApiName == 'Product2.Shipping_Method__c') {
                        aString = String.valueOf(anOLI.Product2.Shipping_Method__c);
                    } else if (fieldApiName == 'Product2.StockKeepingUnit') {
                        aString = String.valueOf(anOLI.Product2.StockKeepingUnit);
                    } else if (fieldApiName == 'Product2.ProductCode') {
                        aString = String.valueOf(anOLI.Product2.ProductCode);
                    } else if (fieldApiName == 'Product2.Type__c') {
                        aString = String.valueOf(anOLI.Product2.Type__c);
                    } else if (fieldApiName == 'Opportunity.Id') {
                        aString = String.valueOf(anOLI.Opportunity.Id);
                    } else if (fieldApiName == 'Opportunity.Account.AccountNumber') {
                        aString = String.valueOf(anOLI.Opportunity.Account.AccountNumber);
                    }

                }

                if (aString != null) {
                    aString = aString.replace(',', ':'); // Must not have commas going into a CSV file.
                } else {
                    aString = '';  // Otherwise 'null' shows up in the output.
                }
                csvLine += aString + ', ';
            }   // for (Product_Template_Field__c aPTF : queryFields)

            if (csvLine.length() > 2) {
                csvLine = csvLine.substring(0, (csvLine.length() - 2));  // Get rid of last comma
            }

            csvLine += '\n';

            vendorCSVString += csvLine;
        } // for (OpportunityLineItem anOLI : queryResultSet)

        return vendorCSVString;

    }
}
