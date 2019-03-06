public without sharing class PricebookServices {
    
    public static final String ONE_TIME = 'One Time';
    public static final String SUSTAINER = 'Sustainer';

    public static Map<String,String> pricebookToProductField = new Map<String,String>{
        'Standard Price Book' => 'One_Time_Price__c',
        ONE_TIME => 'One_Time_Price__c',
        SUSTAINER => 'Sustainer_Price__c'
    };

    public static Map<String,Id> pricebooksByName {
        get {
            if (pricebooksByName == null) {
                pricebooksByName = new Map<String,Id>();
                List<Pricebook2> pricebooks = [SELECT Id, Name FROM Pricebook2];
                for (Pricebook2 aPricebook : pricebooks) {
                    pricebooksByName.put(aPricebook.Name, aPricebook.Id);
                }
            }
            if (Test.isRunningTest()) {
                pricebooksByName.put('Standard Price Book', Test.getStandardPricebookId());
            }
            return pricebooksByName;
        }
        private set;
    }
}
