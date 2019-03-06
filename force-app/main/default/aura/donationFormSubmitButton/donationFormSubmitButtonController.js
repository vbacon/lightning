({
    handleSubmitButtonAmountChange : function(component, event, helper){
        var monthly = event.getParam('isMonthly');
        var amount = event.getParam('amount');
        component.set('v.amount', amount);
        component.set('v.isMonthly', monthly);
    },
    
    handleButtonClick : function(component, event, helper){
        var onClickEvent = component.getEvent('submitButtonClickEvent');
        onClickEvent.fire();
    }
})
