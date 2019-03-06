@isTest
public with sharing class VantivUtilitiesTest {

    @testSetup static void setup() {
        Date thisDay = Date.today();
        Contact theContact = new Contact(FirstName = 'First2', LastName = 'Last2', email = 'test@example.com', phone = '4155551212',
                Standardized_Street_1__c = '456 Main St.', Standardized_City__c = 'A City', Standardized_State__c = 'CA', Standardized_Postal_Code__c = '12345');
        insert theContact;
        Opportunity theOpp = new Opportunity(CloseDate = thisDay, Name = 'test opp', StageName = 'Prospecting',
                Contact__c = theContact.Id, Initial_Payment_Amount__c = 10.01,
                Auth_Transaction__c = VantivUtilitiesMock.AUTH_TRANSACTION, Worldpay_Token__c = VantivUtilitiesMock.WORLDPAY_TOKEN);
        insert theOpp;
    }

    public static testMethod void testAuthorizeCard() {

        Contact theContact = [SELECT FirstName, LastName, Email, Phone, MailingStreet, MailingCity, MailingState, MailingPostalCode, 
                                Standardized_Street_1__c, Standardized_Street_2__c, Standardized_City__c,
                                Standardized_State__c, Standardized_Postal_Code__c FROM Contact LIMIT 1];
        Opportunity theOpp = [SELECT CloseDate, Name, StageName, Contact__c, Initial_Payment_Amount__c FROM Opportunity LIMIT 1];
        
        PaymentMethodModel thePayMeth = new PaymentMethodModel();
        thePayMeth.payType = 'Credit Card';
        thePayMeth.cardType = 'VI';
        thePayMeth.cardExpMonth = '10';
        thePayMeth.cardExpYear = '29';
        thePayMeth.cardNumber = '4000123412341234';
        thePayMeth.cardCVV = '123';
        thePayMeth.worldpayOrderId = VantivUtilitiesMock.ORDER_ID;

        Boolean isAuthorized;
        Test.setMock(HttpCalloutMock.class, new VantivUtilitiesMock());
        Test.startTest();
            isAuthorized = VantivUtilities.authorizeCard(theContact, theOpp, thePayMeth);
        Test.stopTest();

        System.assert(isAuthorized, 'Expect authorization method to return true when the authorization succeeds');
    }

    public static testMethod void testAuthorizeCard_decline() {

        Contact theContact = [SELECT FirstName, LastName, Email, Phone, MailingStreet, MailingCity, MailingState, MailingPostalCode,
                                Standardized_Street_1__c, Standardized_Street_2__c, Standardized_City__c,
                                Standardized_State__c, Standardized_Postal_Code__c FROM Contact LIMIT 1];
        Opportunity theOpp = [SELECT CloseDate, Name, StageName, Contact__c, Initial_Payment_Amount__c FROM Opportunity LIMIT 1];
        
        PaymentMethodModel thePayMeth = new PaymentMethodModel();
        thePayMeth.payType = 'Credit Card';
        thePayMeth.cardType = 'VI';
        thePayMeth.cardExpMonth = '10';
        thePayMeth.cardExpYear = '29';
        thePayMeth.cardNumber = '4000123412341234';
        thePayMeth.cardCVV = '123';
        thePayMeth.worldpayOrderId = VantivUtilitiesMock.ORDER_ID;

        VantivUtilitiesMock theMock = new VantivUtilitiesMock();
        theMock.vantivResponseCode = '123';
        theMock.message = 'Failed';

        Test.setMock(HttpCalloutMock.class, theMock);
        Test.startTest();
            Boolean isAuthorized = VantivUtilities.authorizeCard(theContact, theOpp, thePayMeth);
        Test.stopTest();

        System.assert(!isAuthorized, 'Expect authorization to fail because vantiv response code was not 000');
    }

    public static testMethod void testAuthorizeCard_fail() {

        Contact theContact = [SELECT FirstName, LastName, Email, Phone, MailingStreet, MailingCity, MailingState, MailingPostalCode,
                                Standardized_Street_1__c, Standardized_Street_2__c, Standardized_City__c,
                                Standardized_State__c, Standardized_Postal_Code__c FROM Contact LIMIT 1];
        Opportunity theOpp = [SELECT CloseDate, Name, StageName, Contact__c, Initial_Payment_Amount__c FROM Opportunity LIMIT 1];
        
        PaymentMethodModel thePayMeth = new PaymentMethodModel();
        thePayMeth.payType = 'Credit Card';
        thePayMeth.cardType = 'VI';
        thePayMeth.cardExpMonth = '10';
        thePayMeth.cardExpYear = '29';
        thePayMeth.cardNumber = '4000123412341234';
        thePayMeth.cardCVV = '123';
        thePayMeth.worldpayOrderId = VantivUtilitiesMock.ORDER_ID;

        VantivUtilitiesMock theMock = new VantivUtilitiesMock();
        theMock.statusCode = 500;

        String exceptionMessage;
        Test.setMock(HttpCalloutMock.class, theMock);
        Test.startTest();
            try {
                VantivUtilities.authorizeCard(theContact, theOpp, thePayMeth);
            }
            catch (Exception e) {
                exceptionMessage = e.getMessage();
            }
        Test.stopTest();

        System.assertEquals(VantivUtilities.AUTH_FAILURE_MSG, exceptionMessage, 'Expect the exception message to reflect that callout failed');
    }

    public static testMethod void testProcessAuthorizationResponse() {

        VantivUtilitiesMock theMock = new VantivUtilitiesMock();
        String mockAuthResponse = theMock.getTestAuthorizationResponse();

        Contact theContact = [SELECT FirstName, LastName, Email, Phone, Standardized_Street_1__c, Standardized_Street_2__c, Standardized_City__c,
                                Standardized_State__c, Standardized_Postal_Code__c FROM Contact LIMIT 1];
        Opportunity theOpp = [SELECT CloseDate, Name, StageName, Contact__c, Initial_Payment_Amount__c FROM Opportunity LIMIT 1];
        
        PaymentMethodModel thePayMeth = new PaymentMethodModel();
        thePayMeth.payType = 'Credit Card';
        thePayMeth.cardType = 'VI';
        thePayMeth.cardExpMonth = '10';
        thePayMeth.cardExpYear = '29';
        thePayMeth.cardNumber = '4000123412341234';
        thePayMeth.cardCVV = '123';
        thePayMeth.worldpayOrderId = VantivUtilitiesMock.ORDER_ID;

        Test.startTest();
            VantivUtilities.processAuthorizationResponse(mockAuthResponse, theOpp, thePayMeth);
        Test.stopTest();

        System.assertEquals(VantivUtilitiesMock.AUTH_TRANSACTION, theOpp.Auth_Transaction__c);
        System.assertEquals('1029', theOpp.Card_Expiration__c);
        System.assertEquals('VI', theOpp.Card_Type__c);
        System.assertEquals(VantivUtilitiesMock.CREDIT_CARD_BIN ,theOpp.Credit_Card_Bin__c);
        System.assertEquals(VantivUtilitiesMock.WORLDPAY_TOKEN ,theOpp.Worldpay_Token__c);
    }

    public static testMethod void testChargeCard() {

        Opportunity captureOpp = [SELECT CloseDate, Name, StageName, Contact__c, Initial_Payment_Amount__c, Auth_Transaction__c, Worldpay_Token__c
                                FROM Opportunity LIMIT 1];

        Payment__c thePayment = new Payment__c(Worldpay_Token__c = 'Default token',
                Opportunity__c = captureOpp.Id, Amount__c = 10.01,
                Worldpay_Order_Id__c = VantivUtilitiesMock.ORDER_ID);
        insert thePayment;

        VantivUtilitiesMock theMock = new VantivUtilitiesMock();
        Test.setMock(HttpCalloutMock.class, theMock);
        Test.startTest();
            VantivUtilities.chargeCard(thePayment.Id);
        Test.stopTest();

        Payment__c createdPayment = [SELECT Id, Status__c, Amount__c, Worldpay_Token__c,
                Post_Date__c, Opportunity__r.Initial_Payment_Amount__c, Opportunity__r.Worldpay_Token__c, Message__c
                FROM Payment__c];

        System.assertEquals(PaymentServices.APPROVED_STATUS, createdPayment.Status__c, 'Expect payment status to reflect that card was approved');
        System.assertEquals(VantivUtilitiesMock.POST_DATE, createdPayment.Post_Date__c, 'Expect post date to reflect that payment was processed');
        System.assertEquals(theMock.message, createdPayment.Message__c, 'Expect the message to be stamped on the payment');
		System.assertEquals(captureOpp.Worldpay_Token__c, createdPayment.Worldpay_Token__c, 'Expect token to be stamped on payment');
    }

    public static testMethod void testChargeCard_decline() {

        Opportunity captureOpp = [SELECT CloseDate, Name, StageName, Contact__c, Initial_Payment_Amount__c, Auth_Transaction__c, Worldpay_Token__c
                                FROM Opportunity LIMIT 1];

        Payment__c thePayment = new Payment__c(Opportunity__c = captureOpp.Id,
                Amount__c = 10.01, Worldpay_Order_Id__c = VantivUtilitiesMock.ORDER_ID);
        insert thePayment;

        VantivUtilitiesMock theMock = new VantivUtilitiesMock();
        theMock.vantivResponseCode = '123';
        theMock.message = 'Failed';

        Test.setMock(HttpCalloutMock.class, theMock);
        Test.startTest();
            VantivUtilities.chargeCard(thePayment.Id);
        Test.stopTest();

        Payment__c createdPayment = [SELECT Id, Status__c, Amount__c, Worldpay_Token__c,
                Opportunity__r.Initial_Payment_Amount__c, Opportunity__r.Worldpay_Token__c, Message__c
                FROM Payment__c];

        System.assertEquals(PaymentServices.DECLINED_STATUS, createdPayment.Status__c,
            'Expect payment status to be declined because card was not approved');
        System.assertEquals(theMock.message, createdPayment.Message__c, 'Expect the message to be stamped on the payment');
		System.assert(String.isBlank(createdPayment.Worldpay_Token__c), 'Expect token NOT to be stamped on payment if capture failed');
    }

    public static testMethod void testChargeCard_fail() {

        Opportunity captureOpp = [SELECT CloseDate, Name, StageName, Contact__c, Initial_Payment_Amount__c, Auth_Transaction__c, Worldpay_Token__c
                                FROM Opportunity LIMIT 1];

        Payment__c thePayment = new Payment__c(Opportunity__c = captureOpp.Id,
                Amount__c = 10.01, Worldpay_Order_Id__c = VantivUtilitiesMock.ORDER_ID);
        insert thePayment;

        VantivUtilitiesMock theMock = new VantivUtilitiesMock();
        theMock.statusCode = 500;

        Test.setMock(HttpCalloutMock.class, theMock);
        Test.startTest();
            VantivUtilities.chargeCard(thePayment.Id);
        Test.stopTest();

        Payment__c createdPayment = [SELECT Id, Status__c, Amount__c, Worldpay_Token__c,
                Opportunity__r.Initial_Payment_Amount__c, Opportunity__r.Worldpay_Token__c, Message__c
                FROM Payment__c];

        System.assertEquals(PaymentServices.FAILED_STATUS, createdPayment.Status__c,
            'Expect payment status to be failed because callout was not successful');
        System.assertEquals(VantivUtilities.CAPTURE_FAILURE_MSG, createdPayment.Message__c, 'Expect the message to be stamped on the payment');
		System.assert(String.isBlank(createdPayment.Worldpay_Token__c), 'Expect token NOT to be stamped on payment if capture failed');
    }

    public static testMethod void testProcessCaptureResponse() {

        VantivUtilitiesMock theMock = new VantivUtilitiesMock();
        String mockCaptureResponse = theMock.getTestCaptureResponse();

        Opportunity captureOpp = [SELECT CloseDate, Name, StageName, Contact__c, Initial_Payment_Amount__c, Auth_Transaction__c, Worldpay_Token__c
                                FROM Opportunity LIMIT 1];

        Payment__c thePayment = new Payment__c(Worldpay_Token__c = captureOpp.Worldpay_Token__c,
                Opportunity__c = captureOpp.Id, Amount__c = 10.01);
        insert thePayment;

        Test.startTest();
            VantivUtilities.processCaptureResponse(mockCaptureResponse, thePayment);
        Test.stopTest();

        System.assertEquals(VantivUtilitiesMock.CAPTURE_TRANSACTION, thePayment.Capture_Sale_Transaction__c);
        System.assertEquals(VantivUtilitiesMock.POST_DATE, thePayment.Post_Date__c);
    }

    public static testMethod void testPerformSale() {
        Opportunity captureOpp = [SELECT CloseDate, Name, StageName, Contact__c, Initial_Payment_Amount__c, Auth_Transaction__c, Worldpay_Token__c
                                FROM Opportunity LIMIT 1];

        Payment__c testPayment = TestUtilities.createPayment(captureOpp, true);

        Payment__c requeriedPayment = [SELECT Id, Scheduled_Post_Date__c, Status__c, Opportunity__c, Opportunity__r.Id,
								        Worldpay_Token__c ,Opportunity__r.Initial_Payment_Amount__c, Amount__c
                        		        FROM Payment__c WHERE Id = :testPayment.Id];

        VantivUtilitiesMock theMock = new VantivUtilitiesMock();
        
        Test.setMock(HttpCalloutMock.class, theMock);
        Test.startTest();
            VantivUtilities.performSale(requeriedPayment);
        Test.stopTest();
        System.assertEquals(PaymentServices.APPROVED_STATUS, requeriedPayment.Status__c, 'Expect payment status to reflect that sale was approved');
        System.assertEquals(VantivUtilitiesMock.POST_DATE, requeriedPayment.Post_Date__c, 'Expect the post date to be updated');
        System.assertEquals(theMock.message, requeriedPayment.Message__c, 'Expect the message to be stamped on the payment');
	}

    public static testMethod void testPerformSale_decline() {
        Opportunity captureOpp = [SELECT CloseDate, Name, StageName, Contact__c, Initial_Payment_Amount__c, Auth_Transaction__c, Worldpay_Token__c
                                FROM Opportunity LIMIT 1];

        Payment__c testPayment = TestUtilities.createPayment(captureOpp, true);

        Payment__c requeriedPayment = [SELECT Id, Scheduled_Post_Date__c, Status__c, Opportunity__c, Opportunity__r.Id,
								        Worldpay_Token__c, Opportunity__r.Initial_Payment_Amount__c, Amount__c
                        		        FROM Payment__c WHERE Id = :testPayment.Id];

        VantivUtilitiesMock theMock = new VantivUtilitiesMock();
        theMock.vantivResponseCode = '123';
        theMock.message = 'Failure';

        Test.setMock(HttpCalloutMock.class, theMock);
        Test.startTest();
            VantivUtilities.performSale(requeriedPayment);
        Test.stopTest();
        System.assertEquals(PaymentServices.DECLINED_STATUS, requeriedPayment.Status__c, 'Expect payment status to reflect that sale was declined');
        System.assertEquals(null, requeriedPayment.Post_Date__c, 'Expect the post date not to update if the sale did not succeed');
        System.assertEquals(theMock.message, requeriedPayment.Message__c, 'Expect the message to be stamped on the payment');
	}

    public static testMethod void testPerformSale_failure() {
        Opportunity captureOpp = [SELECT CloseDate, Name, StageName, Contact__c, Initial_Payment_Amount__c, Auth_Transaction__c, Worldpay_Token__c
                                FROM Opportunity LIMIT 1];

        Payment__c testPayment = TestUtilities.createPayment(captureOpp, true);

        Payment__c requeriedPayment = [SELECT Id, Scheduled_Post_Date__c, Status__c, Opportunity__c, Opportunity__r.Id,
								        Worldpay_Token__c, Opportunity__r.Initial_Payment_Amount__c, Amount__c
                        		        FROM Payment__c WHERE Id = :testPayment.Id];

        VantivUtilitiesMock theMock = new VantivUtilitiesMock();
        theMock.statusCode = 500;

        Test.setMock(HttpCalloutMock.class, theMock);
        Test.startTest();
            VantivUtilities.performSale(requeriedPayment);
        Test.stopTest();
        System.assertEquals(PaymentServices.FAILED_STATUS, requeriedPayment.Status__c, 'Expect payment status to reflect that sale failed');
        System.assertEquals(VantivUtilities.SALE_FAILURE_MSG, requeriedPayment.Message__c, 'Expect payment message to reflect that sale failed');
    }

    public static testMethod void testProcessSaleResponse() {
        VantivUtilitiesMock theMock = new VantivUtilitiesMock();
        String mockSaleResponse = theMock.getTestSaleResponse();
        Opportunity captureOpp = [SELECT CloseDate, Name, StageName, Contact__c, Initial_Payment_Amount__c, Auth_Transaction__c, Worldpay_Token__c
                                FROM Opportunity LIMIT 1];

        Payment__c testPayment = TestUtilities.createPayment(captureOpp, true);

        Payment__c requeriedPayment = [SELECT Id, Scheduled_Post_Date__c, Status__c, Opportunity__c, Opportunity__r.Id,
								        Worldpay_Token__c, Opportunity__r.Initial_Payment_Amount__c, Amount__c
                        		        FROM Payment__c WHERE Id = :testPayment.Id];

        Test.startTest();
            VantivUtilities.processSaleResponse(mockSaleResponse, testPayment);
        Test.stopTest();
        System.assertEquals(VantivUtilitiesMock.SALE_TRANSACTION_ID, testPayment.Capture_Sale_Transaction__c);
    }

    public static testMethod void testPerformRefund() {
        Payment__c refundPayment;
        Opportunity captureOpp = [SELECT CloseDate, Name, StageName, Contact__c, Initial_Payment_Amount__c, Auth_Transaction__c, Worldpay_Token__c
                                FROM Opportunity LIMIT 1];

        Payment__c testPayment = TestUtilities.createPayment(captureOpp, false);
        testPayment.Status__c = PaymentServices.APPROVED_STATUS;
        testPayment.Capture_Sale_Transaction__c = VantivUtilitiesMock.CAPTURE_TRANSACTION;
        testPayment.Post_Date__c = Date.today();
        insert testPayment;

        VantivUtilitiesMock theMock = new VantivUtilitiesMock();
        Test.setMock(HttpCalloutMock.class, theMock);
        Exception thrownException;        
        Test.startTest();
            try {
                refundPayment = VantivUtilities.performRefund(testPayment);
            }
            catch (Exception e) {
                thrownException = e;
            }
        Test.stopTest();
        
        System.assertEquals(null, thrownException, 'Expect no exception to be thrown');
        System.assertEquals(PaymentServices.REFUNDED_STATUS, refundPayment.Status__c, 'Expect the child payment to reflect that it has been refunded');
        System.assertEquals(VantivUtilitiesMock.POST_DATE, refundPayment.Post_Date__c, 'Expect the post date to reflect the date from the response');
	}

    public static testMethod void testPerformRefund_decline() {
        Payment__c refundPayment;
        Opportunity captureOpp = [SELECT CloseDate, Name, StageName, Contact__c, Initial_Payment_Amount__c, Auth_Transaction__c, Worldpay_Token__c
                                FROM Opportunity LIMIT 1];

        Payment__c testPayment = TestUtilities.createPayment(captureOpp, false);
        testPayment.Status__c = PaymentServices.APPROVED_STATUS;
        testPayment.Capture_Sale_Transaction__c = VantivUtilitiesMock.CAPTURE_TRANSACTION;
        testPayment.Post_Date__c = Date.today();
        insert testPayment;

        VantivUtilitiesMock theMock = new VantivUtilitiesMock();
        theMock.vantivResponseCode = '123';
        theMock.message = 'Failure';
        Test.setMock(HttpCalloutMock.class, theMock);
        Exception thrownException;
        Test.startTest();
            try {
                refundPayment = VantivUtilities.performRefund(testPayment);
            }
            catch (Exception e) {
                thrownException = e;
            }
        Test.stopTest();

        System.assertEquals(null, thrownException, 'Expect no exception to be thrown');
        System.assertEquals(null, refundPayment, 'Expect no refund payment to be generated because the refund was declined');
	}

    public static testMethod void testPerformRefund_fail() {
        Opportunity captureOpp = [SELECT CloseDate, Name, StageName, Contact__c, Initial_Payment_Amount__c, Auth_Transaction__c, Worldpay_Token__c
                                FROM Opportunity LIMIT 1];

        Payment__c testPayment = TestUtilities.createPayment(captureOpp, false);
        testPayment.Status__c = PaymentServices.APPROVED_STATUS;
        testPayment.Capture_Sale_Transaction__c = VantivUtilitiesMock.CAPTURE_TRANSACTION;
        testPayment.Post_Date__c = Date.today();
        insert testPayment;

        VantivUtilitiesMock theMock = new VantivUtilitiesMock();
        theMock.statusCode = 500;
        Test.setMock(HttpCalloutMock.class, theMock);
        Exception thrownException;
        Test.startTest();
            try {
                Payment__c refundPayment = VantivUtilities.performRefund(testPayment);
            }
            catch (Exception e) {
                thrownException = e;
            }
        Test.stopTest();

        System.assertNotEquals(null, thrownException, 'Expect an exception to be thrown because the callout failed');
	}

    public static testMethod void testCardTypeAbbrev() {

        String typeAbbrev = VantivUtilities.getCardTypeAbbreviation('VI');
        System.assertEquals('VI', typeAbbrev);

        String typeAbbrev2 = VantivUtilities.getCardTypeAbbreviation('Visa');
        System.assertEquals('VI', typeAbbrev2);

        String typeAbbrev3 = VantivUtilities.getCardTypeAbbreviation('Mastercard');
        System.assertEquals('MC', typeAbbrev3);

        String typeAbbrev4 = VantivUtilities.getCardTypeAbbreviation('American Express');
        System.assertEquals('AX', typeAbbrev4);

        String typeAbbrev5 = VantivUtilities.getCardTypeAbbreviation('Discover');
        System.assertEquals('DI', typeAbbrev5);

    }

    public static testMethod void testDateStringCreation() {

        String theDateString = '2017-05-16';
        Date theDate  = Date.newInstance(2017, 5, 16);
        Date returnedDate = VantivUtilities.dateStringToDate(theDateString);
        System.assertEquals(theDate, returnedDate);

        String theDateString2 = '';
        Date returnedDate2 = VantivUtilities.dateStringToDate(theDateString2);
        System.assertEquals(null, returnedDate2);

    }

    public static testMethod void testExpriationStringCreation() {

        String theMonth = 'June';
        String theYear = '2018';
        String abbrevString = VantivUtilities.getExpirationAbbreviation(theMonth, theYear);
        System.assertEquals(abbrevString, '0618');

        String theMonth2 = '';
        String theYear2 = '';
        String abbrevString2 = VantivUtilities.getExpirationAbbreviation(theMonth2, theYear2);
        System.assertEquals(abbrevString2, '');

    }

}
