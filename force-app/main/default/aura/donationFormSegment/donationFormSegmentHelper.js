({
    validate : function(component,event) {
        const validateChild = function(cmp){
            if(cmp.isInstanceOf('lightning:input')){
                const isValid = cmp.get('v.validity').valid;
                cmp.showHelpMessageIfInvalid();
                return isValid;
            } 
            else if (cmp.isInstanceOf('c:inputDuplicate')) {
                return cmp.validateFinal();
            } else if (cmp.isInstanceOf('c:inputCCNumber')) {
                return cmp.validate();
            } else if (cmp.isInstanceOf('c:inputPhone')) {
                return cmp.validate();
            }
            else {
                const cmpBody = cmp.get('v.body');
                if(!cmpBody || !cmpBody.length) {
                    return true;
                }
                let isValid = true;
                for (let i = 0; i < cmpBody.length; i++) {
                    isValid = validateChild(cmpBody[i]) && isValid;
                }
                return isValid;
            }
        }
        const formCmp = component.find("theForm");
        const isValid = validateChild(formCmp);
        if (isValid) {
           return true;
        }
        else return false;
    }
})