trigger ProductTemplateField on Product_Template_Field__c (before insert, before update) {
    new ProductTemplateFieldTriggerHandler().run();
}