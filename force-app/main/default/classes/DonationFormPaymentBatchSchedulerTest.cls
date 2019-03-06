@IsTest
public with sharing class DonationFormPaymentBatchSchedulerTest {
    static testmethod void testScheduler() {
        String sch = '0 0 0 15 * ?';
        Test.startTest();
            DonationFormPaymentBatchScheduler obj = new DonationFormPaymentBatchScheduler();
            String jobId = System.schedule('Test status Check', sch, obj);
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(sch, ct.CronExpression);
        Test.stopTest();
    }
}
