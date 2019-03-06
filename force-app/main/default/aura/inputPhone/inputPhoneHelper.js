({
    evaluateKeyup : function(component, event) {
        let value = event.target.value;
        let pattern = component.get('v.pattern');
        if (value[value.length-1] === '_' || value[value.length-1] !== pattern[value.length-1]) {
            this.transform(component, event);
        }
        component.set('v.value', event.target.value);
    },

    transform : function(component, event) {
        let pattern = component.get('v.pattern');
        let split = pattern.split(/[^_]/)
            .map(function(a){return a.length})
            .filter(function(a){return a !== 0});
        let separators = pattern.split('_')
            .filter(function(a){return a !== ''});
        separators.push('');
        if (pattern[0] === '_') { separators.unshift(''); }
        let chunk = [];
        let value = event.target.value;
        let valueIndex = 0;
        let splitIndex = 0;
        value = value.replace(/[^0-9]/g, '');
        let len = value.length;
        while (valueIndex < len) {
            chunk.push(value.substr(valueIndex, split[splitIndex]));
            valueIndex += split[splitIndex];
            splitIndex++;
        }
        let joinedValue = '';
        if (chunk.length > 0) {
            joinedValue = separators[0] + chunk[0];
        }
        for (let chunkIndex = 1; chunkIndex < chunk.length; chunkIndex++) {
            joinedValue = joinedValue + separators[chunkIndex] + chunk[chunkIndex];
        }
        event.target.value = joinedValue;
    },

    validate : function(component, event) {
        let value = component.get('v.value');
        if (!component.get('v.required')) {
            if (value && value.length < component.get('v.pattern').length) {
                component.set('v.isValid', false);
                return false;
            }
        }
        else {
            if (!value || value.length < component.get('v.pattern').length) {
                component.set('v.isValid', false);
                return false;
            }
        }
        component.set('v.isValid', true);
        return true;
    }
})