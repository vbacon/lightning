@isTest
public with sharing class CalcAnnualPaymentInfoSchedulerTest {
    static testmethod void testScheduler() {
        String sch = '0 0 0 15 * ?';
        Test.startTest();
            CalcAnnualPaymentInfoScheduler obj = new CalcAnnualPaymentInfoScheduler();
            String jobId = System.schedule('Test status Check', sch, obj);
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(sch, ct.CronExpression);
        Test.stopTest();
    }
}
