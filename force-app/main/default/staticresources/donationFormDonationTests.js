const expect = chai.expect;
var sandbox = sinon.sandbox.create();

describe('c:donationFormDonation', function() {
    var donation = {
        'sobjectType' : 'Opportunity',
        'Initial_Payment_Amount__c' : 10.00,
        'Is_Monthly__c' : 'false'
    };
    var cmp;
    beforeEach(function(done) {
        $T.createComponent('c:donationFormDonation', {'donation' : donation}, true)
        .then(function(component) {
            cmp = component;
            done();
        })
        .catch(function(error) {
            done(error);
        });
    });

    it('contains ask string buttons', function(done) {
        var askStringTray = cmp.find('oneTimeAskStringTray');
        var askStringButtons = askStringTray.find('askStringButton');
        expect(askStringButtons.length).to.equal(cmp.get('v.oneTimeAskStringValues').length);
        for (let i = 0; i < askStringButtons.length; i++) {
            expect(askStringButtons[i].get('v.askStringAmount')).to.equal(cmp.get('v.oneTimeAskStringValues')[i]);
        }
        done();
    });

    it('changes ask string values when donation type is changed', function(done) {
        cmp.set('v.donation.Is_Monthly__c', 'true');
        var askStringTray = cmp.find('monthlyAskStringTray');
        var askStringButtons = askStringTray.find('askStringButton');
        expect(askStringButtons.length).to.equal(cmp.get('v.monthlyAskStringValues').length);
        for (let i = 0; i < askStringButtons.length; i++) {
           expect(askStringButtons[i].get('v.askStringAmount')).to.equal(cmp.get('v.monthlyAskStringValues')[i]);
        }
        done();
    });

    it('contains custom ask string buttons', function(done) {
        cmp.set('v.customOneTimeAskString',"40,45,50,55,60,65,75");
        $T.run(cmp.custAskString_Test);
        var askStringTray = cmp.find('oneTimeAskStringTray');
        var askStringButtons = askStringTray.find('askStringButton');
        expect(askStringButtons.length).to.equal(cmp.get('v.oneTimeAskStringValues').length);
        done();
    });

    it('contains monthly ask string values when donation type is changed', function(done) {
        cmp.set('v.donation.Is_Monthly__c', 'true');
        cmp.set('v.customMonthlyAskString',"10,15,30,40,45,50,55");
        $T.run(cmp.custAskString_Test);
        var askStringTray = cmp.find('monthlyAskStringTray');
        var askStringButtons = askStringTray.find('askStringButton');
        expect(askStringButtons.length).to.equal(cmp.get('v.monthlyAskStringValues').length);
        done();
    });

    it('correctly validates complete input', function(done) {
        cmp.set('v.donation.Initial_Payment_Amount__c', 40);
        expect(cmp.validate()).to.be.true;
        done();
    });

    it('correct validates incomplete input', function(done) {
        cmp.set('v.donation.Initial_Payment_Amount__c', null);
        expect(cmp.validate()).to.be.false;
        done();
    });

    it('clears the other amount input when a preset value is selected', function(done) {
        var otherAmountInput = cmp.find('otherAmountInput').getElement();
        otherAmountInput.value = '123.12'; // not a value that should be found in a preset
        var askButton = cmp.find('oneTimeAskStringTray').find('askStringButton')[0];
        askButton.setDonationAmount_test();
        expect(otherAmountInput.value).to.equal('');
        expect(cmp.get('v.donation').Initial_Payment_Amount__c).to.equal(askButton.get('v.askStringAmount'));
        done();
    });

    it('clears the other amount input wen the donation type is changed', function(done) {
        var otherAmountInput = cmp.find('otherAmountInput').getElement();
        otherAmountInput.value = '123.12';
        var donation = cmp.get('v.donation');
        donation.Is_Monthly__c = !donation.Is_Monthly__c;
        cmp.set('v.donation', donation);
        expect(otherAmountInput.value).to.equal('');
        done();
    });
});