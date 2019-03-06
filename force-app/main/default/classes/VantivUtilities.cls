public with sharing class VantivUtilities {

	public static final String AUTH_FAILURE_MSG = 'authorization status code not 200';
	public static final String CAPTURE_FAILURE_MSG = 'capture status code not 200';
	public static final String SALE_FAILURE_MSG = 'sale status code not 200';
	public static final String REFUND_FAILURE_MSG = 'credit status code not 200';
	public static final String VANTIV_NAMESPACE = 'http://www.vantivcnp.com/schema';

    public static Boolean authorizeCard(Contact theContact, Opportunity theOpportunity, PaymentMethodModel thePaymentMethod) {

		// This method makes an 'authorization' call to Vantiv.  If successful, a hold is put on
		// the credit card for the amount specified.  The card is not actually charged at this
		// point.  It is charged via a second 'capture' call that references the transaction ID
		// returned from the first call.  This second call is done in the chargeCard method below.
		
		// Will return Boolean whether card was able to be tokenized.
		// If tokenization was successful, return true
		// If tokenization was unsuccessful but callout was made successfully, return false
		// If an exception was thrown during tokenization, throw an AuraHandledException

        String resBody;

        HttpRequest req = new HttpRequest();
        Http http = new Http();
        // String url = 'https://transact.vantivprelive.com/vap/communicator/online';  // defined in Named Credential

	    // Create request to send to Vantiv
        req.setEndPoint('callout:Vantiv');
		req.setMethod('POST');
	    req.setHeader('Content-Type','text/xml');
        String requestBody = createAuthorizationXMLString(theContact, theOpportunity, thePaymentMethod);
        req.setbody(requestBody);
        req.setHeader('Content-Length', String.valueof(requestBody.length()));

        // Post HTTP Request and process response
		HttpResponse res = http.send(req);
		if(res.getStatusCode() == 200) {   // Successful authentication
			resBody = res.getBody();
			return processAuthorizationResponse(resBody, theOpportunity, thePaymentMethod);
		}
		else {
			throw new VantivUtilitiesException(AUTH_FAILURE_MSG);
		}
	}

	@future (callout=true)
    public static void chargeCard(Id paymentId) {

		Payment__c thePayment = [SELECT Id, Worldpay_Token__c, Capture_Sale_Transaction__c, Post_Date__c,
				Status__c, Worldpay_Order_Id__c, Opportunity__c, Opportunity__r.Id, Opportunity__r.Contact__r.Id,
				Opportunity__r.Worldpay_Token__c, Opportunity__r.Auth_Transaction__c, Opportunity__r.Initial_Payment_Amount__c
				FROM Payment__c WHERE Id = :paymentId];

		String resBody;

        HttpRequest req = new HttpRequest();
        Http http = new Http();

	    // Create request to send to Vantiv
        req.setEndPoint('callout:Vantiv');
		req.setMethod('POST');
	    req.setHeader('Content-Type','text/xml');
        String requestBody = createCaptureXMLString(thePayment);
        req.setbody(requestBody);
        req.setHeader('Content-Length', String.valueof(requestBody.length()));

        // Post HTTP Request and process response
	    try  {
            HTTPResponse res = http.send(req);
            if(res.getStatusCode() == 200) {   // Successful authentication
           		resBody = res.getBody();
           		processCaptureResponse(resBody, thePayment);
            }
			else {
				throw new VantivUtilitiesException(CAPTURE_FAILURE_MSG);
			}
        } catch(Exception e){
			thePayment.Status__c = PaymentServices.FAILED_STATUS;
        	thePayment.Message__c = e.getMessage();
        }

		try {
			update thePayment;
		}
		catch(DmlException e) {
			ErrorLog.logError(e, 'VantivUtilities', 'Exception updating payment record');
			ErrorLog.commitErrors();
		}

		// Need to send email from here since this is a future job that can't return anything.
		// COMMENTING THIS OUT UNTIL WE CAN DETERMINE HOW TO DISABLE DELIVERABILITY IN SCRATCH ORGS
		// ... and uncommenting for testing purposes.
		if (thePayment.Status__c == PaymentServices.APPROVED_STATUS) {
			SendDonationConfirmationEmail email = new SendDonationConfirmationEmail(thePayment.Opportunity__r.Id);
			email.sendConfirmationEmail();
		}
	}

	public static Payment__c performSale(Payment__c thePayment) {

		String resBody;
	    // Payment__c updatePayment = new Payment__c();

        HttpRequest req = new HttpRequest();
        Http http = new Http();

	    // Create request to send to Vantiv
        req.setEndPoint('callout:Vantiv');
		req.setMethod('POST');
	    req.setHeader('Content-Type','text/xml');
		//Creating sale request for vantiv
        String requestBody = createSaleXMLString(thePayment);
        req.setbody(requestBody);
        req.setHeader('Content-Length', String.valueof(requestBody.length()));
		try{
			// Post HTTP Request and process response
			HttpResponse response = http.send(req);
			if(response.getStatusCode() == 200) {   // Successful authentication
           		resBody = response.getBody();
           		processSaleResponse(resBody, thePayment);
			} else {
				throw new VantivUtilitiesException(SALE_FAILURE_MSG);
			}
        } catch(Exception e){
			thePayment.Status__c = PaymentServices.FAILED_STATUS;
        	thePayment.Message__c = e.getMessage();
        }
		//returning payment object to DonationFormPaymentBatch.execute method
		return thePayment;
	}

	public static Payment__c performRefund(Payment__c thePayment) {
		
		String httpResponse;
	    String responseCode = 'ERROR';
		Payment__c refundPayment;
        HttpRequest req = new HttpRequest();
        Http http = new Http();
        
	    // Create request to send to Vantiv
        req.setEndPoint('callout:Vantiv');
		req.setMethod('POST');
	    req.setHeader('Content-Type','text/xml');

		//Creating credit/refund request for vantiv
        String requestBody = createRefundXMLString(thePayment);
	
		req.setbody(requestBody);
        req.setHeader('Content-Length', String.valueof(requestBody.length()));

		try {
			// Post HTTP Request and process response
			HTTPResponse response = http.send(req);
			
			if(response.getStatusCode() == 200) {   // Successful authentication
           		httpResponse = response.getBody();
				//processing refund response from vantiv
           		refundPayment = processRefundResponse(httpResponse);
			} else {
				throw new VantivUtilitiesException(REFUND_FAILURE_MSG);
			}

        } catch(Exception e){
			throw new VantivUtilitiesException(e.getMessage());
        }
		//returning payment object to PaymentRefundController.refundDonation method
		return refundPayment;
	}

	public static String createRefundXMLString(Payment__c thePayment) {
		XmlStreamWriter w = new XmlStreamWriter();

        String userId = '{!$Credential.UserName}'; 
        String password = '{!$Credential.Password}';
        String merchantId = '1333056';
        
		w.writeStartElement(null, 'cnpOnlineRequest', null);
			w.writeAttribute(null, null, 'version', '12.1');
			w.writeAttribute(null, null, 'xmlns', VANTIV_NAMESPACE);
			w.writeAttribute(null, null, 'merchantId', merchantId);
        
            w.writeStartElement(null, 'authentication', null);
                w.writeStartElement(null, 'user', null);
                    w.writeCharacters(userId);
                w.writeEndElement();
                w.writeStartElement(null, 'password', null);
                    w.writeCharacters(password);
                w.writeEndElement();
            w.writeEndElement(); // authentication

            w.writeStartElement(null, 'credit', null);
                w.writeAttribute(null, null, 'id', thePayment.Worldpay_Order_Id__c); 
                w.writeAttribute(null, null, 'reportGroup', 'rptGrp');
             	w.writeStartElement(null, 'cnpTxnId', null);
                    w.writeCharacters(thePayment.Capture_Sale_Transaction__c); 
                w.writeEndElement();
			w.writeEndElement();
		w.writeEndElement();
		String XmlOutput = w.getXmlString();
        w.close();

        return XmlOutput;
	}

	public static String createAuthorizationXMLString(Contact theContact, Opportunity theOpportunity, PaymentMethodModel thePaymentMethod) {
        XmlStreamWriter w = new XmlStreamWriter();

        String userId = '{!$Credential.UserName}';
        String password = '{!$Credential.Password}';
        String merchantId = '1333056';

	   	// Vantiv takes the amount as an integer with no decimal place.
        Integer amtInteger = Integer.valueOf(theOpportunity.Initial_Payment_Amount__c * 100);
        String amtString = String.valueOf(amtInteger);

        String cardTypeString = getCardTypeAbbreviation(thePaymentMethod.cardType);
        String expirationString = getExpirationAbbreviation(thePaymentMethod.cardExpMonth, thePaymentMethod.cardExpYear);

		String address1 = theContact.Standardized_Street_1__c;
		String address = (String.isBlank(theContact.Standardized_Street_2__c)) ? theContact.MailingStreet : theContact.Standardized_Street_2__c;
		String city = (String.isBlank(theContact.Standardized_City__c)) ? theContact.MailingCity : theContact.Standardized_City__c;
		String state = (String.isBlank(theContact.Standardized_State__c)) ? theContact.MailingState : theContact.Standardized_State__c;
		String postalCode = (String.isBlank(theContact.Standardized_Postal_Code__c)) ? theContact.MailingPostalCode : theContact.Standardized_Postal_Code__c;

        w.writeStartElement(null, 'cnpOnlineRequest', null);
			w.writeAttribute(null, null, 'version', '12.1');
			w.writeAttribute(null, null, 'xmlns', VANTIV_NAMESPACE);
			w.writeAttribute(null, null, 'merchantId', merchantId);

            w.writeStartElement(null, 'authentication', null);
                w.writeStartElement(null, 'user', null);
                    w.writeCharacters(userId);
                w.writeEndElement();
                w.writeStartElement(null, 'password', null);
                    w.writeCharacters(password);
                w.writeEndElement();
            w.writeEndElement(); // authentication

            w.writeStartElement(null, 'authorization', null);
                w.writeAttribute(null, null, 'id', thePaymentMethod.worldpayOrderId);
                w.writeAttribute(null, null, 'reportGroup', 'RG1');

                w.writeStartElement(null, 'orderId', null);
                    w.writeCharacters(thePaymentMethod.worldpayOrderId);
                w.writeEndElement();

                w.writeStartElement(null, 'amount', null);
                    w.writeCharacters(amtString);
                w.writeEndElement();

                w.writeStartElement(null, 'orderSource', null);
                    w.writeCharacters('ecommerce'); // Effectively a constant.
                w.writeEndElement();

                w.writeStartElement(null, 'billToAddress', null);
                    w.writeStartElement(null, 'name', null);
                        w.writeCharacters(theContact.FirstName + ' ' + theContact.LastName);
                    w.writeEndElement();
					if (String.isNotBlank(theContact.Standardized_Street_1__c)) {
						w.writeStartElement(null, 'addressLine1', null);
							w.writeCharacters(theContact.Standardized_Street_1__c);
						w.writeEndElement();
					}
                    if (String.isNotBlank(address)) {
						w.writeStartElement(null, 'addressLine2', null);
							w.writeCharacters(address);
						w.writeEndElement();
					}
                    w.writeStartElement(null, 'city', null);
                        w.writeCharacters(city);
                    w.writeEndElement();
                    w.writeStartElement(null, 'state', null);
                        w.writeCharacters(state);
                    w.writeEndElement();
                    w.writeStartElement(null, 'zip', null);
                        w.writeCharacters(postalCode);
                    w.writeEndElement();
                    w.writeStartElement(null, 'country', null);
                        w.writeCharacters('USA');  // TO DO - Simply using USA at this time.
                    w.writeEndElement();
                    w.writeStartElement(null, 'email', null);
                        w.writeCharacters(theContact.email);
                    w.writeEndElement();
					if (theContact.phone != null) {
						w.writeStartElement(null, 'phone', null);
							w.writeCharacters(theContact.phone);
						w.writeEndElement();
					}
                w.writeEndElement(); // billToAddress

                w.writeStartElement(null, 'card', null);
                    w.writeStartElement(null, 'type', null);
                        w.writeCharacters(cardTypeString);
                    w.writeEndElement();
                    w.writeStartElement(null, 'number', null);
                        w.writeCharacters(thePaymentMethod.cardNumber);
                    w.writeEndElement();
                    w.writeStartElement(null, 'expDate', null);
                        w.writeCharacters(expirationString);
                    w.writeEndElement();
                    w.writeStartElement(null, 'cardValidationNum', null);
                        w.writeCharacters(thePaymentMethod.cardCVV);  // 3 or four chars
                    w.writeEndElement();
                w.writeEndElement(); // card

            w.writeEndElement(); // requestType

        w.writeEndElement(); // cnpOnlineRequest

        String xmlOutput = w.getXmlString();
        w.close();

        return xmlOutput;
    }

	public static String createCaptureXMLString(Payment__c thePayment) {
		// This method creates a 'capture' XML request.  The format of this is defined in the

        XmlStreamWriter w = new XmlStreamWriter();

        String userId = '{!$Credential.UserName}';
        String password = '{!$Credential.Password}';
        String merchantId = '1333056';


        w.writeStartElement(null, 'cnpOnlineRequest', null);
			w.writeAttribute(null, null, 'version', '12.1');
			w.writeAttribute(null, null, 'xmlns', VANTIV_NAMESPACE);
			w.writeAttribute(null, null, 'merchantId', merchantId);

            w.writeStartElement(null, 'authentication', null);
                w.writeStartElement(null, 'user', null);
                    w.writeCharacters(userId);
                w.writeEndElement();
                w.writeStartElement(null, 'password', null);
                    w.writeCharacters(password);
                w.writeEndElement();
            w.writeEndElement(); // authentication

            w.writeStartElement(null, 'capture', null);
                w.writeAttribute(null, null, 'id', thePayment.Worldpay_Order_Id__c);
                w.writeAttribute(null, null, 'reportGroup', 'RG1');
        		w.writeAttribute(null, null, 'partial', 'false');

				w.writeStartElement(null, 'cnpTxnId', null);
                    w.writeCharacters(thePayment.Opportunity__r.Auth_Transaction__c);
                w.writeEndElement();

            w.writeEndElement(); // requestType (capture)

        w.writeEndElement(); // cnpOnlineRequest

        String xmlOutput = w.getXmlString();
        w.close();

        return xmlOutput;
    }

	public static String createSaleXMLString(Payment__c thePayment) {
        XmlStreamWriter w = new XmlStreamWriter();

        String userId = '{!$Credential.UserName}';
        String password = '{!$Credential.Password}';
        String merchantId = '1333056';

        Integer amtInteger = Integer.valueOf(thePayment.Amount__c * 100);
        String amtString = String.valueOf(amtInteger);


        w.writeStartElement(null, 'cnpOnlineRequest', null);
			w.writeAttribute(null, null, 'version', '12.1');
			w.writeAttribute(null, null, 'xmlns', VANTIV_NAMESPACE);
			w.writeAttribute(null, null, 'merchantId', merchantId);
			w.writeStartElement(null, 'authentication', null);
				w.writeStartElement(null, 'user', null);
					w.writeCharacters(userId);
				w.writeEndElement();
				w.writeStartElement(null, 'password', null);
					w.writeCharacters(password);
				w.writeEndElement();
			w.writeEndElement(); // authentication
			w.writeStartElement(null, 'sale', null);
				w.writeAttribute(null, null, 'id', thePayment.Id); // currently adding payment id
				w.writeAttribute(null, null, 'reportGroup', 'RG1');
				w.writeStartElement(null, 'orderId', null);
					w.writeCharacters(thePayment.Id); // currently adding payment id
				w.writeEndElement();
				w.writeStartElement(null, 'amount', null);
					w.writeCharacters(amtString);
				w.writeEndElement();
				w.writeStartElement(null, 'orderSource', null);
					w.writeCharacters('ecommerce');
				w.writeEndElement();
				w.writeStartElement(null, 'token', null);
					w.writeStartElement(null, 'cnpToken', null);
						w.writeCharacters(thePayment.Worldpay_Token__c);
					w.writeEndElement();
				w.writeEndElement(); // token
			w.writeEndElement(); // sale
		w.writeEndElement(); // cnpOnlineRequest
        String xmlOutput = w.getXmlString();
        w.close();
        return xmlOutput;
	}

    public static Boolean processAuthorizationResponse(String httpResponse, Opportunity theOpportunity, PaymentMethodModel thePaymentMethod) {
		try {
	   		Dom.Document doc = new Dom.Document();
    		doc.load(httpResponse);

			// First just get all of the response elements into strings.
            // If certain key items are missing (authResponse), will return right away with ERROR
            Dom.XMLNode cnpOnlineResponse = doc.getRootElement();

            // Note: Complete list of items possibly returned from Vantiv.  Not all are used.
            Dom.XMLNode authResponse = cnpOnlineResponse.getChildElement('authorizationResponse', VANTIV_NAMESPACE);
			if (authResponse == null) {
				throw new VantivUtilitiesException('no auth response from vantiv');
			}
			// authorizationResponse is present in good/bad credit cards.  If not present, return error.

			String cnpTxnId;
			Dom.XMLNode cnpTxnEl = authResponse.getChildElement('cnpTxnId', VANTIV_NAMESPACE);
			if (cnpTxnEl != null && cnpTxnEl.getText() != null) {
				cnpTxnId = cnpTxnEl.getText();
			}
			String orderId;
			Dom.XMLNode orderIdEl = authResponse.getChildElement('orderId', VANTIV_NAMESPACE);
			if (orderIdEl != null && orderIdEl.getText() != null) {
				orderId = orderIdEl.getText();
			}
			String response;
			Dom.XMLNode responseEl = authResponse.getChildElement('response', VANTIV_NAMESPACE);
			if (responseEl != null && responseEl.getText() != null) {
				response = responseEl.getText();
			}
			String postDate;
			Dom.XMLNode postDateEl = authResponse.getChildElement('postDate', VANTIV_NAMESPACE);
			if (postDateEl != null && postDateEl.getText() != null) {
				postDate = postDateEl.getText();
			}
			String message;
			Dom.XMLNode messageEl = authResponse.getChildElement('message', VANTIV_NAMESPACE);
			if (messageEl != null && messageEl.getText() != null) {
				message = messageEl.getText();
			}
			String authCode;
			Dom.XMLNode authCodeEl = authResponse.getChildElement('authCode', VANTIV_NAMESPACE);
			if (authCodeEl != null && authCodeEl.getText() != null) {
				authCode = authCodeEl.getText();
			}

	    	// XML Child element fraudResult (partially present in bad credit cards)
			Dom.XMLNode fraudResult = authResponse.getChildElement('fraudResult', VANTIV_NAMESPACE);
			if (fraudResult != null) {   // If this child isn't present, don't try to get its items
				String avsResult;
				Dom.XMLNode avsResultEl = fraudResult.getChildElement('avsResult', VANTIV_NAMESPACE);
				if (avsResultEl != null && avsResultEl.getText() != null) {
					avsResult = avsResultEl.getText();
				}
				String cardValidationResult;
				Dom.XMLNode cardValidationResultEl = fraudResult.getChildElement('cardValidationResult', VANTIV_NAMESPACE);
				if (cardValidationResultEl != null && cardValidationResultEl.getText() != null) {
					cardValidationResult = cardValidationResultEl.getText();
				}
			}

			Dom.XMLNode tokenResponse = authResponse.getChildElement('tokenResponse', VANTIV_NAMESPACE);

			String cnpToken;
			String tokenResponseCode;
			String tokenMessage;
			String bin;

			if (tokenResponse != null) { // If this child isn't present, don't try to get its items
				Dom.XMLNode cnpTokenEl = tokenResponse.getChildElement('cnpToken', VANTIV_NAMESPACE);
				if (cnpTokenEl != null && cnpTokenEl.getText() != null) {
					cnpToken = cnpTokenEl.getText();
				}
				Dom.XMLNode tokenResponseCodeEl = tokenResponse.getChildElement('tokenResponseCode', VANTIV_NAMESPACE);
				if (tokenResponseCodeEl != null && tokenResponseCodeEl.getText() != null) {
			 		tokenResponseCode = tokenResponseCodeEl.getText();
				}
				Dom.XMLNode tokenMessageEl = tokenResponse.getChildElement('tokenMessage', VANTIV_NAMESPACE);
				if (tokenMessageEl != null && tokenMessageEl.getText() != null) {
					tokenMessage = tokenMessageEl.getText();
				}
				Dom.XMLNode binEl = tokenResponse.getChildElement('bin', VANTIV_NAMESPACE);
				if (binEl != null && binEl.getText() != null) {
	    			bin = binEl.getText();
				}
			}

            // Second, these two items must be present on bad or good credit cards
			if (cnpTxnId == null) {
				throw new VantivUtilitiesException('no transaction id from vantiv');
			}
            if (response == null) {
				throw new VantivUtilitiesException('no response code from vantiv');
			}

			// If the card is authorized ('000'), update the Opportunity.
			if (response == '000') {
                theOpportunity.Auth_Transaction__c = cnpTxnId;
                String expirationString = getExpirationAbbreviation (thePaymentMethod.cardExpMonth, thePaymentMethod.cardExpYear);
				if(expirationString != null) { theOpportunity.Card_Expiration__c = expirationString; }
                theOpportunity.Card_Type__c = thePaymentMethod.cardType;
                if (bin != null) { theOpportunity.Credit_Card_Bin__c = bin; }
                theOpportunity.Worldpay_Token__c = cnpToken;
            }
			return (response == '000');
	   	} catch (VantivUtilitiesException e) {
			   throw new VantivUtilitiesException(e.getMessage());
		   }
		catch (Exception e) {
	   		throw new VantivUtilitiesException('uncaught exception processing vantiv response: ' + e.getMessage());
	   	}
	}

    public static void processCaptureResponse(String httpResponse, Payment__c thePayment) {
		try {
	   		Dom.Document doc = new Dom.Document();
    		doc.load(httpResponse);

			// First just get all of the response elements into strings.
            Dom.XMLNode cnpOnlineResponse = doc.getRootElement();

            // Note: Complete list of items possibly returned from Vantiv.  Not all of these are used.
            Dom.XMLNode captureResponse = cnpOnlineResponse.getChildElement('captureResponse', VANTIV_NAMESPACE);
			if (captureResponse == null) {
				throw new VantivUtilitiesException('no capture response from vantiv');
			}
			// captureResponse should always be present whether the charge is good or bad

			String cnpTxnId;
			Dom.XMLNode cnpTxnIdEl = captureResponse.getChildElement('cnpTxnId', VANTIV_NAMESPACE);
			if (cnpTxnIdEl != null && cnpTxnIdEl.getText() != null) {
				cnpTxnId = captureResponse.getChildElement('cnpTxnId', VANTIV_NAMESPACE).getText();
			}
			String response;
			Dom.XMLNode responseEl = captureResponse.getChildElement('response', VANTIV_NAMESPACE);
			if (responseEl != null && responseEl.getText() != null) {
				response = captureResponse.getChildElement('response', VANTIV_NAMESPACE).getText();
			}
			String postDate = '';
			Dom.XMLNode postDateEl = captureResponse.getChildElement('postDate', VANTIV_NAMESPACE);
			if (postDateEl != null && postDateEl.getText() != null) {
				postDate = captureResponse.getChildElement('postDate', VANTIV_NAMESPACE).getText();
			}
			String message;
			Dom.XMLNode messageEl = captureResponse.getChildElement('message', VANTIV_NAMESPACE);
			if (messageEl != null && messageEl.getText() != null) {
				message = captureResponse.getChildElement('message', VANTIV_NAMESPACE).getText();
			}

	    	// Second, these two items must be present on bad or good charges
			if (cnpTxnId == null) {
				throw new VantivUtilitiesException('no transaction id from vantiv');
			}
            if (response == null) {
				throw new VantivUtilitiesException('no response code from vantiv');
			}

			if (response == '000') { // charge was successful
				thePayment.Status__c = PaymentServices.APPROVED_STATUS;
				thePayment.Capture_Sale_Transaction__c = cnpTxnId;  // this is the capture's ID, not the auth one.
				thePayment.Worldpay_Token__c = thePayment.Opportunity__r.Worldpay_Token__c;
				thePayment.Post_Date__c = dateStringToDate(postDate);
            }
			else {
				thePayment.Status__c = PaymentServices.DECLINED_STATUS;
			}
			thePayment.Message__c = message;

	   	} catch (VantivUtilitiesException e) {
			   throw new VantivUtilitiesException(e.getMessage());
		   }
		catch (Exception e) {
	   		throw new VantivUtilitiesException('uncaught exception processing vantiv response: ' + e.getMessage());
	   	}
	}


  	public static void processSaleResponse(String httpResponse, Payment__c thePayment) {
		try {
	   		Dom.Document doc = new Dom.Document();
    		doc.load(httpResponse);

			// First just get all of the response elements into strings.
            Dom.XMLNode cnpOnlineResponse = doc.getRootElement();
            
			// Note: Complete list of items possibly returned from Vantiv.  Not all of these are used.
            Dom.XMLNode saleResponse = cnpOnlineResponse.getChildElement('saleResponse', VANTIV_NAMESPACE);
			if (saleResponse == null) {
				throw new VantivUtilitiesException('no sale response from vantiv');
			}

			String cnpTxnId;
			Dom.XMLNode cnpTxnIdEl = saleResponse.getChildElement('cnpTxnId', VANTIV_NAMESPACE);
			if (cnpTxnIdEl != null && cnpTxnIdEl.getText() != null) {
				cnpTxnId = cnpTxnIdEl.getText();
			}
			String response;
			Dom.XMLNode responseEl = saleResponse.getChildElement('response', VANTIV_NAMESPACE);
			if (responseEl != null && responseEl.getText() != null) {
				response = responseEl.getText();
			}
			String postDateStr = '';
			Dom.XMLNode postDateEl = saleResponse.getChildElement('postDate', VANTIV_NAMESPACE);
			if (postDateEl != null && postDateEl.getText() != null) {
				postDateStr = postDateEl.getText();
			}
			String message;
			Dom.XMLNode messageEl = saleResponse.getChildElement('message', VANTIV_NAMESPACE);
			if (messageEl != null && messageEl.getText() != null) {
				message = messageEl.getText();
			}
			String orderId;
			Dom.XMLNode orderIdEl = saleResponse.getChildElement('orderId', VANTIV_NAMESPACE);
			if (orderIdEl != null && orderIdEl.getText() != null) {
				orderId = orderIdEl.getText();
			}

			if (cnpTxnId == null) {
				throw new VantivUtilitiesException('no transaction id from vantiv');
			}
			if (response == null) {
				throw new VantivUtilitiesException('no response code from vantiv');
			}

			if (response == '000') { // charge was successful
				thePayment.Status__c = PaymentServices.APPROVED_STATUS;
				thePayment.Capture_Sale_Transaction__c = cnpTxnId;
				thePayment.Worldpay_Order_Id__c = orderId;
				thePayment.Post_Date__c = dateStringToDate(postDateStr);
			} else {
				thePayment.Status__c = PaymentServices.DECLINED_STATUS;
			}
			thePayment.Message__c = message;
	 	} catch (VantivUtilitiesException e) {
			throw new VantivUtilitiesException(e.getMessage());
		 } catch (Exception e) {
			throw new VantivUtilitiesException('uncaught exception processing vantiv response: ' + e.getMessage());
		}
	}

	public static Payment__c processRefundResponse(String httpResponse) {
	  	Payment__c responsePayment;
		try {
	   		Dom.Document doc = new Dom.Document();
    		doc.load(httpResponse);

			Dom.XMLNode cnpOnlineResponse = doc.getRootElement();
            Dom.XMLNode creditResponse = cnpOnlineResponse.getChildElement('creditResponse', VANTIV_NAMESPACE);
			if (creditResponse == null) { 
					throw new VantivUtilitiesException('no refund response from vantiv');
			}
			String cnpTxnId;
     		Dom.XMLNode cnpTxnIdEl = creditResponse.getChildElement('cnpTxnId', VANTIV_NAMESPACE);
			if (cnpTxnIdEl != null && cnpTxnIdEl.getText() != null) {
				cnpTxnId =  cnpTxnIdEl.getText();
			}
			if (cnpTxnId == null) {
				throw new VantivUtilitiesException('no transaction id from vantiv');
			}
    
      		String response;
			Dom.XMLNode responseEl = creditResponse.getChildElement('response', VANTIV_NAMESPACE);
			if (responseEl != null && responseEl.getText() != null) {
				response = responseEl.getText();
			}
			if (response == null) {
				throw new VantivUtilitiesException('no response code from vantiv');
			}

			String postDateStr = '';
			Dom.XMLNode postDateEl = creditResponse.getChildElement('postDate', VANTIV_NAMESPACE);
			if (postDateEl != null && postDateEl.getText() != null) {
				postDateStr = postDateEl.getText();
			}

			String message;
			Dom.XMLNode messageEl = creditResponse.getChildElement('message', VANTIV_NAMESPACE);
			if (messageEl != null && messageEl.getText() != null) {
				message = messageEl.getText();
			}
           
			if (response == '000') { // refund was successful
		        responsePayment = new Payment__c();
                responsePayment.Capture_Sale_Transaction__c = cnpTxnId;
				responsePayment.Post_Date__c = dateStringToDate(postDateStr);
				responsePayment.Status__c =  PaymentServices.REFUNDED_STATUS;
			} 
			
	   	} catch (VantivUtilitiesException e) {
			throw new VantivUtilitiesException(e.getMessage());
		} catch (Exception e) {
			throw new VantivUtilitiesException('uncaught exception processing vantiv refund response: ' + e.getMessage());
		}
		//returning payment object to performRefund method
		return responsePayment;
	}

    public static String getExpirationAbbreviation (String expMonth, String expYear) {
        if (expMonth == null || expMonth == '' || expYear == null || expYear == '') {
			return '';
		}
		return getTwoDigitMonth(expMonth) + getTwoDigitYear(expYear);
	}

	// For converting a date string from Vantiv (i.e. 2017-05-16) to a Date value.
	public static Date dateStringtoDate(String dateString) {
		if (dateString.length() == 10) {
			try {
				Integer theYear = Integer.valueof(dateString.substring(0,4));
				Integer theMonth = Integer.valueof(dateString.substring(5,7));
				Integer theDate = Integer.valueof(dateString.substring(8,10));
				Date dateType = Date.newInstance(theYear, theMonth, theDate);
				return dateType;
			} catch (Exception e) {
       			System.debug('Exception: ' + e);
			}
		}
		return null;
	}

    // The following three methods are needed to convert certain strings into the format required
    // by the Vantive XML string.

    public static String getTwoDigitMonth (String fullMonth) {
		Map<String, String> monthMap = new Map<String, String>();
		monthMap.put('January', '01');
		monthMap.put('February', '02');
		monthMap.put('March', '03');
		monthMap.put('April', '04');
		monthMap.put('May', '05');
		monthMap.put('June', '06');
		monthMap.put('July', '07');
		monthMap.put('August', '08');
		monthMap.put('September', '09');
		monthMap.put('October', '10');
		monthMap.put('November', '11');
		monthMap.put('December', '12');

		String twoDigitMonth = monthMap.get(fullMonth);
		if (fullMonth.length() == 2) { twoDigitMonth = fullMonth; }
		if (twoDigitMonth == null) { fullMonth = ''; }

		return twoDigitMonth;
	}

    public static String getTwoDigitYear (String fullYear) {

        if (fullYear.length() == 2) {
            return fullYear;
        } else if (fullYear.length() == 4) {
            return (fullYear.substring(2, 4));
        }
        return '';

	}

    public static String getCardTypeAbbreviation (String cardType) {

        if (cardType.length() == 2) {return cardType; }

        String cardTypeCode = '';
		if (cardType == 'Visa') {
			cardTypeCode = 'VI';
		} else if (cardType == 'Mastercard') {
			cardTypeCode = 'MC';
		} else if (cardType == 'American Express') {
			cardTypeCode = 'AX';
		} else if (cardType == 'Discover') {
			cardTypeCode = 'DI';
		}
		return cardTypeCode;
	}

	public class VantivUtilitiesException extends Exception {}

}