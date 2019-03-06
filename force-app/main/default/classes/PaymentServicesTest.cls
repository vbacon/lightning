@IsTest
public class PaymentServicesTest {
    
    static testMethod void testScheduleNext() {
        List<Account> testAccount = TestUtilities.createAccounts(1, true);
        Opportunity testOpp = TestUtilities.createOpportunities(testAccount, 1, true)[0];
        Payment__c testPayment = TestUtilities.createPayment(testOpp, false);
        testPayment.Status__c = PaymentServices.APPROVED_STATUS;
        testPayment.Post_Date__c = Date.today();
        testPayment.Scheduled_Post_date__c = Date.today();
        insert testPayment;
        Test.startTest();
            Payment__c newPayment = PaymentServices.scheduleNext(testPayment);
        Test.stopTest();

        System.assertEquals(PaymentServices.PENDING_STATUS, newPayment.Status__c,
            'Expect the new payments status to be pending');
        System.assertEquals(Date.today().addMonths(1), newPayment.Scheduled_Post_Date__c,
            'Expect the new payments scheduled post date to be one month out');
        for (String aField : PaymentServices.fieldsToMap) {
            System.assertEquals(testPayment.get(aField), newPayment.get(aField),
                'Expect each specified field to be mapped from the old payment to the new: ' + aField);
        }
    }

}
