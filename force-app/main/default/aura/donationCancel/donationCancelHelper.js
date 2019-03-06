({
    doInit : function(component, event) {
        var opportunityId = component.get('v.recordId');
        var action = component.get('c.getDonation');
        action.setParams({'opportunityId' : opportunityId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var opp = response.getReturnValue();
                component.set('v.opp', opp);
                if (!opp.Is_Monthly__c) component.set('v.errMsg', 'Cannot cancel a single-payment donation');
                if (opp.Is_Cancelled__c) component.set('v.errMsg', 'This donation has already been cancelled');
            }
            else {
                var errors = response.getError();
                var message = 'A server error occurred - Please try again later';
                if (errors && errors[0] && errors[0].message) {
                    message = errors[0].message;
                }
                var toastEventFail = $A.get("e.force:showToast");
                toastEventFail.setParams({
                    title: 'Failure!',
                    message: message,
                    type: 'error',
                    mode: 'sticky'
                });
                toastEventFail.fire();
            }
        });
        $A.enqueueAction(action);
    },

    cancel : function(component, event) {
        var opp = component.get('v.opp');
        var action = component.get('c.cancelDonation');
        action.setParams({'opp' : opp});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var refreshAction = $A.get('e.force:refreshView');
                refreshAction.fire();
                var dismissActionPanel = $A.get('e.force:closeQuickAction');
                dismissActionPanel.fire();
            }
            else {
                var errors = response.getError();
                var message = 'A server error occurred - Please try again later';
                if (errors && errors[0] && errors[0].message) {
                    message = errors[0].message;
                }
                var toastEventFail = $A.get("e.force:showToast");
                toastEventFail.setParams({
                    title: 'Failure!',
                    message: message,
                    type: 'error',
                    mode: 'sticky'
                });
                toastEventFail.fire();
            }
        });
        $A.enqueueAction(action);
    }
})
