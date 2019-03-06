({
    doInit: function(component, event) {
        const productId = component.get("v.recordId");
        var action = component.get("c.getProduct");
        action.setParams({'productId' : productId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.aProduct",response.getReturnValue());
            } else if (state === "ERROR"){
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        var toastEventFail = $A.get("e.force:showToast");
                        toastEventFail.setParams({
                            title: 'Failure!',
                            message: 'A server error occurred - Please try again later.',
                            type: 'error',
                            mode: 'sticky'
                        });
                        toastEventFail.fire();
                    }
                } else {
                    var toastEventFail = $A.get("e.force:showToast");
                    toastEventFail.setParams({
                        title: 'Failure!',
                        message: 'A server error occurred - Please try again later.',
                        type: 'error',
                        mode: 'sticky'
                    });
                    toastEventFail.fire();
                }    
            }
        });
        $A.enqueueAction(action);
    }
})
