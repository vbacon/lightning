({
    doInit : function(component, event, helper) {
        helper.createCardNumberString(component, event);
        helper.checkIfProductIsSelected(component, event);
    },

    cancelButton : function(component, event, helper) {
        helper.destroyComponent(component, event);
    }, 

    saveButton : function(component, event, helper) {
        helper.processDonation(component, event);       
        helper.destroyComponent(component, event); // Move to end of ProcessDonation??
    },

})
