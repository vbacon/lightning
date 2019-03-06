({
    handleErrorEvent : function(component, event, helper) {
        var message = event.getParam('errorMsg');
        var toastEvent = $A.get('e.force:showToast');
        if (toastEvent && message){
            toastEvent.setParams({
                'message': message,
                'type': 'error'
            });
            toastEvent.fire();
        }
        else {
            component.set('v.errorMsg', message);
        }
    },
    
    closeToast : function(component, event, helper) {
        component.set('v.errorMsg', '');
    }
})
