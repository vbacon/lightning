({
    doInit : function(component, event, helper) {
        helper.generateWorldpayOrderId(component, event);
        helper.assignDefaultValuesToDonation(component, event);
    },

    
    reviewDonation : function(component, event, helper) {
        if (helper.validate(component.find('theForm'))) {
            if(!$A.get('$Browser.isPhone'))
                helper.showReviewForm(component, event);
            else
                helper.submit(component, event);
        }
    },

    submit : function(component, event, helper) {
        helper.submit(component, event);
    }, 
    
    handleProductSelectionEvent : function(component, event, helper) {
        helper.handleProductSelectionEvent(component, event);
    },

    termsOfService : function(component, event, helper) {
        var urlEvent = $A.get('e.force:navigateToURL');
        if (urlEvent) {
            urlEvent.setParams({
                'url' : 'https://ww2.kqed.org/about/terms-service/'
            });
            urlEvent.fire();
        }
        else {
            window.location = 'https://ww2.kqed.org/about/terms-service/';
        }
    },

    privacyPolicy : function(component, event, helper) {
        var urlEvent = $A.get('e.force:navigateToURL');
        if (urlEvent) {
            urlEvent.setParams({
                'url' : 'https://ww2.kqed.org/about/privacy-policy/'
            });
            urlEvent.fire();
        }
        else {
            window.location = 'https://ww2.kqed.org/about/privacy-policy/';
        }
    },
    
    contactUs : function(component, event, helper) {
        var urlEvent = $A.get('e.force:navigateToURL');
        if (urlEvent) {
            urlEvent.setParams({
                'url' : 'http://ww2.kqed.org/about/contact/'
            });
            urlEvent.fire();
        }
        else {
            window.location = 'http://ww2.kqed.org/about/contact/';
        }
    }
})