public class DonationFormController {

    @TestVisible
    static void standardizeBillingAddress(Contact theContact) {
        UspsUtilities.UspsRequest requestAddress = new UspsUtilities.UspsRequest();
        requestAddress.address = theContact.MailingStreet;
        requestAddress.city = theContact.MailingCity;
        requestAddress.state = theContact.MailingState;
        requestAddress.zip = theContact.MailingPostalCode;
        UspsUtilities.UspsResponse standardizedAddress = UspsUtilities.verifyAddress(requestAddress);
        theContact.Standardized_Street_1__c = standardizedAddress.address1;
        theContact.Standardized_Street_2__c = standardizedAddress.address2;
        theContact.Standardized_City__c = standardizedAddress.city;
        theContact.Standardized_State__c = standardizedAddress.state;
        theContact.Standardized_Postal_Code__c = standardizedAddress.zip;
        theContact.Standardized_Address_Message__c = standardizedAddress.returnText;
        if (theContact.Standardized_Address_Message__c != null) {
            if (theContact.Standardized_Street_1__c != null || theContact.Standardized_Street_2__c != null) {
                theContact.Address_Verification_Status__c = 'Partially Verified';
            }
            else {
                theContact.Address_Verification_Status__c = 'Unverified';
            }
        }
        else {
            theContact.Address_Verification_Status__c = 'Verified';
        }
    }

    @TestVisible
    static Opportunity buildOpportunity(Opportunity opty, Contact theContact, PaymentMethodModel paymentData) {
        //getting today's date
        DateTime now = DateTime.now();
        Date today = now.date();
        //converting datetime to string
        String closeDateString = now.format('MM/dd/yyyy');
        //combining contact name, mailing street and close date as opportunity name
        opty.Name = theContact.FirstName + ' ' + theContact.LastName + '-' + theContact.MailingStreet + '-' + closeDateString;
        opty.StageName = 'Closed Won';
        opty.CloseDate = today;
        opty.Payment_Method__c = paymentData.payType;
        //creates opportunity record
        return opty;
    }

    @TestVisible
    static void standardizeShippingAddress(Opportunity opty, Contact theContact, AddressModel shippingAddress) {
        if (shippingAddress != null && shippingAddress.useCustomShippingAddress) {
            opty.Use_Custom_Shipping_Address__c = true;
            UspsUtilities.UspsRequest requestAddress = new UspsUtilities.UspsRequest();
            requestAddress.address = shippingAddress.street;
            requestAddress.city = shippingAddress.city;
            requestAddress.state = shippingAddress.state;
            requestAddress.zip = shippingAddress.postalCode;
            UspsUtilities.UspsResponse standardizedAddress = UspsUtilities.verifyAddress(requestAddress);
            opty.Shipping_Street__c = shippingAddress.street;
            opty.Shipping_City__c = shippingAddress.city;
            opty.Shipping_State__c = shippingAddress.state;
            opty.Shipping_Postal_Code__c = shippingAddress.postalCode;
            opty.Standardized_Street_1__c = standardizedAddress.address1;
            opty.Standardized_Street_2__c = standardizedAddress.address2;
            opty.Standardized_City__c = standardizedAddress.city;
            opty.Standardized_State__c = standardizedAddress.state;
            opty.Standardized_Postal_Code__c = standardizedAddress.zip;
            opty.Standardized_Address_Message__c = standardizedAddress.returnText;
            if (opty.Standardized_Address_Message__c != null) {
                if (opty.Standardized_Street_1__c != null || opty.Standardized_Street_2__c != null) {
                    opty.Address_Verification_Status__c = 'Partially Verified';
                }
                else {
                    opty.Address_Verification_Status__c = 'Unverified';
                }
            }
            else {
                opty.Address_Verification_Status__c = 'Verified';
            }
        }
        else {
            opty.Use_Custom_Shipping_Address__c = false;
            opty.Shipping_Street__c = theContact.MailingStreet;
            opty.Shipping_City__c = theContact.MailingCity;
            opty.Shipping_State__c = theContact.MailingState;
            opty.Shipping_Postal_Code__c = theContact.MailingPostalCode;
            opty.Standardized_Street_1__c = theContact.Standardized_Street_1__c;
            opty.Standardized_Street_2__c = theContact.Standardized_Street_2__c;
            opty.Standardized_City__c = theContact.Standardized_City__c;
            opty.Standardized_State__c = theContact.Standardized_State__c;
            opty.Standardized_Postal_Code__c = theContact.Standardized_Postal_Code__c;
            opty.Standardized_Address_Message__c = theContact.Standardized_Address_Message__c;
            opty.Address_Verification_Status__c = theContact.Address_Verification_Status__c;
        }
    }

    @TestVisible
    static void setOpportunityMembershipValues(Opportunity opty) {
        Date minExpiryDate = opty.Is_Monthly__c ? opty.CloseDate.addMonths(1) : opty.CloseDate.addMonths(12);
        Decimal minimumForLeadership = opty.Is_Monthly__c ? MembershipUtilities.MINIMUM_SG_LEADERSHIP : MembershipUtilities.MINIMUM_OT_LEADERSHIP;

        opty.Projected_End_Date__c = Date.newInstance(minExpiryDate.year(), minExpiryDate.month(),
                                        Date.daysInMonth(minExpiryDate.year(), minExpiryDate.month()));
        opty.Membership_Active__c = Date.today() < opty.Projected_End_Date__c ? true : false;
        opty.Membership_Tier__c = opty.Initial_Payment_Amount__c >= minimumForLeadership ? MembershipUtilities.MEMBERSHIP_TIER_LEADERSHIP : MembershipUtilities.MEMBERSHIP_TIER_BASIC;
    }

