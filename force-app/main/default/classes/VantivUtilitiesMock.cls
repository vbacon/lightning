@isTest
public class VantivUtilitiesMock implements HttpCalloutMock {
    
    public static final String AUTH_TRANSACTION = '82922671406613738';
    public static final String CAPTURE_TRANSACTION = '82922671406613985';
    public static final String SALE_TRANSACTION_ID = '82922712172380936';
    public static final String CREDIT_TRANSACTION_ID = '82922712172354325';
    public static final String WORLDPAY_TOKEN = '1111000298021234';
    public static final String CREDIT_CARD_BIN = '400012';
    public static final String ORDER_ID = 'orVSVJmOn8xUD9iXtAqOjX4Ns';
    public static final String POST_DATE_STR = '2018-03-06';
    public static final Date POST_DATE = Date.newInstance(2018, 3, 6);
    
    public Integer statusCode = 200;
    public String vantivResponseCode = '000';
    public String message = 'Approved';
    
    public HttpResponse respond(HttpRequest req) {
	    HttpResponse res = new HttpResponse();
        String resBody;
        if (req.getBody().contains('authorization')) {
            resBody = getTestAuthorizationResponse();
        } else if (req.getBody().contains('capture')) {
            resBody = getTestCaptureResponse();
        }
        else if (req.getBody().contains('sale')) {
            resBody = getTestSaleResponse();
        }
        else if (req.getBody().contains('credit')) {
            resBody = getTestCreditResponse();
        }
        if (statusCode == 500) {
            resBody = getTestFailResponse();
        }
        res.setBody(resBody);
        res.setStatusCode(statusCode);
	    return res;
    }

    public String getTestAuthorizationResponse() {
    
        String returnString = '';

        returnString += '<cnpOnlineResponse version=\"12.1\" xmlns=\"' + VantivUtilities.VANTIV_NAMESPACE + '\" response=\"0\" message=\"Valid Format\">';
        returnString += '<authorizationResponse id=\"' + ORDER_ID + '\" reportGroup=\"rptGrp\">';
        returnString += '<cnpTxnId>' + AUTH_TRANSACTION + '</cnpTxnId>';
        returnString += '<orderId>' + ORDER_ID + '</orderId>';
        returnString += '<response>' + vantivResponseCode + '</response>';
        returnString += '<responseTime>2018-03-06T22:22:59</responseTime>';
        returnString += '<postDate>' + POST_DATE_STR + '</postDate>';
        returnString += '<message>' + message + '</message>';
        returnString += '<authCode>123457</authCode>';
        returnString += '<fraudResult>';
        returnString += '<avsResult>00</avsResult>';
        returnString += '<cardValidationResult>M</cardValidationResult>';
        returnString += '</fraudResult>';
        returnString += '<tokenResponse>';
        returnString += '<cnpToken>' + WORLDPAY_TOKEN + '</cnpToken>';
        returnString += '<tokenResponseCode>802</tokenResponseCode>';
        returnString += '<tokenMessage>Account number was previously registered</tokenMessage>';
        returnString += '<type>VI</type>';
        returnString += '<bin>' + CREDIT_CARD_BIN + '</bin>';
        returnString += '</tokenResponse>';
        returnString += '</authorizationResponse>';
        returnString += '</cnpOnlineResponse>';

        return returnString;
    }

    public String getTestCaptureResponse() {
    
        String returnString = '';

        returnString += '<cnpOnlineResponse version=\"12.1\" xmlns=\"' + VantivUtilities.VANTIV_NAMESPACE + '\">';
        returnString += 'response="0" message=\"Valid Format\">';
        returnString += '<captureResponse id=\"' + ORDER_ID + '\" reportGroup=\"rptGrp\" customerId=\"1333056\">';
        returnString += '<cnpTxnId>' + CAPTURE_TRANSACTION + '</cnpTxnId>';
        returnString += '<response>' + vantivResponseCode + '</response>';
        returnString += '<responseTime>2018-03-06T22:23:00</responseTime>';
        returnString += '<postDate>' + POST_DATE_STR + '</postDate>';
        returnString += '<message>' + message + '</message>';
        returnString += '</captureResponse>';
        returnString += '</cnpOnlineResponse>';

        return returnString;

    }    

    public String getTestSaleResponse() {
        String returnString = '';
        
        returnString += '<cnpOnlineResponse version=\"12.1\" xmlns=\"' + VantivUtilities.VANTIV_NAMESPACE + '\">';
        returnString += 'response="0" message=\"Valid Format\">';
        returnString += '<saleResponse id="123456" reportGroup="rptGrp">';
        returnString += '<cnpTxnId>'+ SALE_TRANSACTION_ID +'</cnpTxnId>';
        returnString += '<orderId>theOrderId</orderId>';
        returnString += '<response>' + vantivResponseCode + '</response>';
        returnString += '<responseTime>2018-03-12T16:36:27</responseTime>';
        returnString += '<postDate>' + POST_DATE_STR + '</postDate>';
        returnString += '<message>' + message + '</message>';
        returnString += '<authCode>11111</authCode>';
        returnString += '<fraudResult>';
        returnString += '<avsResult>20</avsResult>';
        returnString += '<cardValidationResult>M</cardValidationResult>';
        returnString += '</fraudResult>';
        returnString += '</saleResponse>';
        returnString += '</cnpOnlineResponse>';
        return returnString;
    }    

    public String getTestCreditResponse() {
        String returnString = '';
        
        returnString = '<cnpOnlineResponse version=\"12.1\" xmlns=\"' + VantivUtilities.VANTIV_NAMESPACE + '\">';
        returnString += 'response="0" message=\"Valid Format\">';
        returnString += '<creditResponse id="123456" reportGroup="rptGrp">';
        returnString += '<cnpTxnId>'+ CREDIT_TRANSACTION_ID +'</cnpTxnId>';
        returnString += '<response>' + vantivResponseCode + '</response>';
        returnString += '<responseTime>2018-03-12T16:36:27</responseTime>';
        returnString += '<postDate>' + POST_DATE_STR + '</postDate>';
        returnString += '<message>' + message + '</message>';
        returnString += '</creditResponse>';
        returnString += '</cnpOnlineResponse>';
        return returnString;
    } 

   
    public String getTestFailResponse() {
        String returnString = '';
            returnString = '<cnpOnlineResponse version=\"12.1\" xmlns=\"' + VantivUtilities.VANTIV_NAMESPACE + '\"' +
                            'response="1" message="System Error - Call Vantiv"/>';
        return returnString;
    }    
}