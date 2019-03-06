global class DonationFormPaymentBatchScheduler implements Schedulable{
    global void execute(SchedulableContext sc){
        DonationFormPaymentBatch dfPaymentBatch = new DonationFormPaymentBatch();
        Id batchId = Database.executeBatch(dfPaymentBatch, 100);
    }
}