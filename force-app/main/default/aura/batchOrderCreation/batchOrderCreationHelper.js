({
    doInit: function(component, event) {
        
        component.set('v.vendorId', component.get("v.recordId"));
        this.getProductTemplate(component);
        this.checkForNewOppProducts(component);
    },

    getProductTemplate : function(component) {
    
        const ID = component.get("v.recordId");

        var action = component.get("c.getProductTemplateId");
        action.setParams({'vendorId' : ID});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                if (response.getReturnValue() === null) {
                    component.set('v.hasProductOrderTemplate', false);
                } else {
                    component.set('v.hasProductOrderTemplate', true);
                    component.set('v.templateId', response.getReturnValue());
                }
            } else if (state === "ERROR"){
                var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            component.set('v.errorMsg', errors[0].message);
                        }
                    } else {
                        component.set('v.errorMsg', 'A server error occurred - Please try again later');
                    }
                }
        });
        $A.enqueueAction(action);

    },
    
    checkForNewOppProducts : function(component) {
    
        const ID = component.get("v.recordId");

        var action = component.get("c.checkForNewOpportunityProducts");
        action.setParams({'vendorId' : ID});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                if (response.getReturnValue() === true) {
                    component.set('v.hasNewOpportunityProducts',true);
                }
            } else if (state === "ERROR"){
                var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            component.set('v.errorMsg', errors[0].message);
                        }
                    } else {
                        component.set('v.errorMsg', 'A server error occurred - Please try again later');
                    }
                }
        });
        $A.enqueueAction(action);        

    },

    createOrder: function(component, event) {
        
        const vendorId = component.get("v.recordId");
        const templateId = component.get("v.templateId");

        var action = component.get("c.createBatchOrder");
        action.setParams({"templateId" : templateId, "vendorId" : vendorId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                $A.get("e.force:closeQuickAction").fire();
                var toastEventSuccess = $A.get("e.force:showToast");
                toastEventSuccess.setParams({
                    title: 'Success!',
                    message: 'The batch order has been successfully',
                    type: 'success',
                    mode: 'sticky'
                });
                toastEventSuccess.fire();
            } else if (state === "ERROR"){
                var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            $A.get("e.force:closeQuickAction").fire();
                            var toastEventFail = $A.get("e.force:showToast");
                            toastEventFail.setParams({
                                title: 'Failure!',
                                message: 'Batch order not created. ' + errors[0].message +'. Please contact mercury team.',
                                type: 'error',
                                mode: 'sticky'
                            });
                            toastEventFail.fire();
                        }
                    } else {
                        component.set('v.errorMsg', 'A server error occurred - Please try again later');
                    }
            }
        });
        $A.enqueueAction(action);
    }
    
})
