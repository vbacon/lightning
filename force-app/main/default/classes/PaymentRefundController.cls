public class PaymentRefundController {

    @AuraEnabled
    public static Boolean checkPaymentChildRecord(Id originalPaymentId) {
        Boolean hasChildPaymentRec = false;

        try {
            Payment__c parentPayment = [SELECT Name, Status__c, (SELECT Name FROM Payments__r) 
                                        FROM Payment__c 
                                        WHERE Id =: originalPaymentId];
            List<Payment__c> childPaymentRecord = parentPayment.Payments__r;
            if (childPaymentRecord.size() > 0 || parentPayment.Status__c == PaymentServices.REFUNDED_STATUS) {
                hasChildPaymentRec = true;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return hasChildPaymentRec;
    }

    @AuraEnabled
    public static Payment__c refundDonation(Id originalPaymentID) {
        Payment__c refundPayment = new Payment__c();
        Payment__c refundedPayment;

        try {
            Payment__c theOriginalPayment = [SELECT Id,Amount__c,Opportunity__c,Opportunity__r.Id,
                                                Scheduled_Post_Date__c,Worldpay_Order_Id__c,
                                                Status__c,Capture_Sale_Transaction__c 
                                            FROM Payment__c 
                                            WHERE ID =: originalPaymentId];
            refundPayment = VantivUtilities.performRefund(theOriginalPayment);
           
            if (refundPayment != null) {
                refundPayment.Amount__c = (-1 * theOriginalPayment.Amount__c);
                refundPayment.Opportunity__c = theOriginalPayment.Opportunity__r.Id;
                refundedPayment = createRefundPaymentRecord(originalPaymentId, refundPayment);
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return refundedPayment;
    }

    @TestVisible
    static Payment__c createRefundPaymentRecord(Id originalPaymentId,Payment__c refundPaymentData) {
        if (originalPaymentId != null && refundPaymentData != null) {
            refundPaymentData.Original_Payment_Id__c = originalPaymentId;
            insert refundPaymentData;
        }       
        return refundPaymentData;
    }
}