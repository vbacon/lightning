trigger Product on Product2 (after insert, after update, before delete, before update) {
    new ProductTriggerHandler().run();
}