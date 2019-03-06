({
    formatAmount : function(component, event, helper) {
        var amount = component.get('v.askStringAmount');
        var isMonthly = component.get('v.donation').Is_Monthly__c === 'true';
        var formatter = new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: (Number.isInteger(amount) ? 0 : 2),
        });
        var formattedAmount = formatter.format(amount);
        if (isMonthly) {
            formattedAmount += ' / month';
        }
        component.set('v.formattedAmount', formattedAmount);
    },
    
    setDonationAmount : function(component, event, helper) {
        var donation =  component.get('v.donation');
        donation.Initial_Payment_Amount__c = component.get('v.askStringAmount');
        component.set('v.donation', donation);
        var selectionEvent = component.getEvent('askStringSelection');
        selectionEvent.fire();
    }
})