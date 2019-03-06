({
    getAllProducts : function(component, event) {
        component.set('v.amount', component.get('v.defaultAmount'));
        component.set('v.isMonthly', component.get('v.defaultIsMonthly'));
        const action = component.get('c.getQualifyingProducts');
        action.setCallback(this, function(response) {
            if (component.isValid() && response.getState() === 'SUCCESS') {
                component.set('v.allProducts', response.getReturnValue());
            }
            this.fetchProducts(component, event);
        });
        $A.enqueueAction(action);
    },

    fetchProducts : function(component, event) {
        let amount = parseFloat(component.get('v.amount')) || 0;
        let isMonthly = component.get('v.isMonthly') || false;
        let amountField = (isMonthly === 'true') ? 'Sustainer_Price__c' : 'One_Time_Price__c';
        var allProducts = component.get('v.allProducts')[isMonthly] || [];
        var products = [];
        for (let i = 0; i < allProducts.length && products.length < 4; i++) {
            if (allProducts[i][amountField] <= amount) {
                products.push(allProducts[i]);
            }
        }
        component.set('v.products', products);
        this.resetShowGifts(component, event);
    },

    resetShowGifts : function(component, event) {
        let amount = parseFloat(component.get('v.amount')) || 0;
        let productsExist = component.get('v.products').length;
        let isDisabled = !(amount && amount > 0 && productsExist);
        component.set('v.isDisabled', isDisabled);
        if (isDisabled) {
            component.set('v.showGifts', false);
        }
    },

    closeGiftToggle : function(component,event) {
        const giftsAreShown = event.getParam('value');
        if (!giftsAreShown) {
            component.set('v.selectedProductId', null);
            this.evaluateToggleIsValid(component, event);
            component.set('v.shippingAddressModel', {'useCustomShippingAddress' : false});
        }
    },

    validate : function(component, event) {
        this.evaluateToggleIsValid(component, event);
        let isValid = component.get('v.toggleIsValid');
        let addressComponent = component.find('address');
        if (addressComponent) {
            isValid = addressComponent.validate() && isValid;
        }
        return isValid;
    },

    evaluateToggleIsValid : function(component, event) {
        let isValid = true;
        console.log(component.get('v.selectedProductId'));
        if (component.get('v.showGifts') && !component.get('v.selectedProductId')) {
            isValid = false;
        }
        component.set('v.toggleIsValid', isValid);
    }
})