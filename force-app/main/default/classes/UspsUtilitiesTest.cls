@isTest
public class UspsUtilitiesTest {
    
    static testMethod void testVerifyAddress_valid() {
        UspsUtilities.UspsRequest address = new UspsUtilities.UspsRequest();
        address.address = '123 Main St';
        address.city = 'San Francisco';
        address.state = 'CA';
        address.zip = '94110';
        UspsUtilitiesMock mock = new UspsUtilitiesMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            UspsUtilities.UspsResponse res = UspsUtilities.verifyAddress(address);
        Test.stopTest();
        System.assert(res.returnText == null, 'No return text is returned because the address was validated successfully');
        System.assertEquals(res.address2, mock.address2, 'Expect the response address to be parsed and returned');
        System.assertEquals(res.city, mock.city, 'Expect the response city to be parsed and returned');
        System.assertEquals(res.state, mock.state, 'Expect the response state to be parsed and returned');
        System.assertEquals(mock.zip5 + '-' + mock.zip4, res.zip, 'Expect the response zip to be parsed, concatenated and returned');
    }

    static testMethod void testVerifyAddress_badResponseCode() {
        UspsUtilities.UspsRequest address = new UspsUtilities.UspsRequest();
        address.address = '123 Main St';
        address.city = 'San Francisco';
        address.state = 'CA';
        address.zip = '94110';
        UspsUtilitiesMock mock = new UspsUtilitiesMock();
        mock.statusCode = 500;
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            UspsUtilities.UspsResponse res = UspsUtilities.verifyAddress(address);
        Test.stopTest();
        System.assert(res.returnText.contains(String.valueOf(mock.statusCode)), 'Return text indicates that status code was other than 200');
        System.assertEquals(res.address2, null, 'Expect the response address to be null');
        System.assertEquals(res.city, null, 'Expect the response city to be null');
        System.assertEquals(res.state, null, 'Expect the response state to be null');
        System.assertEquals(res.zip, null, 'Expect the response zip5 to be null');
    }

    static testMethod void testVerifyAddress_includesResponseText() {
        UspsUtilities.UspsRequest address = new UspsUtilities.UspsRequest();
        address.address = '123 Main St';
        address.city = 'San Francisco';
        address.state = 'CA';
        address.zip = '94110';
        UspsUtilitiesMock mock = new UspsUtilitiesMock();
        mock.returnText = 'Test text indicating missing information from address';
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            UspsUtilities.UspsResponse res = UspsUtilities.verifyAddress(address);
        Test.stopTest();
        System.assertEquals(res.returnText, mock.returnText, 'Expect the return text to be parsed and returned');
        System.assertEquals(res.address2, mock.address2, 'Expect the response address to be parsed and returned');
        System.assertEquals(res.city, mock.city, 'Expect the response city to be parsed and returned');
        System.assertEquals(res.state, mock.state, 'Expect the response state to be parsed and returned');
        System.assertEquals(mock.zip5 + '-' + mock.zip4, res.zip, 'Expect the response zip to be parsed, concatenated and returned');
    }

}