    @TestVisible
    static OpportunityLineItem buildOpportunityProduct(Opportunity opty, Id productId) {
        Id pricebookId = [SELECT Pricebook2Id FROM Opportunity WHERE Id = :opty.Id].Pricebook2Id;
        PricebookEntry pbe = [SELECT Id, UnitPrice FROM PricebookEntry WHERE
                                Pricebook2Id = :pricebookId AND
                                Product2Id = :productId];
        OpportunityLineItem theOli = new OpportunityLineItem(OpportunityId = opty.Id);
        theOli.Product2Id = productId;
        theOli.UnitPrice = pbe.UnitPrice;
        theOli.Quantity = 1;
        return theOli;
    }

    @TestVisible
    static Payment__c buildPaymentRecord(Opportunity theOpportunity, PaymentMethodModel paymentData) {
        Payment__c newPayment = new Payment__c();
        newPayment.Amount__c = theOpportunity.Initial_Payment_Amount__c;
        newPayment.Card_Type__c = paymentData.cardType;
        newPayment.Opportunity__c = theOpportunity.Id;
        newPayment.Payment_Method__c = paymentData.payType;
        newPayment.Scheduled_Post_Date__c = Date.today();
        newPayment.Worldpay_Order_Id__c = paymentData.worldpayOrderId;
        newPayment.Status__c = PaymentServices.PENDING_STATUS;
        return newPayment;
    }

    @TestVisible
    private static void insertOrUpdateContact(Contact theContact) {
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;

        if (theContact.Id != null) {  // Update if definite duplicate was found, otherwise insert
            Database.SaveResult sr = Database.update(theContact, dml);
            if (!sr.isSuccess()) {
                throw new CustomDMLException(buildErrorMessageString(sr));
	       	}
        } else {  // Contact is either totally new, or a potential duplicate
            Database.SaveResult sr = Database.insert(theContact, dml);
            if (!sr.isSuccess()) {
                throw new CustomDMLException(buildErrorMessageString(sr));
	      	}
        }
    }

    private static String buildErrorMessageString (Database.SaveResult sr) {
        List<String> errorMessagePieces = new List<String>();
        for (Database.Error dbError : sr.getErrors()) {
            String errorMessage = 'Error: ' + dbError.getMessage();
            errorMessagePieces.add(errorMessage);
        }
        if (!errorMessagePieces.isEmpty()) {
            String concatenatedMessage = String.join(errorMessagePieces, '. ');
            return concatenatedMessage;
        } else {
            return 'No error message found.';
        }
    }

    @AuraEnabled
    public static String submitDonation(Contact contactData, Opportunity opportunityData, String paymentData, Id productId, String shippingAddressData) {
        Savepoint sp;
        String submitStatus = '';        
        try{
            PaymentMethodModel paymentMethod = (PaymentMethodModel)JSON.deserializeStrict(paymentData, PaymentMethodModel.class);
            AddressModel shippingAddress = (AddressModel)JSON.deserializeStrict(shippingAddressData, AddressModel.class);
            
            standardizeBillingAddress(contactData);
            Contact theContact = ContactMatch.getUniqueContact(contactData); // either returning new contact to insert, or existing contact to update
            Boolean isAuthorized = VantivUtilities.authorizeCard(theContact, opportunityData, paymentMethod);

            if (isAuthorized) {
                Opportunity theOpportunity = buildOpportunity(opportunityData, theContact, paymentMethod);
                standardizeShippingAddress(theOpportunity, theContact, shippingAddress);
                setOpportunityMembershipValues(theOpportunity);
                
                sp = Database.setSavepoint();
                insertOrUpdateContact(theContact);
                Contact requeriedContact = [Select AccountId from Contact where Id =: theContact.Id];
                theOpportunity.Contact__c = requeriedContact.Id;
                theOpportunity.AccountId = requeriedContact.AccountId;
                insert theOpportunity;

                if (productId != null) {
                    OpportunityLineItem oppProduct = buildOpportunityProduct(theOpportunity, productId);
                    insert oppProduct;
                }
                Payment__c thePayment = buildPaymentRecord(theOpportunity, paymentMethod);
                insert thePayment;
                //future:
                VantivUtilities.chargeCard(thePayment.Id);
            }
            if (isAuthorized) { 
                submitStatus = 'APPROVE'; 
            } else {
                submitStatus = 'DECLINE';    
            }
        } catch (Exception e) {
            ErrorLog.logError(e, 'DonationFormController', 'Donation Form Submission Error');
            if (sp != null)  {
                Database.rollback(sp);
            }
            submitStatus = 'ERROR';
        } finally {
            ErrorLog.commitErrors();
        }
        return submitStatus;
    }

    public class AddressModel {
        @TestVisible Boolean useCustomShippingAddress;
        @TestVisible String street;
        @TestVisible String street2;
        @TestVisible String city;
        @TestVisible String state;
        @TestVisible String postalCode;

        public AddressModel() {
            useCustomShippingAddress = false;
        }
    }

    class CustomDMLException extends Exception {}
}