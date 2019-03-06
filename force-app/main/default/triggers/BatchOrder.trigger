trigger BatchOrder on Batch_Order__c (after update) {
    new BatchOrderTriggerHandler().run();
}