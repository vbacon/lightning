const expect = chai.expect;
var sandbox = sinon.sandbox.create();

describe("Product Tile Tray Wrapper", function() { 
    var cmp;
    var products = {
        true : [
            {
                'Id':'01t3C0000001',
                'Name': 'Product1',
                'Tagline__c': 'Product 1 Tagline',
                'One_Time_Price__c' : 50,
                'Sustainer_Price__c' : 5
            },
            {
                'Id':'01t3C0000002',
                'Name': 'Product2',
                'Tagline__c': 'Product 2 Tagline',
                'One_Time_Price__c' : 40,
                'Sustainer_Price__c' : 5
            },
            {
                'Id':'01t3C0000003',
                'Name': 'Product3',
                'Tagline__c': 'Product 3 Tagline',
                'One_Time_Price__c' : 30,
                'Sustainer_Price__c' : 5
            },
            {
                'Id':'01t3C0000004',
                'Name': 'Product4',
                'Tagline__c': 'Product 4 Tagline',
                'One_Time_Price__c' : 20,
                'Sustainer_Price__c' : 5
            }
        ],
        false : [
            {
                'Id':'01t3C0000001',
                'Name': 'Product5',
                'Tagline__c': 'Product 5 Tagline',
                'One_Time_Price__c' : 50,
                'Sustainer_Price__c' : 5
            },
            {
                'Id':'01t3C0000002',
                'Name': 'Product6',
                'Tagline__c': 'Product 6 Tagline',
                'One_Time_Price__c' : 40,
                'Sustainer_Price__c' : 5
            },
            {
                'Id':'01t3C0000003',
                'Name': 'Product7',
                'Tagline__c': 'Product 7 Tagline',
                'One_Time_Price__c' : 30,
                'Sustainer_Price__c' : 5
            },
            {
                'Id':'01t3C0000004',
                'Name': 'Product8',
                'Tagline__c': 'Product 8 Tagline',
                'One_Time_Price__c' : 20,
                'Sustainer_Price__c' : 5
            }
        ]
    };
    var shippingAddressModel = {
        'useCustomShippingAddress' : false
    };
    describe('c:donationFormProductTilesWrapper', function() {
        beforeEach(function(done) {
            var res = {getState : function(){return "SUCCESS";}, getReturnValue : function(){return products;}};
            sandbox.stub($A, "enqueueAction").callsFake(function(action) {
                var cb = action.getCallback("SUCCESS")
                cb.fn.apply(cb.s, [res]);
            });
            $T.createComponent('c:donationFormProductTilesWrapper',
                {
                    'defaultAmount' : 50,
                    'defaultIsMonthly' : 'false',
                    'shippingAddressModel' : shippingAddressModel
                } , true)
            .then(function(component) {
                cmp = component;
                done();
            })
            .catch(function(error) {
                done(error);
            });
        });
        afterEach(function() {
            $T.clearRenderedTestComponents();
            sandbox.restore();
        });

        it('toggles the gift tray on and off correctly', function(done) {
            expect(cmp.find('productTiles')).to.be.undefined;
            cmp.set('v.showGifts', true);
            expect(cmp.find('productTiles')).to.not.be.undefined;
            cmp.set('v.showGifts', false);
            expect(cmp.find('productTiles')).to.be.undefined;
            done();
        });

        it('displays nothing when toggled off', function(done) {
            cmp.set('v.showGifts', false);
            var tileTray = cmp.find('productTiles');
            expect(tileTray).to.be.undefined;
            done();
        })

        it('displays up to four products when toggled on', function(done) {
            cmp.set('v.showGifts', true);
            var tileTray = cmp.find('productTiles');
            expect(tileTray).to.not.be.undefined;
            var tiles = tileTray.find('aProductTile');
            expect(tiles.length).to.equal(4);
            for (var i = 0; i < tiles.length; i++) {
                expect(tiles[i].find('productName')).to.not.be.undefined;
                expect(tiles[i].find('productName').getElement().innerText).to.equal(products[false][i].Name);
            }
            done();
        });

        it('display toggle error message if product is not selected when toggled on', function(done) {
            cmp.set('v.showGifts', true);
            cmp.set('v.selectedProductId', null);
            expect(cmp.validate()).to.be.false;
            expect(cmp.find('giftToggleErrorMsg')).to.not.be.undefined;
            done();
        });

        it('hide toggle error message if product is selected when toggled on', function(done) {
            cmp.set('v.showGifts', true);
            var selectedId = products[true][0].Id;
            cmp.set('v.selectedProductId', null);
            expect(cmp.validate()).to.be.false;
            cmp.set('v.selectedProductId', selectedId);
            expect(cmp.find('giftToggleErrorMsg')).to.be.undefined;
            expect(cmp.validate()).to.be.true;
            done();
        });

        it('rebuilds available products when donation is changed', function(done) {
            cmp.set('v.showGifts', true);
            $T.fireApplicationEvent('c:donationAmountChangeEvent', {'amount': 100, 'isMonthly': 'true'});
            var tileTray = cmp.find('productTiles');
            var tiles = tileTray.find('aProductTile');
            for (var i = 0; i < tiles.length; i++) {
                expect(tiles[i].find('productName')).to.not.be.undefined;
                expect(tiles[i].find('productName').getElement().innerText).to.equal(products[true][i].Name);
            }
            done();
        });

        it('disables itself and shows a helptext if there are no products', function(done) {
            cmp.set('v.allProducts', {true: [], false: []});
            $T.fireApplicationEvent('c:donationAmountChangeEvent', {'amount': 5, 'isMonthly': 'true'});
            expect(cmp.find('toggleCheckbox').get('v.disabled')).to.be.true;            
            expect(cmp.get('v.showGifts')).to.be.false;
            expect(cmp.find('helpText')).to.not.be.undefined;
            done();
        });

        it('displays select icon and address form if product is selected', function(done){
            var selectedId = products[false][0].Id;
            cmp.set('v.selectedProductId', selectedId);
            cmp.set('v.showGifts', true);
            var tileTray = cmp.find('productTiles');
            var tiles = tileTray.find('aProductTile');
            for (var i = 0; i < tiles.length; i++) {
                if ((tiles[i].get('v.product').Id === selectedId)) {
                    expect(tiles[i].find('selectedIcon')).to.not.be.undefined;
                }
                else {
                    expect(tiles[i].find('selectedIcon')).to.be.undefined;
                }
            }
            expect(cmp.find('address')).to.not.be.undefined;
            done();
        });

        it('does not show select icon at all if no product is selected', function(done){
            cmp.set('v.showGifts', true);
            var tileTray = cmp.find('productTiles');
            var tiles = tileTray.find('aProductTile');
            for (var i = 0; i < products.length; i++) {
                expect(tiles[i].find('selectedIcon')).to.be.undefined;
            }
            done();
        });

        it('stops showing the select icon for a product when a different product is selected', function(done) {
            cmp.set('v.showGifts', true);
            var tileTray = cmp.find('productTiles');
            var tiles = tileTray.find('aProductTile');
            var selectedFirstId = products[false][0].Id;
            cmp.set('v.selectedProductId', selectedFirstId);
            for (var i = 0; i < tiles.length; i++) { 
                if (tiles[i].get('v.product').Id === selectedFirstId ) {
                    expect(tiles[i].find('selectedIcon')).to.not.be.undefined;
                } else {
                    expect(tiles[i].find('selectedIcon')).to.be.undefined;
                }
            }
            var selectedSecondId = products[false][1].Id;
            cmp.set('v.selectedProductId', selectedSecondId);
            for (var i = 0; i < tiles.length; i++) {               
                if (tiles[i].get('v.product').Id === selectedSecondId ) {
                    expect(tiles[i].find('selectedIcon')).to.not.be.undefined;
                } else {
                    expect(tiles[i].find('selectedIcon')).to.be.undefined;
                }
            }
            done();
        });

        it('deselects product tile when show gifts is toggled off', function(done) {
            cmp.set('v.showGifts', true);
            var productId = cmp.get('v.selectedProductId');
            expect(productId).to.be.null;
            var selectProdId = products[false][0].Id;
            cmp.set('v.selectedProductId', selectProdId);
            cmp.set('v.showGifts', false);
            var expectedProductId =  cmp.get('v.selectedProductId');
            expect(expectedProductId).to.be.null;
            done();
        });

        it('deselects product tile when donation amount change event is fired', function(done) {
            cmp.set('v.showGifts', true);
            var selectedProdId = products[false][0].Id;
            cmp.set('v.selectedProductId', selectedProdId);
            $T.fireApplicationEvent("c:donationAmountChangeEvent", {"amount": 100, "isMonthly": 'true'});
            var resultingProdId = cmp.get('v.selectedProductId');
            expect(resultingProdId).to.be.null;
            done();
        });
    });

    describe('c:productTile', function() {
        var cmp;
        beforeEach(function(done) {
            $T.createComponent('c:productTile', {'product' : products[false][0]}, true)
            .then(function(component) {
                cmp = component;
                done();
            })
            .catch(function(error) {
                done(error);
            });
        });
        afterEach(function() {
            $T.clearRenderedTestComponents();
            sandbox.restore();
        });

        it('emits the products id when a product is selected', function(done){
            cmp.addEventHandler('productTileSelectionEvent', function(event) {
                expect(event.getParam('productTileSelected')).to.equal(products[false][0].Id);
                done();
            })
            $T.run(cmp.productTileSelection_Test);
        });

        it('emits a null value when same product is selected a second time', function(done){
            cmp.set('v.selectedProductId', cmp.get('v.product').Id);
            cmp.addEventHandler('productTileSelectionEvent', function(event) {
                expect(event.getParam('productTileSelected')).to.be.null;
                done();
            })
            $T.run(cmp.productTileSelection_Test);
        }); 
    });

    describe('c:productShippingAddress', function(done) {
        var cmp;
        beforeEach(function(done) {
            shippingAddressModel = {'useCustomShippingAddress' : false};
            $T.createComponent('c:productShippingAddress',
                {
                    'shippingAddressModel' : shippingAddressModel,
                    'useCustomShippingAddress' : shippingAddressModel.useCustomShippingAddress
                }, true)
            .then(function(component) {
                cmp = component;
                done();
            })
            .catch(function(error) {
                done(error);
            });
        });
        afterEach(function() {
            $T.clearRenderedTestComponents();
            sandbox.restore();
        });

        it('validates when no input is required', function(done) {
            expect(cmp.validate()).to.be.true;
            done();
        });

        it('validates a correct and complete input', function(done) {
            cmp.set('v.useCustomShippingAddress', true);
            shippingAddressModel.useCustomShippingAddress = true;
            shippingAddressModel.street = '123 Main St';
            shippingAddressModel.city = 'San Francisco';
            shippingAddressModel.state = 'California';
            shippingAddressModel.postalCode = 94111;
            cmp.set('v.shippingAddressModel', shippingAddressModel);
            expect(cmp.validate()).to.be.true;
            done();
        });

        it('does not validate an incomplete input', function(done) {
            cmp.set('v.useCustomShippingAddress', true);
            shippingAddressModel.useCustomShippingAddress = true;
            shippingAddressModel.street = '123 Main St';
            shippingAddressModel.city = 'San Francisco';
            cmp.set('v.shippingAddressModel', shippingAddressModel);
            expect(cmp.validate()).to.be.false;
            done();
        });
    })
});
