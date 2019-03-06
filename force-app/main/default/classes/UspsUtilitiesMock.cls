@isTest
public class UspsUtilitiesMock implements HttpCalloutMock {
    public String address2 = 'ADDRESS LINE 2';
    public String city = 'SAN FRANCISCO';
    public String state = 'CA';
    public String zip5 = '94110';
    public String zip4 = '1426';
    public String returnText;

    public Integer statusCode = 200;
    
    public HttpResponse respond(HttpRequest req) {
	    XmlStreamWriter w = new XmlStreamWriter();
        w.writeStartDocument('UTF-8', '1.0');
            w.writeStartElement(null, 'AddressValidateResponse', null);
                w.writeStartElement(null, 'Address', null);
                w.writeAttribute(null, null, 'ID', '0');
                    w.writeStartElement(null, 'Address2', null);
                        w.writeCharacters(address2);
                    w.writeEndElement();
                    w.writeStartElement(null, 'City', null);
                        w.writeCharacters(city);
                    w.writeEndElement();
                    w.writeStartElement(null, 'State', null);
                        w.writeCharacters(state);
                    w.writeEndElement();
                    w.writeStartElement(null, 'Zip5', null);
                        w.writeCharacters(zip5);
                    w.writeEndElement();
                    w.writeStartElement(null, 'Zip4', null);
                        w.writeCharacters(zip4);
                    w.writeEndElement();
                    if (returnText != null) {
                        w.writeStartElement(null, 'ReturnText', null);
                            w.writeCharacters(returnText);
                        w.writeEndElement();
                    }
                w.writeEndElement();
            w.writeEndElement();
        w.writeEndDocument();
        HttpResponse res = new HttpResponse();
        res.setStatusCode(statusCode);
        res.setBody(w.getXmlString());
        return res;
    }
}
