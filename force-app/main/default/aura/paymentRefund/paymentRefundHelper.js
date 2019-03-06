({
    doInit: function(component, event) {
        
        const originalPaymentID = component.get("v.recordId");
        var action = component.get("c.checkPaymentChildRecord");
        action.setParams({'originalPaymentId' : originalPaymentID});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.hasChildPaymentRec",response.getReturnValue());
            } else if (state === "ERROR"){
                var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            var toastEventFail = $A.get("e.force:showToast");
                            toastEventFail.setParams({
                                title: 'Failure!',
                                message: errors[0].message,
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
    },

    refund: function(component, event) {
        var paymentID = component.get("v.recordId");
        var action = component.get("c.refundDonation");
        action.setParams({"originalPaymentID" : paymentID});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                $A.get("e.force:closeQuickAction").fire();
                var toastEventSuccess = $A.get("e.force:showToast");
                toastEventSuccess.setParams({
                    message: 'The payment has been refunded successfully',
                    type: 'success',
                    mode: 'sticky'
                });
                toastEventSuccess.fire();
                var paymentRefundNavEvt = $A.get("e.force:navigateToSObject");
                paymentRefundNavEvt.setParams({
                    "recordId": response.getReturnValue().Id,
                    "slideDevName": "related"
                });
                paymentRefundNavEvt.fire();
            } else if (state === "ERROR"){
                var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            $A.get("e.force:closeQuickAction").fire();
                            var toastEventFail = $A.get("e.force:showToast");
                            toastEventFail.setParams({
                                title: 'Failure!',
                                message: 'Refund is not successful. ' + errors[0].message +'. Please contact mercury team.',
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