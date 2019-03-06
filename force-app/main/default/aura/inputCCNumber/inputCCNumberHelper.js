({
    evaluateKeyup : function(component, event) {
        if (event.keyCode !== 32) {
            this.transform(component, event, event.target.value);
        }
        component.set('v.value', event.target.value.replace(/\s/g, ''));
    },
    
    evaluatePaste : function(component, event) {
        var cd = event.clipboardData;
        var pastedValue = cd.getData('Text');
        this.transform(component, event, pastedValue);
        component.set('v.value', event.target.value.replace(/\s/g, ''));
    },

    transform : function(component, event, value) {
        value = value.replace(/[^0-9]/g, '');
        let split;
        if (value.startsWith('34') || value.startsWith('37')) {
            split = [4,6,5];
            event.target.setAttribute('maxlength', '17');
        }
        else {
            split = [4,4,4,4];
            event.target.setAttribute('maxlength', '19');
        }
        let chunk = [];
        let i = 0;
        let j = 0;
        let len = value.length;
        while (i < len) {
            chunk.push(value.substr(i, split[j]));
            i += split[j];
            j++;
        }
        event.target.value = chunk.join(' ');
    },

    validate : function(component, event) {
        let value = component.get('v.value');
        let maxLength = 16;
        component.set('v.cardType', '');
        if (!value) {
            component.set('v.errorMsg', 'Complete this field');
            component.set('v.isValid', false);
            return false;
        }
        else {
            let firstTwoDigits = parseInt(value.substr(0,2));
            component.set('v.errorMsg', '');
            if (firstTwoDigits === 34 || firstTwoDigits === 37) {
                maxLength = 15;
                component.set('v.cardType', 'American Express');
            }
            else if (Math.floor(firstTwoDigits / 10) === 4) {
                component.set('v.cardType', 'Visa');
            }
            else if (firstTwoDigits >= 51 && firstTwoDigits <= 55) {
                component.set('v.cardType', 'Mastercard');
            }
            else if (firstTwoDigits === 60 || firstTwoDigits === 62 || firstTwoDigits === 64 || firstTwoDigits === 65) {
                component.set('v.cardType', 'Discover');
            }
            else {
                component.set('v.errorMsg', 'Card type not recognized');
                component.set('v.isValid', false);
                return false;
            }
        }
        if (value.length < maxLength) {
            component.set('v.cardType', '');
            component.set('v.errorMsg', 'Card number is incomplete');
            component.set('v.isValid', false);
            return false;
        }
        component.set('v.isValid', true);
        return true;
    }
})