global class BatchOrderGeneratorScheduler implements Schedulable {
    global void execute(SchedulableContext SC){
        BatchOrderGenerator generator = new BatchOrderGenerator();
        generator.generateBatchOrders();
    }
}
