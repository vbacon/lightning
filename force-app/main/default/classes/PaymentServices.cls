public class PaymentServices {

    public static final String APPROVED_STATUS = 'Approved';
    public static final String PENDING_STATUS = 'Pending';
    public static final String DECLINED_STATUS = 'Declined';
    public static final String FAILED_STATUS = 'Failed';
    public static final String REFUNDED_STATUS = 'Refunded';
    public static final String CANCELLED_STATUS = 'Cancelled';
    
    @TestVisible
    static List<String> fieldsToMap = new List<String>{
        'Opportunity__c', 'Amount__c', 'Card_Type__C', 'Worldpay_Token__c', 'Payment_Method__c'
    };

    public static Payment__c scheduleNext(Payment__c thePayment) {
        Payment__c newPayment = new Payment__c();
        for (String aField : fieldsToMap) {
            newPayment.put(aField, thePayment.get(aField));
        }
        newPayment.Scheduled_Post_Date__c = thePayment.Scheduled_Post_Date__c.addMonths(1);
        newPayment.Status__c = PENDING_STATUS;
        return newPayment;
    }

}