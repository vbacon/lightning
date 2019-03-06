public class UspsUtilities {

    public static UspsResponse verifyAddress(UspsRequest requestAddress) {
        HttpRequest request;
        HttpResponse response;
        try {
            request = buildRequest(requestAddress);
            response = new Http().send(request);
            if (response.getStatusCode() == 200) {
                return formatResponse(response);
            }
            else {
                UspsResponse failResponse = new UspsResponse();
                failResponse.returnText = 'EXCEPTION: Status code of ' + response.getStatusCode() + ' returned';
                return failResponse; 
            }
        }
        catch (Exception e) {
            String customError = '';
            if (request != null) { customError += 'Request: ' + request.getBody() + '\n'; }
            if (response != null) { customError += 'Response: ' + response.getBody(); }
            ErrorLog.logError(e, 'UspsUtilities', customError);
            UspsResponse failResponse = new UspsResponse();
            failResponse.returnText = 'EXCEPTION: ' + e.getMessage();
            return failResponse;
        }
    }

    private static HttpRequest buildRequest(UspsRequest requestAddress) {
        XmlStreamWriter w = new XmlStreamWriter();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('callout:Usps');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String reqBody;
        // Unfortunately because of where the UserId is positioned in the request body,
        // a named credential merge field will not work (see MER-718)
        String username = '809KQED07446';
        try {
            w.writeStartElement(null, 'AddressValidateRequest', null);
            w.writeAttribute(null, null, 'USERID', username);
                w.writeStartElement(null, 'Address', null);
                w.writeAttribute(null, null, 'ID', '0');
                    w.writeEmptyElement(null, 'Address1', null);
                    w.writeStartElement(null, 'Address2', null);
                        w.writeCharacters(requestAddress.address);
                    w.writeEndElement();
                    w.writeStartElement(null, 'City', null);
                        if (requestAddress.city != null) {
                            w.writeCharacters(requestAddress.city);
                        }
                    w.writeEndElement();
                    w.writeStartElement(null, 'State', null);
                        if (requestAddress.state != null) {
                            w.writeCharacters(requestAddress.city);
                        }
                    w.writeEndElement();
                    w.writeStartElement(null, 'Zip5', null);
                        if (requestAddress.zip != null) {
                            w.writeCharacters(requestAddress.zip);
                        }
                    w.writeEndElement();
                    w.writeEmptyElement(null, 'Zip4', null);
                w.writeEndElement();
            w.writeEndElement();
            reqBody = w.getXmlString();
        }
        finally {
            w.close();
        }
        String payload = 'API=' + EncodingUtil.urlEncode('Verify', 'UTF-8') + '&XML=' + EncodingUtil.urlEncode(reqBody, 'UTF-8');
        req.setBody(payload);
        return req;
    }

    private static UspsResponse formatResponse(HttpResponse res) {
        UspsResponse resAddress = new UspsResponse();
        Dom.Document doc = new Dom.Document();
        doc.load(res.getBody());
        Dom.XMLNode uspsAddressResponse = doc.getRootElement();
        Dom.XMLNode address = uspsAddressResponse.getChildElement('Address', null);
        Dom.XMLNode xmlError = uspsAddressResponse.getChildElement('Error', null);
        DOM.XMLNode errorRes;
        if (address != null) {
            errorRes = address.getChildElement('Error', null);
        }
        if (xmlError != null) {
            resAddress.returnText = xmlError.getChildElement('Description', null).getText();
        }
        else if (errorRes != null) {
            resAddress.returnText = errorRes.getChildElement('Description', null).getText();
        }
        else if (address == null) {
            resAddress.returnText = 'Unable to process response: ' + res.getBody();
        }
        else {
            Dom.XMLNode address1 = address.getChildElement('Address1', null);
            if (address1 != null) {
                resAddress.address1 = address1.getText();
            }
            Dom.XMLNode address2 = address.getChildElement('Address2', null);
            if (address2 != null) {
                resAddress.address2 = address2.getText();
            }
            Dom.XMLNode city = address.getChildElement('City', null);
            if (city != null) {
                resAddress.city = city.getText();
            }
            Dom.XMLNode state = address.getChildElement('State', null);
            if (state != null) {
                resAddress.state = state.getText();
            }
            String zip5Text;
            String zip4Text;
            Dom.XMLNode zip5 = address.getChildElement('Zip5', null);
            if (zip5 != null) {
                zip5Text = zip5.getText();
            }
            Dom.XMLNode zip4 = address.getChildElement('Zip4', null);
            if (zip4 != null) {
                zip4Text = zip4.getText();
            }
            String concatenatedZip;
            if (zip5Text != null) {
                concatenatedZip = zip5Text;
                if (zip4Text != null && String.isNotBlank(zip4Text)) {
                    concatenatedZip += '-' + zip4Text;
                }
            }
            resAddress.zip = concatenatedZip;
            Dom.XMLNode returnText = address.getChildElement('ReturnText', null);
            if (returnText != null) {
                resAddress.returnText = returnText.getText();
            }
        }
        return resAddress;
    }

    public class UspsRequest {
        public String address;
        public String city;
        public String state;
        public String zip;
    }

    public class UspsResponse {
        public String address1;
        public String address2;
        public String city;
        public String state;
        public String zip;
        public String returnText;
    }

    public class UspsUtilitiesException extends Exception {}
    
}