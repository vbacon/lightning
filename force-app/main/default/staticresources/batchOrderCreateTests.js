//batchOrderCreate lightning component testing

const expect = chai.expect; 
var sandbox = sinon.sandbox.create(); 

describe("batch order create", function(){
    var cmp;
    afterEach(function() { 
        $T.clearRenderedTestComponents();
        sandbox.restore();
    });
    describe('c:batchOrderCreation', function(){

        it('Disables button if no template found', function(done) {
            var cmp;
            var hasTemplate = {getState : function(){return "SUCCESS";}, getReturnValue : function(){return null;}};
            var hasProducts = {getState : function(){return "SUCCESS";}, getReturnValue : function(){return true;}};     
            sandbox.stub($A, "enqueueAction").callsFake(function(action) {
                if (action.getName() === 'getProductTemplateId') {
                    var cb = action.getCallback("SUCCESS")
                    cb.fn.apply(cb.s, [hasTemplate]);
                }
                else if (action.getName() === 'checkForNewOpportunityProducts') {
                    var cb = action.getCallback("SUCCESS")
                    cb.fn.apply(cb.s, [hasProducts]);
                }
            });
            $T.createComponent('c:batchOrderCreation', {'recordId' : '12341234'}, true) // creating the component
            .then(function(component) {
                cmp = component;
                expect(cmp.find('batchOrderButtonDisabled')).to.be.ok;
                expect(cmp.find('batchOrderButton')).to.not.be.ok;
                done();
            })
            .catch(function(error) {
                done(error);
            });
        });

        it('Disables button if template found but no New OLIs', function(done) {
            var cmp;
            var hasTemplate = {getState : function(){return "SUCCESS";}, getReturnValue : function(){return '12341234';}};
            var hasProducts = {getState : function(){return "SUCCESS";}, getReturnValue : function(){return false;}};            
            sandbox.stub($A, "enqueueAction").callsFake(function(action) {
                if (action.getName() === 'getProductTemplateId') {
                    var cb = action.getCallback("SUCCESS")
                    cb.fn.apply(cb.s, [hasTemplate]);
                }
                else if (action.getName() === 'checkForNewOpportunityProducts') {
                    var cb = action.getCallback("SUCCESS")
                    cb.fn.apply(cb.s, [hasProducts]);
                }
            });
            $T.createComponent('c:batchOrderCreation', {'recordId' : '12341234'}, true) // creating the component
            .then(function(component) {
                cmp = component;
                expect(cmp.find('batchOrderButtonDisabled')).to.be.ok;
                expect(cmp.find('batchOrderButton')).to.not.be.ok;
                done();
            })
            .catch(function(error) {
                done(error);
            });
        });

        it('Enables button if template found AND there are New OLIs', function(done) {
            var cmp;
            var hasTemplate = {getState : function(){return "SUCCESS";}, getReturnValue : function(){return '56785678';}};
            var hasProducts = {getState : function(){return "SUCCESS";}, getReturnValue : function(){return true;}};            
            sandbox.stub($A, "enqueueAction").callsFake(function(action) {
                if (action.getName() === 'getProductTemplateId') {
                    var cb = action.getCallback("SUCCESS")
                    cb.fn.apply(cb.s, [hasTemplate]);
                }
                else if (action.getName() === 'checkForNewOpportunityProducts') {
                    var cb = action.getCallback("SUCCESS")
                    cb.fn.apply(cb.s, [hasProducts]);
                }
            });
            $T.createComponent('c:batchOrderCreation', {'recordId' : '12341234'}, true) // creating the component
            .then(function(component) {
                cmp = component;
                expect(cmp.find('batchOrderButtonDisabled')).to.not.be.ok;
                expect(cmp.find('batchOrderButton')).to.be.ok;
                done();
            })
            .catch(function(error) {
                done(error);
            });
        });


    });
});