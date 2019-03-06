({
    checkDuplicateEmail : function(component, event, helper) {
        var dupeEmailInput = component.find('dupeInput');
        if (dupeEmailInput) {
            component.find('dupeInput').validate();
        }
    }
})