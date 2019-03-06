({
    
    returnToMain : function(component, event, helper) {
        var urlEvent = $A.get('e.force:navigateToURL');
        if (urlEvent) {
            urlEvent.setParams({
                'url' : 'http://www.kqed.org'
            });
            urlEvent.fire();
        }
        else {
            window.location = 'http://www.kqed.org';
        }
    }
})
