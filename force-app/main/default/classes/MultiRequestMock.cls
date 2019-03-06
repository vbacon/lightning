@isTest
public class MultiRequestMock implements HttpCalloutMock{
    Map<String,HttpCalloutMock> calloutMap = new Map<String,HttpCalloutMock>();
    
    public MultiRequestMock() {
        this(new Map<String,HttpCalloutMock>());
    }

    public MultiRequestMock(Map<String,HttpCalloutMock> customCalloutMap) {
        Map<String,NamedCredential> credsByDevname = new Map<String,NamedCredential>();
        this.calloutMap.put('callout:Usps', new UspsUtilitiesMock());
        this.calloutMap.put('callout:Vantiv', new VantivUtilitiesMock());
        if (credsByDevname.containsKey('Vantiv')) {
            this.calloutMap.put(credsByDevname.get('Vantiv').Endpoint, new VantivUtilitiesMock());
        }
        if (credsByDevname.containsKey('Usps')) {
            this.calloutMap.put(credsByDevname.get('Usps').Endpoint, new UspsUtilitiesMock());
        }
        for (String anEndpoint : customCalloutMap.keySet()) {
            this.calloutMap.put(anEndpoint, customCalloutMap.get(anEndpoint));
        }
    }
    public HttpResponse respond(HttpRequest req) {
        String endpoint = req.getEndpoint();
        return this.calloutMap.get(endpoint).respond(req);
    }
}
