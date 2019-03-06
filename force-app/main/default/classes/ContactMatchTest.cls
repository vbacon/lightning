@IsTest
public class ContactMatchTest {

    // These tests expect at least one active Contact duplicate rule in the org!
    // static testMethod void test_getUniqueContact_duplicateExists() {
    //     Contact testContact = TestUtilities.createContacts(1, false)[0];
    //     testContact.Phone = '(123) 123-1231';
    //     testContact.MailingStreet = '2601 Mariposa St';
    //     testContact.MailingCity = 'San Francisco';
    //     testContact.MailingState = 'CA';
    //     testContact.MailingPostalCode = '94110';
    //     insert testContact;
    //     Contact dupeContact = testContact.clone(false, false, false, false);
    //     Test.startTest();
    //         Contact resultingContact = ContactMatch.getUniqueContact(dupeContact);
    //     Test.stopTest();

    //     System.assertEquals(testContact.Id, resultingContact.Id, 'Expect the Id of the original contact to be returned');
    // }

    // static testMethod void test_getUniqueContact_noDuplicate() {
    //     List<Contact> testContacts = TestUtilities.createContacts(2, false);
    //     testContacts[0].Phone = '(123) 123-1231';
    //     testContacts[0].MailingStreet = '2601 Mariposa St';
    //     testContacts[0].MailingCity = 'San Francisco';
    //     testContacts[0].MailingState = 'CA';
    //     testContacts[0].MailingPostalCode = '99999';

    //     testContacts[1].Phone = '(987) 987-9879';
    //     testContacts[1].MailingStreet = '123 Elm St';
    //     testContacts[1].MailingCity = 'Oakland';
    //     testContacts[1].MailingState = 'CA';
    //     testContacts[1].MailingPostalCode = '91111';
    //     insert testContacts[0];
    //     Contact dupeContact = testContacts[1];
    //     Test.startTest();
    //         Contact resultingContact = ContactMatch.getUniqueContact(dupeContact);
    //     Test.stopTest();

    //     System.assertEquals(null, resultingContact.Id, 'Expect the returned contact not to have an Id because it does not match any existing contacts');
    // }
}