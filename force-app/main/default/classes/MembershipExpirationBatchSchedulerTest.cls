@IsTest
public with sharing class MembershipExpirationBatchSchedulerTest {
    static testmethod void testScheduler() {
        String cronString = '0 0 0 15 * ?';
        MembershipExpirationBatchScheduler scheduler = new MembershipExpirationBatchScheduler();
        Test.startTest();
            String jobId = System.schedule('Test', cronString, scheduler);
        Test.stopTest();
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(cronString, ct.CronExpression);
    }
}
