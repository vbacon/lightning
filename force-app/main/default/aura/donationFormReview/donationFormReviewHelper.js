({

    createCardNumberString : function(component, event) {
        var cardString = '************';
        var fullCCNum = component.get("v.thePM.cardNumber");
        var lengthCCNum = fullCCNum.length;
        cardString += fullCCNum.substring(lengthCCNum - 4, lengthCCNum);
        var selectedProduct = component.get("v.selectedProductId");
        component.set('v.cardNumberString', cardString);   

    },

    checkIfProductIsSelected : function(component, event) {
        var boolean = true;
        var selectedProductId = component.get("v.theSelectedProductId");
        if (selectedProductId === null) {
            boolean = false;
        }    
        component.set('v.isProductSelected', boolean);
    },

    destroyComponent : function(component, event) {
        component.destroy();
    },

    processDonation : function(component, event) {
        var theEvent = component.getEvent("donationFormCheckoutEvent");
        theEvent.fire();
    },


})
