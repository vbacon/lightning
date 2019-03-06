global class MembershipExpirationBatchScheduler implements Schedulable{
    global void execute(SchedulableContext sc) {
        MembershipExpirationBatch batch = new MembershipExpirationBatch();
        Database.executeBatch(batch);
    }
}