trigger Opportunity on Opportunity (before insert, before update, after insert, after update, after delete) {
    new OpportunityTriggerHandler().run();
}