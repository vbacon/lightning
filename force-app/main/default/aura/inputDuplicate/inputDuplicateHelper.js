({
    validate : function(component, event) {
        if (component.find('theInput').getElement().value === component.get('v.originalInput') || component.get('v.isPristine')) {
            component.set('v.isValid', true);
            return true;
        }
        else {
            component.set('v.isValid', false);
            return false;
        }
    },

    dirtyInput : function(component, event) {
        if (component.get('v.isPristine')) { component.set('v.isPristine', false); }
    }
})