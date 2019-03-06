({
    doInit : function(component, event) {
        var otAmountStr = component.get('v.customOneTimeAskString');
        var monthlyAmountStr = component.get('v.customMonthlyAskString');
        if (otAmountStr) { 
            var otAmountArray = this.safeConvertStringToNumberArray(otAmountStr);
            component.set('v.oneTimeAskStringValues', otAmountArray);
        } 
        if (monthlyAmountStr) {
            var monthlyAmountArray = this.safeConvertStringToNumberArray(monthlyAmountStr);
            component.set('v.monthlyAskStringValues', monthlyAmountArray);
        }
        var defaultAskStringTray = component.find('monthlyAskStringTray') || component.find('oneTimeAskStringTray');
        defaultAskStringTray.setDefaultValue();
    },

    safeConvertStringToNumberArray : function(askString) {
        var convertedArray = askString.split(',').join('').split(';').map(function(value) {
            return parseFloat(value.trim());
        })
        .filter(function(value) {
            return (value);
        });
        var removeDuplicateInArray = convertedArray.filter(function(elem, index, self) {
            return index == self.indexOf(elem);
        });
        return removeDuplicateInArray.slice(0,7);
    },

    amountIsValid : function(amount) {
        var regex = RegExp(/^[0-9]+(\.[0-9]{1,2})?$/);
        var match = regex.test(amount);
        return match;
    },

    validate : function(component, event) {
        var donationAmount = component.get('v.donation').Initial_Payment_Amount__c;
        if (donationAmount && donationAmount > 0) {
            component.set('v.otherAmountInputIsValid', true);
            return true;
        }
        else {
            component.set('v.otherAmountInputIsValid', false);
            return false;
        }
    }
})