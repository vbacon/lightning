({
    doInit : function(component, event, helper) {
        helper.doInit(component, event);
        component.set('v.donationOldValue', JSON.parse(JSON.stringify(component.get('v.donation')))); // parse->stringify = clone
    },

    handleAmountChange : function(component, event, helper) {
        var donation = component.get('v.donation');
        var oldValue = component.get('v.donationOldValue');
        var appEvent = $A.get('e.c:donationAmountChangeEvent');
        appEvent.setParam('amount', donation.Initial_Payment_Amount__c);
        appEvent.setParam('isMonthly', donation.Is_Monthly__c);
        if (donation.Is_Monthly__c !== oldValue.Is_Monthly__c) {
            component.set('v.otherAmountInputIsValid', true);
            component.find('otherAmountInput').getElement().value = '';
        }
        component.set('v.donationOldValue', JSON.parse(JSON.stringify(donation)));
        appEvent.fire();
    },

    setOtherAmount : function(component, event, helper) {
        var otherAmount = event.target.value;
        var match = helper.amountIsValid(otherAmount);
        var donation = component.get('v.donation');
        if (!match) {
            donation.Initial_Payment_Amount__c = 0;
            component.set('v.donation', donation);
        }
        else {
            donation.Initial_Payment_Amount__c = parseFloat(otherAmount);
            component.set('v.donation', donation);
        }
    },

    clearOtherAmount : function(component, event, helper) {
        component.find('otherAmountInput').getElement().value = '';
        component.set('v.otherAmountInputIsValid', true);
    },

    validateOtherAmountInput : function(component, event, helper) {
        var otherAmount = component.find('otherAmountInput').getElement().value;
        if (otherAmount === '') {
            component.set('v.otherAmountInputIsValid', true);
        }
        else {
            var match = helper.amountIsValid(otherAmount);
            component.set('v.otherAmountInputIsValid', match);
        }
    }
})