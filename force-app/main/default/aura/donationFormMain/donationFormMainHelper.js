({
    generateWorldpayOrderId : function(component, event) {
        let orderId = '';
        let possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        for (let i = 0; i < 25; i++) {
            orderId += possible.charAt(Math.floor(Math.random() * possible.length));
        }
        let paymentMethod = component.get('v.thePaymentMethod');
        paymentMethod.worldpayOrderId = orderId;
        component.set('v.thePaymentMethod', paymentMethod);
    },

    assignDefaultValuesToDonation : function(component, event) {
        var theDonation = component.get('v.theDonation');
        theDonation.Device_Type__c = $A.get('$Browser.formFactor');
        var isMonthly = component.get('v.defaultIsMonthly');
        theDonation.Is_Monthly__c = isMonthly;
        component.set('v.theDonation', theDonation);
    },
    
    showConfirmation : function(component, event) {
        let theDonation = component.get('v.theDonation');
        let theContact = component.get('v.theContact');
        $A.createComponent('c:donationFormConfirmation', {
            'theDonation' : theDonation,
            'theContact' : theContact
        }, function(cmp) {
            if (component.isValid()) {
                let theFormCmp = component.find('theForm');
                if (theFormCmp) theFormCmp.set('v.body', cmp);
            }
        });
    },

    showReviewForm : function(component, event) {
        this.clearErrorMessage(component);
        const theDonation = component.get('v.theDonation');
        const theContact = component.get('v.theContact');
        const thePM = component.get('v.thePaymentMethod');
        const theSelectedProduct = component.get('v.selectedProduct');
        const theSelectedProductId = component.get('v.selectedProductId');
        const theShippingAddressModel = component.get('v.shippingAddressModel');

        $A.createComponent("c:donationFormReview", { "theDonation" : theDonation,
                "theContact" : theContact, "thePM" : thePM,
                "theSelectedProduct" : theSelectedProduct,  
                "theSelectedProductId" : theSelectedProductId,  
                "theShippingAddressModel" : theShippingAddressModel},
            function(msgBox) {
            if (component.isValid()) {
                    var targetCmp = component.find('modalPlaceholder');
                    targetCmp.set("v.body", msgBox);
            }
        });
    },

    validate : function(component) {
        if (component.isInstanceOf('c:donationFormSegment')) {
            return component.validate();
        }
        else {
            if (!component || !component.get('v.body')) {
                return true;
            }
            else {
                var children = component.get('v.body');
                var isValid = true;
                for (let i = 0; i < children.length; i++) {
                    isValid = this.validate(children[i]) && isValid;
                }
                return isValid;
            }
        }
    },

    submit : function(component, event) {
        var donData = component.get("v.theDonation");
        var conData = component.get("v.theContact");
        var payData = component.get("v.thePaymentMethod");
        var prodData = component.get("v.selectedProductId");
        var shippingAddressModel = component.get("v.shippingAddressModel");
        var action = component.get("c.submitDonation");
        action.setParams(
            {
                "contactData" : conData,
                "opportunityData" : donData,
                "paymentData" : JSON.stringify(payData),
                "productId" : prodData,
                "shippingAddressData" : JSON.stringify(shippingAddressModel)
            }
        );
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // TO DO - The line below shows the confirmation form any time the submitDonation
                // function is 'successful'.  However, it doesn't account for error situations.
                var returnValue = response.getReturnValue();
                if (returnValue === 'APPROVE') {
                    this.showConfirmation(component, event);
                } else {
                    component.set('v.donateButtonDisabled', false);
                    payData.cardCVV = '';
                    component.set('v.thePaymentMethod', payData);
                    if (returnValue === 'DECLINE') {
                        this.throwErrorMessage(component, 'There was an error processing your credit card.  Please try again.');
                    } else if (returnValue === 'ERROR') {
                        this.throwErrorMessage(component, 'A server error occurred - Please try again later.');
                    }    
                }
            } else if (state === "ERROR") {
                component.set('v.donateButtonDisabled', false);
                payData.cardCVV = '';
                component.set('v.thePaymentMethod', payData);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                        this.throwErrorMessage(component, 'A server error occurred - Please try again later.');
                    }
                } else {
                    console.log("Unknown error");
                    this.throwErrorMessage(component, 'A server error occurred - Please try again later.');
                }
            }
        });
        component.set('v.donateButtonDisabled', true);
        $A.enqueueAction(action);
    },

    clearErrorMessage : function(component) {
        this.throwErrorMessage(component, '');
    },

    throwErrorMessage : function(component, message) {
        var appEvent = $A.get('e.c:donationFormErrorEvent');
        appEvent.setParams({'errorMsg' : message});
        appEvent.fire();
    },

    handleProductSelectionEvent : function(component, event, helper) {
        const productId = event.getParam("productTileSelected");
        component.set('v.selectedProductId', productId);
        const product = event.getParam("productSelected");
        const productSelected = event.getParam("productSelected");
        component.set('v.selectedProduct', productSelected);
    }
})