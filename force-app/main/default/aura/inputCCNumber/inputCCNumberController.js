({
    evaluateKeyup : function(component, event, helper) {
        helper.evaluateKeyup(component, event);
    },

    evaluatePaste : function(component, event, helper) {
        helper.evaluatePaste(component, event);
    },

    validate : function(component, event, helper) {
        return helper.validate(component, event);
    }
})