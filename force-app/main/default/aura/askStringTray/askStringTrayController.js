({
    setDefaultValue : function(component, event, helper) {
        var defaultIndex = component.get('v.defaultIndex')-1;
        var valueOptions = component.get('v.valueOptions');
        if ((defaultIndex >= valueOptions.length) || (defaultIndex <= 0)) {
            defaultIndex = 0;
        }
        var defaultValue = valueOptions[defaultIndex];
        component.set('v.donation.Initial_Payment_Amount__c', defaultValue);
    }
})
