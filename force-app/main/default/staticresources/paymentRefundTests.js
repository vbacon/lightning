//paymentRefund lightning component testing

const expect = chai.expect; 
var sandbox = sinon.sandbox.create(); 

describe("payment refund", function(){
    var cmp;
    afterEach(function() { 
        $T.clearRenderedTestComponents();
        sandbox.restore();
    });
    describe('c:paymentRefund', function(){

        it('doesnt let you click the button if the payment has already been refunded', function(done) {
            var cmp;
            var mockResponseValue = true;
            var res = {                                                                   
                getState : function(){return "SUCCESS";},
                getReturnValue : function(){return mockResponseValue;}
            };
            sandbox.stub($A, "enqueueAction").callsFake(function(action) {                 
                var cb = action.getCallback("SUCCESS")
                cb.fn.apply(cb.s, [res]);
            });
            $T.createComponent('c:paymentRefund', {'recordId' : '12341234'}, true) // creating the component
            .then(function(component) {
                cmp = component;
                expect(cmp.find('authButtonDisabled')).to.be.ok;
                expect(cmp.find('authButton')).to.not.be.ok;
                done();
            })
            .catch(function(error) {
                done(error);
            });
        });

        it('lets you click the button if the payment has not been refunded', function(done) {
            var cmp;
            var mockResponseValue = 'false';
            var res = {                                                                    
                getState : function(){return "SUCCESS";},
                getReturnValue : function(){return mockResponseValue;}
            };
            sandbox.stub($A, "enqueueAction").callsFake(function(action) {                 
                var cb = action.getCallback("SUCCESS")
                cb.fn.apply(cb.s, [res]);
            });
            $T.createComponent('c:paymentRefund', {'recordId' : '12341234'}, true) // creating the component
            .then(function(component) {
                cmp = component;
                expect(cmp.find('authButtonDisabled')).to.not.be.ok; 
                expect(cmp.find('authButton')).to.be.ok;
                done();
            })
            .catch(function(error) {
                done(error);
            })
           
        });
    });
});