const expect = chai.expect;
var sandbox = sinon.sandbox.create();

describe("Donation Form", function() {
    var contact;
    var opportunity;
    var paymentMethod;
    var cmp;
    beforeEach(function() {
        contact = {
            'sobjectType' : 'Contact',
            'FirstName' : 'Test',
            'LastName' : 'Test',
            'Email' : 'test@test.com',
            'Phone' : '(123) 456-7890',
            'MailingStreet' : '123 Main St',
            'MailingCity' : 'San Francisco',
            'MailingState' : 'CA',
            'MailingPostalCode' : '98765'
        };
        opportunity = {
            'sobjectType' : 'Opportunity',
            'Initial_Payment_Amount__c' : 10.00,
            'Is_Monthly__c' : 'false'
        };
        paymentMethod = {
            'payType' : 'Credit Card',
            'cardType' : 'Visa',
            'cardExpMonth' : '11',
            'cardExpYear' : '2022',
            'cardCVV' : '123',
            'cardNumber' : '4321432143214321'
        };
    });
    afterEach(function() {
        // Each spec (test) renders its components into the same div,
        // so we need to clear that div out at the end of each spec.
        $T.clearRenderedTestComponents();
        sandbox.restore();
    });

    describe('the complete donation form', function() {
        var cmp;
        describe('products exist', function() {
            var submitRes;
            var productsRes;
            var products = {
                true : [],
                false : [
                    {
                        'Id':'01t3C0000001',
                        'Name': 'Bose',
                        'Tagline__c': 'Bose Tagline',
                        'One_Time_Price__c' : 50,
                        'Sustainer_Price__c' : 5
                    }
                ]
            };
           
            beforeEach(function(done) {
                submitRes = {getState : function(){return "SUCCESS";}, getReturnValue : function(){return 'APPROVE';}};
                productsRes = {getState : function(){return "SUCCESS";}, getReturnValue : function(){return products;}};
                sandbox.stub($A, "enqueueAction").callsFake(function(action) {
                    if (action.getName() === 'getQualifyingProducts') {
                        var cb = action.getCallback("SUCCESS")
                        cb.fn.apply(cb.s, [productsRes]);
                    }
                    else if (action.getName() === 'submitDonation') {
                        var cb = action.getCallback("SUCCESS")
                        cb.fn.apply(cb.s, [submitRes]);
                    }
                    else {
                        done(new Error('unrecognized server action'));
                    }
                });
                $T.createComponent('c:donationFormMain', {'theContact' : contact, 'thePaymentMethod' : paymentMethod}, true)
                .then(function(component) {
                    cmp = component;
                    cmp.find('contact').find('dupeInput').find('theInput').getElement().value = contact.Email;
                    done();
                })
                .catch(function(error) {
                    done(error);
                })
            });

            it('should enable the products wrapper toggle', function(done){
                var donateCmp = cmp.find('donate');
                var productTileCmp = cmp.find('productsWrapper');
                var prodData = [];
                prodData = productTileCmp.get('v.products');
                expect(donateCmp.get('v.donation.Initial_Payment_Amount__c')).to.equal(productTileCmp.get('v.defaultAmount'));
                expect(donateCmp.get('v.donation.Is_Monthly__c')).to.equal(productTileCmp.get('v.defaultIsMonthly'));
                expect(productTileCmp.find('toggleCheckbox').get('v.disabled')).to.be.false;
                expect(prodData[0].Name).to.equal(products[false][0].Name);
                done();
            });

            it('contains all of the donation form components', function(done) {
                expect(cmp.find('donate')).to.not.be.undefined;
                expect(cmp.find('contact')).to.not.be.undefined;
                expect(cmp.find('payment')).to.not.be.undefined;
                expect(cmp.find('address')).to.not.be.undefined;
                expect(cmp.find('productsWrapper')).to.not.be.undefined;
                expect(cmp.find('submit')).to.not.be.undefined;
                done();
            });
           
            it('should open the review modal when all inputs are valid', function(done) {
                $T.run(cmp.reviewDonation_Test);
                $T.waitFor(function(){
                    return cmp.find('modalPlaceholder').getElement().children.length !== 0;
                }, 500, 50)
                .then(function(cmp){
                    done();
                })
                .catch(function(error){
                    done(error);
                });
            });
    
            it('should not open the review modal if the data is invalid', function(done) {
                cmp.set('v.theContact', {});
                $T.run(cmp.reviewDonation_Test);
                $T.waitFor(function(){
                    return cmp.find('modalPlaceholder').getElement().children.length !== 0;
                }, 500, 50)
                .then(function() {
                    done(new Error('modal should not have appeared'));
                })
                .catch(function(error){
                    done();
                });
            });
    
            it('correctly handles a successful tokenization', function(done) {
                opportunity = cmp.get('v.theDonation');
                $T.run(cmp.submit_Test);
                $T.waitFor(function(){
                    return cmp.find('theForm').get('v.body')[0].isInstanceOf('c:donationFormConfirmation');
                }, 500, 50)
                .then(function() {
                    expect(cmp.find('theForm').get('v.body')[0].get('v.theContact')).to.eql(contact);
                    expect(cmp.find('theForm').get('v.body')[0].get('v.theDonation').Initial_Payment_Amount__c).to.equal(opportunity.Initial_Payment_Amount__c);
                    done();
                })
                .catch(function(error){
                    done(new Error('The confirmation page should not have appeared'));
                });
            });
    
            it('correctly handles a successful submission that fails to tokenize', function(done) {
                submitRes.getReturnValue = function(){return 'DECLINE';}; // DECLINE - Card is declined
                $T.run(cmp.submit_Test);
                $T.waitFor(function(){
                    return cmp.find('theForm').get('v.body')[0].isInstanceOf('c:donationFormConfirmation');
                }, 500, 50)
                .then(function() {
                    done(new Error('The confirmation page should not have appeared'));
                })
                .catch(function(error) {
                    expect(cmp.get('v.thePaymentMethod').cardCVV).to.be.empty;
                    done();
                });
            });
    
            it('correctly handles an unsuccessful submission', function(done) {
                submitRes.getReturnValue = function(){return 'ERROR';};
                $T.run(cmp.submit_Test);
                $T.waitFor(function(){
                    return cmp.find('theForm').get('v.body')[0].isInstanceOf('c:donationFormConfirmation');
                }, 500, 50)
                .then(function() {
                    done(new Error('The confirmation page should not have appeared'));
                })
                .catch(function(error) {
                    expect(cmp.get('v.thePaymentMethod').cardCVV).to.be.empty;
                    done();
                });
            });
    
            it('correctly handles an unsuccessful submission', function(done) {
                submitRes.getState = function(){return "ERROR";};
                submitRes.getError = function(){return 'error message';};
                $T.run(cmp.submit_Test);
                $T.waitFor(function(){
                    return cmp.find('theForm').get('v.body')[0].isInstanceOf('c:donationFormConfirmation');
                }, 500, 50)
                .then(function() {
                    done(new Error('The confirmation page should not have appeared'));
                })
                .catch(function(error) {
                    expect(cmp.get('v.thePaymentMethod').cardCVV).to.be.empty;
                    done();
                });
            });
        });
        
        describe('products do not exist', function() {
            var submitRes;
            var productsResWithoutProduct;
            var products = {
                true : [],
                false : []
            };

            beforeEach(function(done) {
                submitRes = {getState : function(){return "SUCCESS";}, getReturnValue : function(){return 'APPROVE';}};
                productsResWithoutProduct = {getState : function(){return "SUCCESS";}, getReturnValue : function(){return products;}};
                sandbox.stub($A, "enqueueAction").callsFake(function(action) {
                    if (action.getName() === 'getQualifyingProducts') {
                        var cb = action.getCallback("SUCCESS")
                        cb.fn.apply(cb.s, [productsResWithoutProduct]);
                    }
                    else if (action.getName() === 'submitDonation') {
                        var cb = action.getCallback("SUCCESS")
                        cb.fn.apply(cb.s, [submitRes]);
                    }
                    else {
                        done('unrecognized server action');
                    }
                });
                $T.createComponent('c:donationFormMain', {'theContact' : contact, 'thePaymentMethod' : paymentMethod}, true)
                .then(function(component) {
                    cmp = component;
                    cmp.find('contact').find('dupeInput').find('theInput').getElement().value = contact.Email;
                    done();
                })
                .catch(function(error) {
                    done(error);
                })
            });

            it('should disable the products wrapper toggle', function(done){
                var donateCmp = cmp.find('donate');
                var productTileCmp = cmp.find('productsWrapper');
                var prodData = [];
                prodData = productTileCmp.get('v.products');
                expect(donateCmp.get('v.donation.Initial_Payment_Amount__c')).to.equal(productTileCmp.get('v.defaultAmount'));
                expect(donateCmp.get('v.donation.Is_Monthly__c')).to.equal(productTileCmp.get('v.defaultIsMonthly'));
                expect(productTileCmp.find('toggleCheckbox').get('v.disabled')).to.be.true;
                expect(prodData).to.be.empty;
                done();
            });
        });

    });

    describe('the contact information component', function() {
        beforeEach(function(done) {
            $T.createComponent('c:donationFormContact', {'theContact' : contact}, true)
            .then(function(component) {
                cmp = component;
                done();
            })
            .catch(function(error) {
                done(error);
            });
        });

        it('correctly validates complete input', function(done) {
            cmp.find('dupeInput').find('theInput').getElement().value = contact.Email;
            expect(cmp.validate()).to.be.true;
            done();
        });

        it('correct validates incomplete input', function(done) {
            cmp.set('v.theContact', {});
            expect(cmp.validate()).to.be.false;
            done();
        });

        it('correctly fails to validate when inputDuplicate fails to match', function(done) {
            cmp.find('dupeInput').find('theInput').getElement().value = contact.Email + 'asdf';
            expect(cmp.validate()).to.be.false;
            done();
        });
    });

    describe('the address information component', function() {
        beforeEach(function(done) {
            $T.createComponent('c:donationFormAddress', {
                'street' : contact.MailingStreet,
                'city' : contact.MailingCity,
                'state' : contact.MailingState,
                'postalCode' : contact.MailingPostalCode
            }, true)
            .then(function(component) {
                cmp = component;
                done();
            })
            .catch(function(error) {
                done(error);
            });
        });

        it('correctly validates complete input', function(done) {
            expect(cmp.validate()).to.be.true;
            done();
        });

        it('correct validates incomplete input', function(done) {
            cmp.set('v.street', undefined);
            expect(cmp.validate()).to.be.false;
            done();
        });
    });

    describe('the payment information component', function() {
        beforeEach(function(done) {
            $T.createComponent('c:donationFormPayment', {'thePaymentMethod' : paymentMethod}, true)
            .then(function(component) {
                cmp = component;
                done();
            })
            .catch(function(error) {
                done(error);
            });
        });

        it('correctly validates complete input', function(done) {
            expect(cmp.validate()).to.be.true;
            done();
        });

        it('correct validates incomplete input', function(done) {
            cmp.set('v.thePaymentMethod', {});
            expect(cmp.validate()).to.be.false;
            done();
        });
    });

    describe('the review component', function() {
        beforeEach(function(done) {
            $T.createComponent('c:donationFormReview', {'theContact' : contact, 'theDonation' : opportunity, 'thePM' : paymentMethod}, true)
            .then(function(component) {
                cmp = component;
                done();
            })
            .catch(function(error) {
                done(error);
            });
        });

        it('destroys itself when cancel is called', function(done) {
            cmp.cancelButton_Test();
            expect(cmp.isValid()).to.be.false;
            done();
        });

        it('fires the correct event and destroys itself when submit is called', function(done) {
            var componentEvent;
            cmp.addEventHandler('donationFormCheckoutEvent', function(event) {
                expect(event).to.be.ok;
                componentEvent = event;
                $T.waitFor(function() {
                    return (!cmp.isValid());
                }, 500, 50)
                .then(function() {
                    done();
                })
                .catch(function() {
                    done(new Error('component was never destroyed'));
                });
            });
            $T.run(cmp.saveButton_Test);
            $T.waitFor(function() {
                return (componentEvent);
            }, 500, 50)
            .catch(function() {
                done(new Error('event was never fired'));
            });
        });
    });

    describe('the submit button component', function() {
        beforeEach(function(done) {
            $T.createComponent('c:donationFormSubmitButton', {'donateButtonDisabled' : false}, true)
            .then(function(component) {
                cmp = component;
                done();
            })
            .catch(function(error) {
                done(error);
            });
        });

        it('handle submit event when submit button is called', function(done) {
            var componentEvent;
            cmp.addEventHandler('submitButtonClickEvent', function(event) {
                done();
            })
            $T.run(cmp.submitButton_Test);
        });

        it('handle donation amount change in submit button when donation is changed', function(done) {
            $T.fireApplicationEvent('c:donationAmountChangeEvent', {'amount': 5, 'isMonthly': 'true'});
            expect(cmp.get('v.isMonthly')).to.equal('true');
            expect(cmp.get('v.amount')).to.equal(5);
            done();
        });
    });
    
});