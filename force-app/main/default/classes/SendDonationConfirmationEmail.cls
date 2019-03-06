public with sharing class SendDonationConfirmationEmail {

    private static Boolean isEmailDeliverable() {
        Email_Deliverable__mdt setting = [SELECT Send_Receipts__c FROM Email_Deliverable__mdt LIMIT 1];
        if (Test.isRunningTest()) {
            return true;
        }
        else if (setting == null) {
            return false;
        }
        else {
            return setting.Send_Receipts__c;
        }
    }
    
    List<OpportunityLineItem> theOLIs;
    Opportunity theOpp;
    String address1;
    String address2;
    String city;
    String state;
    String zip;

    public SendDonationConfirmationEmail(Id theOppId) {
        theOLIs = new List<OpportunityLineItem>([SELECT ID, Product2.Name, Product2.Image_URL__c, 
            Opportunity.Contact__r.FirstName,  Opportunity.Contact__r.LastName, Opportunity.Contact__r.Standardized_Street_1__c, Opportunity.Contact__r.Standardized_Street_2__c,
       	    Opportunity.Contact__r.Standardized_City__c, Opportunity.Contact__r.Standardized_State__c, Opportunity.Contact__r.Standardized_Postal_Code__c,
            Opportunity.Contact__r.Phone, Opportunity.Contact__r.Email, Opportunity.Is_Monthly__c, Opportunity.Initial_Payment_Amount__c,
            Opportunity.CloseDate
            FROM OpportunityLineItem WHERE OpportunityId = :theOppId]);

        theOpp = [SELECT ID, Contact__r.FirstName, Contact__r.LastName,
            Contact__r.Standardized_Street_1__c, Contact__r.Standardized_Street_2__c,
       	    Contact__r.Standardized_City__c, Contact__r.Standardized_State__c, Contact__r.Standardized_Postal_Code__c,
            Contact__r.MailingStreet, Contact__r.MailingCity, Contact__r.MailingState, Contact__r.MailingPostalCode,
            Contact__r.Phone, Contact__r.Email, Is_Monthly__c, Initial_Payment_Amount__c, CloseDate, Shipping_Street__c,
            Shipping_City__c, Shipping_State__c, Shipping_Postal_Code__c, Use_Custom_Shipping_Address__c
            FROM Opportunity WHERE Id = :theOppId];

        address1 = theOpp.Contact__r.Standardized_Street_1__c;
        address2 = String.isNotBlank(theOpp.Contact__r.Standardized_Street_2__c) ? theOpp.Contact__r.Standardized_Street_2__c :
            theOpp.Contact__r.MailingStreet;
        city = String.isNotBlank(theOpp.Contact__r.Standardized_City__c) ? theOpp.Contact__r.Standardized_City__c :
            theOpp.Contact__r.MailingCity;
        state = String.isNotBlank(theOpp.Contact__r.Standardized_State__c) ? theOpp.Contact__r.Standardized_State__c :
            theOpp.Contact__r.MailingState;
        zip = String.isNotBlank(theOpp.Contact__r.Standardized_Postal_Code__c) ? theOpp.Contact__r.Standardized_Postal_Code__c :
            theOpp.Contact__r.MailingPostalCode;
    }

    public void sendConfirmationEmail () {

        if (!isEmailDeliverable()) {
            return;
        }

        String htmlBody;
        String plainTextBody;

        htmlBody = buildHTMLEmail() ;
        plainTextBody = buildPlainTextEmail() ;
    
        Messaging.SingleEmailMessage theEmail = new Messaging.SingleEmailMessage();
        List <String> emailAddresses = new List<String> {
            theOpp.Contact__r.Email
        };

        theEmail.setToAddresses(emailAddresses);
        theEmail.setSubject('Your KQED Pledge');
        theEmail.setWhatId(theOpp.Id);

        theEmail.setPlainTextBody(plainTextBody);
        theEmail.setHtmlBody(htmlBody);

        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{theEmail});
        }
        catch (EmailException e) {
            ErrorLog.logError(e, 'SendDonationConfirmationEmail', 'Unable to send confirmation email to opportunity Id ' + theOpp.Id);
            ErrorLog.commitErrors();
        }
    }

    @TestVisible
    private String buildHTMLEmail() {
        String donorAddress = '';
        if (address1 != null) {
            donorAddress += address1 + '<br />';
        }
        if (address2 != null) {
            donorAddress += address2 + '<br />';
        }
        List<String> htmlStringPieces1 = new List<String>{

            '<html lang="en">',
            '<head>',
            '</head>',
            '<body>',
            '<table align="center" cellpadding="15" cellspacing="0" border="0" bgcolor="#ffffff" style="display:block; max-width:600px">',
            '<tbody>',
            '<tr>',
            '<td>',
            '<p style="margin:16px auto 32px"><a href="http://www.kqed.org/" target="_blank">',
            '<img src="http://a.s.kqed.net/img/pledge/hd-donation-confirmation.png" alt="KQED Donation Confirmation" style="max-width:100%"></a>',
            '</p>',
            '<p style="font:16px/24px Helvetica,Arial,san-serif; color:#666666">Dear ' + theOpp.Contact__r.FirstName + ',</p>',
            '<p style="font:16px/24px Helvetica,Arial,san-serif; color:#666666">Thank you for your support! ',
            'Your generosity helps KQED celebrate diversity, embrace innovation, value lifelong learning and partner with those who ',
                'share our passion for public service. We couldn\'t do that without you!</p>',
            '<p style="font:16px/24px Helvetica,Arial,san-serif; color:#666666">Please take a moment to review the information below ',
                'and ensure its accuracy:</p>',
            '<h3 style="font:bold 18px/27px Helvetica,Arial,san-serif">CONTACT INFORMATION: ',
            '<a href="https://ww2.kqed.org/support/membership/update-info-form/" style="color:#ff6600; text-decoration:none" target="_blank">',
            '<strong>Update Contact Information</strong></a></h3>',
            '<p style="font:16px/24px Helvetica,Arial,san-serif; color:#666666">',
            theOpp.Contact__r.FirstName + ' ' + theOpp.Contact__r.LastName + '<br />',
            donorAddress,
            city + ', ' + state + ' &nbsp;', 
            zip + '<br />',
            'Home Phone: ' + (theOpp.Contact__r.Phone == null ? '<none>' : theOpp.Contact__r.Phone) + '<br />',
            'Email: ' + theOpp.Contact__r.Email + '<br /></p>'
        };

        // Create the shipping address, say it's the same, or do nothing if no product is selected.
        List<String> htmlStringPieces2 = new List<String> { };

        List<String> htmlStringPieces2a  = new List<String> {
            '<p style="font:16px/24px Helvetica,Arial,san-serif; color:#666666"><b>Shipping address:</b><br />',
            theOpp.Shipping_Street__c + '<br />',
            theOpp.Shipping_City__c + ', ' + theOpp.Shipping_State__c + ' &nbsp;',
            theOpp.Shipping_Postal_Code__c + '<br /></p>'
        };

        List<String> htmlStringPieces2b  = new List<String> {
            '<p style="font:16px/24px Helvetica,Arial,san-serif; color:#666666">Shipping address is the same as the above address.</p>'
        };

        if (theOLIs.size() > 0) {
            if (theOpp.Use_Custom_Shipping_Address__c) {
                htmlStringPieces2 = htmlStringPieces2a;
            } else {
                htmlStringPieces2 = htmlStringPieces2b;
            }
        }

        String donationFrequency = theOpp.Is_Monthly__c ?  'Monthly' : 'One-Time Donation';

        List<String> htmlStringPieces3  = new List<String> {
            '<h3 style="font:bold 18px/27px Helvetica,Arial,san-serif">DONATION INFORMATION: </h3>',
            '<p style="font:16px/24px Helvetica,Arial,san-serif; color:#666666">Pledge Date: ' + theOpp.CloseDate + '<br />',
            'Payment Method: Credit Card - <a href="https://ww2.kqed.org/support/membership/update-your-credit-card-info/" ',
            'style="color:#ff6600; text-decoration:none" target="_blank">',
            '<strong>Update Payment Method</strong></a><br />',
            'Donation Frequency: ' + donationFrequency + '<br />',
            'Pledge Amount: ' + theOpp.Initial_Payment_Amount__c + '<br />',
            '</p>'
        };

        String productsString = '<h3 style="font:bold 18px/27px Helvetica,Arial,san-serif">GIFT INFORMATION: </h3>';
        if (theOLIs.size() != 0) {
            for (OpportunityLineItem theOLI : theOLIs) {
                productsString += '<p style="font:16px/24px Helvetica,Arial,san-serif; color:#666666">Gift Name: ' + theOLI.Product2.Name + '<br />';
                productsString += '<img src="' + theOLI.Product2.Image_URL__c + '" height="200px"></p>';
            }
        } else {
            productsString += '<p style="font:16px/24px Helvetica,Arial,san-serif; color:#666666">No gift selected.</p>';
        }

        List<String> htmlStringPieces4  = new List<String> {
            productsString,
            '<div class="divider" style="width:100%; margin:32px 0; border-bottom:1px solid #dddddd">',
            '<img src="14.3.361.1/themes/resources/clear1x1.gif" alt="" style="width:100%" border="1" width="275" height="1"></div>',
            '<h3 style="font:bold 18px/27px Helvetica,Arial,san-serif">QUESTIONS? <span style="font:16px/24px Helvetica,Arial,san-serif; color:#666666">',
            'Answers to frequently asked questions can be found via the links below.</span></h3>',
            '<p style="font:16px/24px Helvetica,Arial,san-serif"><a href="https://ww2.kqed.org/support/membership/faq/general-questions/" style="color:#ff6600; text-decoration:none" target="_blank"><strong>General',
            'Member Questions</strong></a> | <a href="https://ww2.kqed.org/support/membership/matching-gifts/" style="color:#ff6600; text-decoration:none" target="_blank">',
            '<strong>Matching Gifts</strong></a> | <a href="https://ww2.kqed.org/support/membership/faq/your-membership-and-member-card/" style="color:#ff6600; text-decoration:none" target="_blank">',
            '<strong>Member Days &amp; Member Card</strong></a> | <a href="https://ww2.kqed.org/support/membership/faq/guide_mailings/" style="color:#ff6600; text-decoration:none" target="_blank">',
            '<strong>On Q Program Guide</strong></a> | <a href="https://ww2.kqed.org/support/membership/kqed-passport-help/" style="color:#ff6600; text-decoration:none" target="_blank">',
            '<strong>Passport Access</strong></a> | <a href="https://ww2.kqed.org/support/membership/faq/payments/" style="color:#ff6600; text-decoration:none" target="_blank">',
            '<strong>Payments and Credit Card Updates</strong></a> | <a href="http://www.kqed.org/radio/listen/pledgefree/" style="color:#ff6600; text-decoration:none" target="_blank">',
            '<strong>Pledge-Free Stream</strong></a> | <a href="https://ww2.kqed.org/support/membership/faq/general-questions/#section2" style="color:#ff6600; text-decoration:none" target="_blank">',
            '<strong>Preferences &amp; Contact Info</strong></a> | <a href="https://ww2.kqed.org/support/membership/faq/thank-you-gifts/" style="color:#ff6600; text-decoration:none" target="_blank">',
            '<strong>Thank You Gifts</strong></a> | <a href="https://ww2.kqed.org/support/membership/faq/thank-you-gifts/#tickets" style="color:#ff6600; text-decoration:none" target="_blank">',
            '<strong>Tickets</strong></a></p><p style="font:16px/24px Helvetica,Arial,san-serif; color:#666666"></p>',
            '<h3 style="font:bold 18px/27px Helvetica,Arial,san-serif; display:inline">CONTACT US:',
            '</h3>',
            '<a href="https://ww2.kqed.org/support/membership/faq/memberservices/" style="color:#ff6600; text-decoration:none; font:16px/24px Helvetica,Arial,san-serif" target="_blank"><strong>Contact',
            'Member Services</strong></a> | <a href="https://ww2.kqed.org/about/contact/" style="color:#ff6600; text-decoration:none; font:16px/24px Helvetica,Arial,san-serif" target="_blank">',
            '<strong>Contact other KQED Departments</strong></a><p></p>',
            '<h3 style="font:bold 18px/27px Helvetica,Arial,san-serif">Thank you again for supporting KQED.</h3>',
            '<h3 style="font:bold 18px/27px Helvetica,Arial,san-serif">Sincerely,</h3>',
            '<h3 style="font:bold 18px/27px Helvetica,Arial,san-serif">Marianne Fu-Petroni<br />',
            'Executive Director, Membership<br />',
            '</h3>',
            '<p><a href="https://www.facebook.com/dialog/feed?app_id=112966235403758&link=https://www.kqed.org/donate/&picture=https://a.s.kqed.net/img/nav/og-support.png&name=I%20just%20made%20a%20donation%20to%20support%20KQED.&description=You%20can%20too%20at%20www.kqed.org%2Fdonate%20&redirect_uri=https://www.kqed.org/" target="_blank"><img src="https://a.s.kqed.net/img/pledge/facebook-support-share.gif"></a>',
            '</p>',
            '</td>',
            '</tr>',
            '</tbody>',
            '</table>',
            '</body>',
            '</html>'
        };

        String htmlStringFinal1 = String.join(htmlStringPieces1, '\n' );
        String htmlStringFinal2 = String.join(htmlStringPieces2, '\n' );
        String htmlStringFinal3 = String.join(htmlStringPieces3, '\n' );
        String htmlStringFinal4 = String.join(htmlStringPieces4, '\n' );

        String htmlStringFinal = htmlStringFinal1 + htmlStringFinal2 + htmlStringFinal3 + htmlStringFinal4;
        System.debug('htmlStringFinal = ' + htmlStringFinal);
        return htmlStringFinal;

    }

    @TestVisible
    private String buildPlainTextEmail() {
        String donorAddress = '';
        if (address1 != null) {
            donorAddress += address1 + '\n';
        }
        if (address2 != null) {
            donorAddress += address2;
        }

        List<String> plainStringPieces1 = new List<String>{

            'Dear ' + theOpp.Contact__r.FirstName + ',\n',
            'Thank you for your support!\n',
            'Your generosity helps KQED celebrate diversity, embrace innovation, value lifelong learning and partner with those who ',
                'share our passion for public service. We couldn\'t do that without you!\n',
            'Please take a moment to review the information below and ensure its accuracy:\n',

            'CONTACT INFORMATION: \n',

            theOpp.Contact__r.FirstName + ' ' + theOpp.Contact__r.LastName,
            donorAddress,
            city + ', ' + state + '  ', 
            zip,
            'Home Phone: ' + (theOpp.Contact__r.Phone == null ? '<none>' : theOpp.Contact__r.Phone),
            'Email: ' + theOpp.Contact__r.Email

        };

        List<String> plainStringPieces2 = new List<String>{ };

        List<String> plainStringPieces2a  = new List<String> {
            'Shipping address:',
            theOpp.Shipping_Street__c,
            theOpp.Shipping_City__c + ', ' + theOpp.Shipping_State__c + '  ' + theOpp.Shipping_Postal_Code__c + '\n'
        };

        List<String> plainStringPieces2b  = new List<String> {
            'Shipping address is the same as the above address.\n'
        };

        if (theOLIs.size() > 0) {
            if (theOpp.Use_Custom_Shipping_Address__c) {
                plainStringPieces2 = plainStringPieces2a;
            } else {
                plainStringPieces2 = plainStringPieces2b;
            }
        }

        String donationFrequency = theOpp.Is_Monthly__c ?  'Monthly' : 'One-Time Donation';

        List<String> plainStringPieces3  = new List<String> {
            'DONATION INFORMATION:\n',
            'Pledge Date: ' + theOpp.CloseDate,
            'Payment Method: Credit Card',
            'Donation Frequency: ' + donationFrequency,
            'Pledge Amount: ' + theOpp.Initial_Payment_Amount__c + '\n'
        };

        String productsString = 'GIFT INFORMATION: \n\n';
        if (theOLIs.size() != 0) {
            for (OpportunityLineItem theOLI : theOLIs) {
                productsString += 'Gift Name: ' + theOLI.Product2.Name + '\n';
            }
        } else {
            productsString += 'No Gift Selected\n';
        }

        List<String> plainStringPieces4  = new List<String> {
            productsString,
            'QUESTIONS? Answers to frequently asked questions can be found at the links below.\n',
            'General Member Questions - https://ww2.kqed.org/support/membership/faq/general-questions/',
            'Matching Gifts - https://ww2.kqed.org/support/membership/matching-gifts/',
            'Member Days & Member Card - https://ww2.kqed.org/support/membership/faq/your-membership-and-member-card',
            'On Q Program Guide - https://ww2.kqed.org/support/membership/faq/guide_mailings',
            'Passport Access - https://ww2.kqed.org/support/membership/kqed-passport-help/',
            'Payments and Credit Card Updates - https://ww2.kqed.org/support/membership/faq/payments/',
            'Pledge-Free Stream - http://www.kqed.org/radio/listen/pledgefree/',
            'Preferences & Contact Info - https://ww2.kqed.org/support/membership/faq/general-questions/#section2',
            'Thank You Gifts - https://ww2.kqed.org/support/membership/faq/thank-you-gifts/',
            'Tickets - https://ww2.kqed.org/support/membership/faq/thank-you-gifts/#tickets\n',

            'CONTACT US:\n',
            'Contact Member Services - https://ww2.kqed.org/support/membership/faq/memberservices/',
            'Contact other KQED Departments - https://ww2.kqed.org/about/contact/\n',
            'Thank you again for supporting KQED.\n',
            'Sincerely,\n',
            'Marianne Fu-Petroni',
            'Executive Director, Membership'
        };

        String plainStringFinal1 = String.join(plainStringPieces1, '\n' );
        String plainStringFinal2 = String.join(plainStringPieces2, '\n' );
        String plainStringFinal3 = String.join(plainStringPieces3, '\n' );
        String plainStringFinal4 = String.join(plainStringPieces4, '\n' );

        String plainStringFinal = plainStringFinal1 + '\n' + plainStringFinal2 + '\n' + plainStringFinal3 + '\n' + plainStringFinal4;

        System.debug('plainStringFinal = ' + plainStringFinal);
        return plainStringFinal;

    }
}