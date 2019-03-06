({
    getAllProducts : function(component, event, helper) {
        helper.getAllProducts(component, event);
    },

    fetchProducts : function(component, event, helper) {
        helper.fetchProducts(component, event);
    },

    closeGiftToggle : function(component, event, helper) {
        helper.closeGiftToggle(component, event);
    },
    
    handleDonationAmountChangeEvent : function(component, event, helper) {
        component.set('v.selectedProductId', null);
        var amount = event.getParam('amount');
        var isMonthly = event.getParam('isMonthly');
        component.set('v.amount', amount);
        component.set('v.isMonthly', isMonthly);
        helper.fetchProducts(component, event);
    },

    evaluateToggleIsValid : function(component, event, helper) {
        helper.evaluateToggleIsValid(component, event);
    }
   
})