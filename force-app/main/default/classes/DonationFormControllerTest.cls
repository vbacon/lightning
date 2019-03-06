@isTest
public with sharing class DonationFormControllerTest {

    private static final String PAYMENT_METHOD_STRING = '{"worldpayOrderId":"' +
        VantivUtilitiesMock.ORDER_ID + 
        '","payType":"Credit Card","cardExpMonth":"10","cardExpYear":"2029",' +
        '"cardNumber":"4000123412341234","cardType":"Visa","cardCVV":"123"}';

    static testMethod void standardizeBillingAddressTest() {
        Contact testContact = new Contact(FirstName = 'Test',
                                            LastName = 'Test',
                                            MailingStreet = '123 Test St.',
                                            MailingCity = 'Testville',
                                            MailingState = 'CA',
                                            MailingPostalCode = '91111');
        UspsUtilitiesMock mock = new UspsUtilitiesMock();
        mock.address2 = '123 TEST STREET';
        mock.city = 'TESTVILLE';
        mock.state = 'CA';
        mock.zip5 = '91110';
        mock.zip4 = '1234';
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            DonationFormController.standardizeBillingAddress(testContact);
        Test.stopTest();
        // These assertions are placeholders for when we have a USPS callout mock to assert against
        System.assertEquals(mock.address2, testContact.Standardized_Street_2__c, 'Expect the standardized address to be stamped on the contact');
        System.assertEquals(mock.city, testContact.Standardized_City__c, 'Expect the standardized address to be stamped on the contact');
        System.assertEquals(mock.state, testContact.Standardized_State__c, 'Expect the standardized address to be stamped on the contact');
        System.assertEquals(mock.zip5 + '-' + mock.zip4, testContact.Standardized_Postal_Code__c, 'Expect the standardized address to be stamped on the contact');
    }

    static testMethod void buildOpportunityTest() {
        Contact theContact = new Contact();
        theContact.FirstName = 'TestName';
        theContact.LastName = 'T';
        theContact.MailingStreet = 'mariposa';
        insert theContact;
        Contact requeriedContact = [select AccountId from Contact where Id =: theContact.Id];
        Opportunity opty = new Opportunity();
        opty.Initial_Payment_Amount__c = 100;
        PaymentMethodModel paymentData = new PaymentMethodModel();
        paymentData.payType = 'Credit Card';
        Test.startTest();
            Opportunity builtOpty = DonationFormController.buildOpportunity(opty, theContact, paymentData);
        Test.stopTest();
        System.assertEquals(paymentData.payType, builtOpty.Payment_Method__c, 'Expect the built opportunity to have the correct payment method');
        System.assertEquals('Closed Won', builtOpty.StageName, 'Expect the opportunity to be closed/won');
    }

    static testMethod void testStandardizeShippingAddress_useBillingAddress() {
        Contact theContact = new Contact(FirstName = 'First2', LastName = 'Last2', email = 'test@example.com', phone = '4155551212',
            MailingStreet = '456 Main St.', MailingCity = 'A City', MailingState = 'CA', MailingPostalCode = '12345');
        UspsUtilitiesMock mock = new UspsUtilitiesMock();
        theContact.Standardized_Street_2__c = mock.address2;
        theContact.Standardized_City__c = mock.city;
        theContact.Standardized_State__c = mock.state;
        theContact.Standardized_Postal_Code__c = mock.zip5;
        Opportunity theOpp = new Opportunity(CloseDate = Date.today(), Name = 'test opp', StageName = 'Prospecting', Is_Monthly__c = false,
                Contact__c = theContact.Id, Initial_Payment_Amount__c = 100);

        DonationFormController.AddressModel shippingAddress = new DonationFormController.AddressModel();
        shippingAddress.useCustomShippingAddress = false;
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            DonationFormController.standardizeShippingAddress(theOpp, theContact, shippingAddress);
        Test.stopTest();
        System.assertEquals(theContact.MailingStreet, theOpp.Shipping_Street__c,
                'Expect opportunity address to be mapped from contact');
        System.assertEquals(theContact.Standardized_Street_2__c, theOpp.Standardized_Street_2__c,
                'Expect opportunity standardized address to be mapped from contact');
        System.assert([SELECT Id FROM Error_Log__c].isEmpty(), 'Expect no error logs');
    }

    static testMethod void testStandardizeShippingAddress_customShippingAddress() {
        Contact theContact = new Contact(FirstName = 'First2', LastName = 'Last2', email = 'test@example.com', phone = '4155551212',
            MailingStreet = '456 Main St.', MailingCity = 'A City', MailingState = 'CA', MailingPostalCode = '12345');
        Opportunity theOpp = new Opportunity(CloseDate = Date.today(), Name = 'test opp', StageName = 'Prospecting', Is_Monthly__c = false,
                Contact__c = theContact.Id, Initial_Payment_Amount__c = 100);

        DonationFormController.AddressModel shippingAddress = new DonationFormController.AddressModel();
        shippingAddress.useCustomShippingAddress = true;
        shippingAddress.street = 'NOT ' + theContact.MailingStreet;
        UspsUtilitiesMock mock = new UspsUtilitiesMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            DonationFormController.standardizeShippingAddress(theOpp, theContact, shippingAddress);
        Test.stopTest();
        System.assertEquals(shippingAddress.street, theOpp.Shipping_Street__c,
                'Expect opportunity address to be mapped from shipping address model');
        System.assertEquals(mock.address2, theOpp.Standardized_Street_2__c,
                'Expect opportunity standardized address to be mapped from response');
        System.assert([SELECT Id FROM Error_Log__c].isEmpty(), 'Expect no error logs');
    }

    public static testMethod void testSetOpportunityMembershipValues_oneTime_Basic() {
        Contact theContact = new Contact(FirstName = 'First2', LastName = 'Last2', email = 'test@example.com', phone = '4155551212',
            MailingStreet = '456 Main St.', MailingCity = 'A City', MailingState = 'CA', MailingPostalCode = '12345');
        Opportunity theOpp = new Opportunity(CloseDate = Date.today(), Name = 'test opp', StageName = 'Prospecting', Is_Monthly__c = false,
                Contact__c = theContact.Id, Initial_Payment_Amount__c = 100);

        Test.startTest();
            DonationFormController.setOpportunityMembershipValues(theOpp);
        Test.stopTest();

        System.assert(theOpp.Membership_Active__c, 'Membership status should been Active.');
        System.assertEquals(Date.today().addMonths(12).month(), theOpp.Projected_End_Date__c.month(), 'Membership projected end date should be set correctly.');
        System.assertEquals(MembershipUtilities.MEMBERSHIP_TIER_BASIC, theOpp.Membership_Tier__c, 'Membership tier should be basic.');
    }

    public static testMethod void testSetOpportunityMembershipValues_sustainer_Leadership() {
        Contact theContact = new Contact(FirstName = 'First2', LastName = 'Last2', email = 'test@example.com', phone = '4155551212',
            MailingStreet = '456 Main St.', MailingCity = 'A City', MailingState = 'CA', MailingPostalCode = '12345');
        Opportunity theOpp = new Opportunity(CloseDate = Date.today(), Name = 'test opp', StageName = 'Prospecting', Is_Monthly__c = true,
                Contact__c = theContact.Id, Initial_Payment_Amount__c = 30);

        Test.startTest();
            DonationFormController.setOpportunityMembershipValues(theOpp);
        Test.stopTest();

        System.assert(theOpp.Membership_Active__c, 'Membership status should been Active.');
        System.assertEquals(Date.today().addMonths(1).month(), theOpp.Projected_End_Date__c.month(), 'Membership projected end date should be set correctly.');
        System.assertEquals(MembershipUtilities.MEMBERSHIP_TIER_LEADERSHIP, theOpp.Membership_Tier__c, 'Membership tier should be leadership.');
    }

    static testMethod void buildOpportunityProductTest() {
        List<Account> account = TestUtilities.createAccounts(1, true);
        List<Account> vendor = TestUtilities.createVendors(1, true);
        Opportunity testOpp = TestUtilities.createOpportunities(account, 1, false)[0];
        testOpp.Pricebook2Id = Test.getStandardPricebookId();
        insert testOpp;
        Product2 testProduct = TestUtilities.createProducts(1, vendor[0].Id, true)[0];
        // pbe created by product insert trigger
        PricebookEntry testPbe = [SELECT Id, UnitPrice FROM PricebookEntry
                                    WHERE Product2Id = :testProduct.Id
                                    AND Pricebook2Id = :Test.getStandardPricebookId()];
        Test.startTest();
            OpportunityLineItem oli = DonationFormController.buildOpportunityProduct(testOpp, testProduct.Id);
        Test.stopTest();
        System.assertEquals(testPbe.UnitPrice, oli.UnitPrice, 'Expect the oli\'s list price to map to the pricebookentry\'s list price');
        System.assertEquals(1, oli.Quantity, 'Expect the oli\'s quantity to be 1');
    }

    static testMethod void submitDonationTest_success() {
        Account testVendor = TestUtilities.createVendors(1, true)[0];
        Product2 testProduct = TestUtilities.createProducts(1, testVendor.Id, true)[0];
        Contact testContact = TestUtilities.createContacts(1, false)[0];
        testContact.MailingStreet = '2601 Mariposa St';
        testContact.MailingCity = 'San Francisco';
        testContact.MailingState = 'CA';
        testContact.MailingPostalCode = '94110';
        Opportunity testOpp = new Opportunity(Initial_Payment_Amount__c = 100, Is_Monthly__c = false);
        DonationFormController.AddressModel shippingAddress = new DonationFormController.AddressModel();

        Test.setMock(HttpCalloutMock.class, new MultiRequestMock());
        Test.startTest();
            DonationFormController.submitDonation(testContact, testOpp, PAYMENT_METHOD_STRING, testProduct.Id, JSON.serialize(shippingAddress));
        Test.stopTest();

        List<Contact> newContact = [SELECT Id, FirstName, LastName, AccountId FROM Contact];
        System.assertEquals(1, newContact.size(), 'Expect one new contact to be inserted');
        System.assert(newContact[0].AccountId != null, 'Expect one new account to be tied to the new contact');
        
        Opportunity newOpp = [SELECT Id, Contact__c, AccountId, Initial_Payment_Amount__c, Auth_Transaction__c, Worldpay_Token__c,
                                            Shipping_Street__c, Shipping_City__c, Shipping_State__c, Shipping_Postal_Code__c,
                                                (SELECT Id, Amount__c, Capture_Sale_Transaction__c, Status__c, Worldpay_Order_Id__c FROM Payments__r),
                                                (SELECT Id, Product2Id FROM OpportunityLineItems)
                                    FROM Opportunity];
        System.assertNotEquals(null, newOpp.Auth_Transaction__c, 'Expect transaction Id to be populated by the worldpay authorization');
        System.assertNotEquals(null, newOpp.Worldpay_Token__c, 'Expect worldpay token Id to be populated by the worldpay authorization');

        System.assertEquals(1, newOpp.Payments__r.size(), 'Expect one payment to be included with the opportunity because the opportunity is one time');
        Payment__c resultPayment = newOpp.Payments__r[0];
        System.assertEquals(VantivUtilitiesMock.ORDER_ID, resultPayment.Worldpay_Order_Id__c,
            'Expect the order Id returned from worldpay to be stamped on the payment');
        System.assertEquals(newOpp.Initial_Payment_Amount__c, resultPayment.Amount__c, 'Expect the payments amount to equal the opportunitys amount');

        System.assertEquals(1, newOpp.OpportunityLineItems.size(), 'Expect one opportunity line item');
        System.assertEquals(testProduct.Id, newOpp.OpportunityLineItems[0].Product2Id, 'Expect the olis product to be the product whose Id was passed into the submit method');
    }

    //This test (specifically ContactMatch.getUniqueContact) expects at least one active Contact duplicate rule in the org!
    static testMethod void submitDonationTest_success_duplicateContact() {
        Account testVendor = TestUtilities.createVendors(1, true)[0];
        Product2 testProduct = TestUtilities.createProducts(1, testVendor.Id, true)[0];
        Contact testContact = TestUtilities.createContacts(1, false)[0];
        testContact.MailingStreet = '2601 Mariposa St';
        testContact.MailingCity = 'San Francisco';
        testContact.MailingState = 'CA';
        testContact.MailingPostalCode = '94110';
        Opportunity testOpp = new Opportunity(Initial_Payment_Amount__c = 100, Is_Monthly__c = false);
        DonationFormController.AddressModel shippingAddress = new DonationFormController.AddressModel();

        Contact dupeContact = testContact.clone();
        insert testContact;
        Test.setMock(HttpCalloutMock.class, new MultiRequestMock());
        Test.startTest();
            DonationFormController.submitDonation(dupeContact, testOpp, PAYMENT_METHOD_STRING, testProduct.Id, JSON.serialize(shippingAddress));
        Test.stopTest();

        List<Contact> newContact = [SELECT Id, FirstName, LastName, AccountId FROM Contact];
        System.assertEquals(1, newContact.size(), 'Expect only one new contact to have been inserted');
        System.assertEquals(testContact.Id, newContact[0].Id,
            'Expect the only contact to be the one that already existed because the new contact is a duplicate');
    }
}