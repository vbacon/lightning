({
    selectProductTile : function(component, event) {
        var selectedProductId = component.get("v.selectedProductId");
        var productId = component.get("v.product").Id;
        var productSelected = component.get("v.product");

        if (selectedProductId !== productId) {
            var cmpEvent = component.getEvent("productTileSelectionEvent");
            cmpEvent.setParams({
                'productTileSelected' : productId,
                'productSelected' : productSelected
            });
            cmpEvent.fire();
        } else {
            var cmpEvent = component.getEvent('productTileSelectionEvent');
            cmpEvent.setParams({
                'productTileSelected' : null,
                'productSelected' : null
            });
            cmpEvent.fire();
        }
    },
    
    showProductMoreInfo : function(component, event) {
        const product = component.get('v.product');
        const displaySustainerPrice = component.get('v.displaySustainerPrice');
        
        $A.createComponent("c:productMoreInfo", { "product" : product, " displaySustainerPrice" : displaySustainerPrice }, 
                function(msgBox) {
            if (component.isValid()) {
                    var targetCmp = component.find('productTileModalPlaceholder');
                    targetCmp.set("v.body", msgBox);
            }
        });
    }
})
