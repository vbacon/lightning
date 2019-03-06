trigger Payment on Payment__c (after update) {
    new PaymentTriggerHandler().run();
}