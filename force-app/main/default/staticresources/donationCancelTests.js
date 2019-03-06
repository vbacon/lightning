const expect = chai.expect; 
var sandbox = sinon.sandbox.create(); 

describe("donation cancel quickaction", function(){
    var cmp;
    afterEach(function() { 
        $T.clearRenderedTestComponents();
        sandbox.restore();
    });
    describe('c:donationCancel', function(){
        it('doesnt let you click the button if the donation has already been cancelled', function(done) {
            var cmp;
            var mockResponseValue = {'Is_Cancelled__c' : true, 'Is_Monthly__c': true};
            var res = {                                                                   
                getState : function(){return "SUCCESS";},
                getReturnValue : function(){return mockResponseValue;}
            };
            sandbox.stub($A, "enqueueAction").callsFake(function(action) {                 
                var cb = action.getCallback("SUCCESS")
                cb.fn.apply(cb.s, [res]);
            });
            $T.createComponent('c:donationCancel', {'recordId' : '12341234'}, true)
            .then(function(component) {
                cmp = component;
                expect(cmp.find('authButtonDisabled')).to.not.be.undefined;
                expect(cmp.find('authButton')).to.be.undefined;
                done();
            })
            .catch(function(error) {
                done(error);
            });
        });

        it('doesnt let you click the button if the donation is not monthly', function(done) {
            var cmp;
            var mockResponseValue = {'Is_Cancelled__c' : false, 'Is_Monthly__c': false};
            var res = {                                                                   
                getState : function(){return "SUCCESS";},
                getReturnValue : function(){return mockResponseValue;}
            };
            sandbox.stub($A, "enqueueAction").callsFake(function(action) {                 
                var cb = action.getCallback("SUCCESS")
                cb.fn.apply(cb.s, [res]);
            });
            $T.createComponent('c:donationCancel', {'recordId' : '12341234'}, true)
            .then(function(component) {
                cmp = component;
                expect(cmp.find('authButtonDisabled')).to.not.be.undefined;
                expect(cmp.find('authButton')).to.be.undefined;
                done();
            })
            .catch(function(error) {
                done(error);
            });
        });

        it('lets you click the button if the donation is an active, monthly donation', function(done) {
            var cmp;
            var mockResponseValue = {'Is_Cancelled__c' : false, 'Is_Monthly__c': true};
            var res = {                                                                    
                getState : function(){return "SUCCESS";},
                getReturnValue : function(){return mockResponseValue;}
            };
            sandbox.stub($A, "enqueueAction").callsFake(function(action) {                 
                var cb = action.getCallback("SUCCESS")
                cb.fn.apply(cb.s, [res]);
            });
            $T.createComponent('c:donationCancel', {'recordId' : '12341234'}, true)
            .then(function(component) {
                cmp = component;
                expect(cmp.find('authButtonDisabled')).to.be.undefined; 
                expect(cmp.find('authButton')).to.not.be.undefined;
                done();
            })
            .catch(function(error) {
                done(error);
            })
           
        });
    });
});