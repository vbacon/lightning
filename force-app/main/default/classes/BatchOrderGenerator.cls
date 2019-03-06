global with sharing class BatchOrderGenerator {

    private Map<Id, Id> vendorToProductOrderTemplate = new Map<Id, Id>();
    private Map<Id, String> vendorIdToVendorName = new Map<Id, String>();

    public BatchOrderGenerator(Id passedVendorId, Id passedTemplateId) {
        Account vendorAcct = [
                SELECT Id, Name
                FROM Account
                WHERE Id = :passedVendorId
        ];
        String vendorName = vendorAcct.Name;
        this.vendorToProductOrderTemplate.put(passedVendorId, passedTemplateId);
        this.vendorIdToVendorName.put(passedVendorId, vendorName);
    }

    public BatchOrderGenerator() {
        List<AggregateResult> results = [
            SELECT Product2.Vendor__c Vendor, Product2.Vendor__r.Product_Order_Template__c Template,
                    Product2.Vendor__r.Name VendorName
                FROM OpportunityLineItem
                WHERE Order_Status__c = :OpportunityProductUtilities.NEW_ORDER_STATUS
                    AND Product2.Vendor__c != NULL
                    AND Product2.Vendor__r.Product_Order_Template__c != NULL
                GROUP BY Product2.Vendor__c, Product2.Vendor__r.Product_Order_Template__c, Product2.Vendor__r.Name
        ];
        for (AggregateResult aResult : results) {
            Id vendorId = (Id) aResult.get('Vendor');
            String vendorName = (String) aResult.get('VendorName');
            Id templateId = (Id) aResult.get('Template');
            this.vendorToProductOrderTemplate.put(vendorId, templateId);
            this.vendorIdToVendorName.put(vendorId, vendorName);
        }
    }

    global void generateBatchOrders() {
        if (this.vendorToProductOrderTemplate.keySet().isEmpty()) {
            return;
        }
        Savepoint sp = Database.setSavepoint();
        Map<Id,Id> vendorToBatchOrder;
        try {
            vendorToBatchOrder = getVendorToBatchOrderMap();
        }
        catch (DmlException e) {
            ErrorLog.logError(e, 'BatchOrderGenerator', 'Error inserting new Batch Orders');
            ErrorLog.commitErrors();
            Database.rollback(sp);
            return;
        }

        Map<Id,List<OpportunityLineItem>> olisByVendorId = getNewOlisByVendor();
        List<OpportunityLineItem> olisToUpdate = new List<OpportunityLineItem>();

        for (Id aVendorId : this.vendorToProductOrderTemplate.keySet()) {
            Id thisBatchOrderId = vendorToBatchOrder.get(aVendorId);
            List<OpportunityLineItem> theseOlis = olisByVendorId.get(aVendorId);
            Id thisTemplateId = this.vendorToProductOrderTemplate.get(aVendorId);
            String aVendorName = this.vendorIdToVendorName.get(aVendorId);

            if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
                System.enqueueJob(new BatchOrderCsvWriter(aVendorId, aVendorName, thisTemplateId,
                        theseOlis, thisBatchOrderId));
            }
            else {
                ErrorLog.logError(null, 'BatchOrderGenerator',
                        'Too many vendors to enqueue: ' + this.vendorIdToVendorName.get(aVendorId));
            }
        }
        ErrorLog.commitErrors();
    }

    private Map<Id,Id> getVendorToBatchOrderMap() {
        List<Batch_Order__c> newBatchOrders = new List<Batch_Order__c>();
        for (Id theVendorId : this.vendorToProductOrderTemplate.keyset()) {
            Batch_Order__c aBatchOrder = new Batch_Order__c();
            aBatchOrder.Vendor__c = theVendorId;
            aBatchOrder.Status__c = OpportunityProductUtilities.GENERATED_ORDER_STATUS;
            aBatchOrder.Batch_Order_Name__c = this.vendorIdToVendorName.get(theVendorId) + ' : ' + Date.today().format();
            newBatchOrders.add(aBatchOrder);
        }
        insert newBatchOrders;
        Map<Id,Id> vendorToBatchOrderMap = new Map<Id,Id>();
        for (Batch_Order__c aBatchOrder : newBatchOrders) {
            vendorToBatchOrderMap.put(aBatchOrder.Vendor__c, aBatchOrder.Id);
        }
        return vendorToBatchOrderMap;
    }

    private Map<Id,List<OpportunityLineItem>> getNewOlisByVendor() {
        List<OpportunityLineItem> allOlis = [
            SELECT Id, Order_Status__c, Product2.Vendor__c, Product2.Vendor__r.Product_Order_Template__c
                FROM OpportunityLineItem
                WHERE Order_Status__c = :OpportunityProductUtilities.NEW_ORDER_STATUS
                    AND Product2.Vendor__c IN :this.vendorToProductOrderTemplate.keySet()
                    AND Product2.Vendor__r.Product_Order_Template__c != NULL
        ];
        Map<Id,List<OpportunityLineItem>> olisByVendorId = new Map<Id,List<OpportunityLineItem>>();
        for (OpportunityLineItem anOli : allOlis) {
            if (!olisByVendorId.containsKey(anOli.Product2.Vendor__c)) {
                olisByVendorId.put(anOli.Product2.Vendor__c, new List<OpportunityLineItem>());
            }
            olisByVendorId.get(anOli.Product2.Vendor__c).add(anOli);
        }
        return olisByVendorId;
    }
}
