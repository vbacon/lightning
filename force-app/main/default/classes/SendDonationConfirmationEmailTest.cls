@IsTest
public class SendDonationConfirmationEmailTest {

    static testMethod void testSendConfirmationEmail() {
        Account theAccount = TestUtilities.createAccounts(1, true)[0];
        Account theVendor = TestUtilities.createVendors(1, true)[0];
        Date thisDay = Date.today();
        Contact theContact = TestUtilities.createContacts(1, true)[0];
        Opportunity theOpp = TestUtilities.createOpportunities(new List<Account>{theAccount}, 1, false)[0];
        theOpp.Contact__c = theContact.Id;
        insert theOpp;
        List<Product2> products = TestUtilities.createProducts(2, theVendor.Id, true);
        List<PricebookEntry> pbes = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId()];
        List<OpportunityLineItem> theOLIs = TestUtilities.createOLIs(pbes, theAccount.Id, theOpp.Id, true);

        Test.startTest();
            SendDonationConfirmationEmail email = new SendDonationConfirmationEmail(theOpp.Id);
            email.sendConfirmationEmail();
            System.assertEquals(Limits.getEmailInvocations(), 1, 'One email should have been sent.');
        Test.stopTest();
    }

    static testMethod void testBadEmailAddress() {
        Account theAccount = TestUtilities.createAccounts(1, true)[0];
        Account theVendor = TestUtilities.createVendors(1, true)[0];
        Date thisDay = Date.today();
        Contact theContact = TestUtilities.createContacts(1, false)[0];
        theContact.Email = '';
        insert theContact;
        Opportunity theOpp = TestUtilities.createOpportunities(new List<Account>{theAccount}, 1, false)[0];
        theOpp.Contact__c = theContact.Id;
        insert theOpp;
        List<Product2> products = TestUtilities.createProducts(2, theVendor.Id, true);
        List<PricebookEntry> pbes = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId()];
        List<OpportunityLineItem> theOLIs = TestUtilities.createOLIs(pbes, theAccount.Id, theOpp.Id, true);

        Test.startTest();
            SendDonationConfirmationEmail email = new SendDonationConfirmationEmail(theOpp.Id);
            email.sendConfirmationEmail();
            System.assertEquals(Limits.getEmailInvocations(), 0, 'No emails should have been sent.');
        Test.stopTest(); 
        System.assertEquals(1, [SELECT Id FROM Error_Log__c].size(), 'Expect an error log to be created');

    }

}
