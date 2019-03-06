({
    validateAddress : function(component, event) {
        var addressFormCmp = component.find('addressForm');
        if (addressFormCmp) {
            return addressFormCmp.validate();
        }
        else {
            return true;
        }
    }
})
