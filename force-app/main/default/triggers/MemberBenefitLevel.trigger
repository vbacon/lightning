trigger MemberBenefitLevel on Member_Benefit_Level__c (before insert, before update) {
    new MemberBenefitLevelTriggerHandler().run();
}