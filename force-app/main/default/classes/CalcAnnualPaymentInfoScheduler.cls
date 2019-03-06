global class CalcAnnualPaymentInfoScheduler implements Schedulable {
    global void execute(SchedulableContext SC){
        ZeroOutAnnualContactFieldsBatch theBatch = new ZeroOutAnnualContactFieldsBatch();
        database.executeBatch(theBatch);
    }
}

