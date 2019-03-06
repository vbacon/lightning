({
    validateInput : function(component, event, helper) {
        return helper.validate(component, event);
    },

    validateFinal : function(component, event, helper) {
        helper.dirtyInput(component, event);
        return helper.validate(component, event);
    },

    dirtyInput : function(component, event, helper) {
        helper.dirtyInput(component, event);
    }
})