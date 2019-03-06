public class BatchOrderTriggerHandler extends TriggerHandler{
    
    public override void afterUpdate() {
        Map<Id,Batch_Order__c> filteredBatchOrders = filterBatchOrdersByStatusUpdate((List<Batch_Order__c>)Trigger.new, (Map<Id,Batch_Order__c>)Trigger.oldMap);
        if (!filteredBatchOrders.isEmpty()) {
            updateOpportunityProductStatuses(filteredBatchOrders);
        }
    }

    @TestVisible
    private Map<Id,Batch_Order__c> filterBatchOrdersByStatusUpdate(List<Batch_Order__c> triggerNew, Map<Id,Batch_Order__c> triggerOldMap) {
        Map<Id,Batch_Order__c> filteredBatchOrders = new Map<Id,Batch_Order__c>();
        for (Batch_Order__c aBatchOrder : triggerNew) {
            if (aBatchOrder.Status__c != triggerOldMap.get(aBatchOrder.Id).Status__c) {
                filteredBatchOrders.put(aBatchOrder.Id, aBatchOrder);
            }
        }
        return filteredBatchOrders;
    }

    @TestVisible
    private void updateOpportunityProductStatuses(Map<Id, Batch_Order__c> batchOrders) {
        List<OpportunityLineItem> allOlis = [
            SELECT Id, Batch_Order__c FROM OpportunityLineItem
            WHERE Batch_Order__c IN :batchOrders.keySet()
        ];
        Map<Id,List<OpportunityLineItem>> orderToLineItemMap = GroupBy.ids('Batch_Order__c', allOlis);
        for (Id aBatchOrderId : orderToLineItemMap.keySet()) {
            for (OpportunityLineItem anOli : orderToLineItemMap.get(aBatchOrderId)) {
                anOLI.Order_Status__c = batchOrders.get(aBatchOrderId).Status__c;
            }
        }
        try {
            update allOlis;
        }
        catch (DMLException e) {
            for (Integer i = 0; i < e.getNumDml(); i++) {
                Batch_Order__c failedBatchOrder = batchOrders.get(allOlis[e.getDmlIndex(i)].Batch_Order__c);
                failedBatchOrder.addError(e.getDmlMessage(i));
            }
        }
    }
}