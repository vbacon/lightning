public class ProductTilesController {

    public static Integer getFiscalQuarter(Integer orgFiscalStartMonth, Integer currentMonth) {
        currentMonth = currentMonth - orgFiscalStartMonth;
        if (currentMonth < 0) currentMonth += 12;
        Decimal currentFiscalQuarter = Math.floor(currentMonth / 3) + 1; // quarters start at index 1
        return Integer.valueOf(currentFiscalQuarter);
    }

    public static List<Product_Schedule__c> getCurrentProductSchedules() {
        Organization fiscalYearDetails = [SELECT FiscalYearStartMonth, UsesStartDateAsFiscalYearName FROM Organization];
        Integer orgFiscalStartMonth = fiscalYearDetails.FiscalYearStartMonth;
        Integer currentMonth = Date.today().month();
        Integer currentQuarter = getFiscalQuarter(orgFiscalStartMonth, currentMonth);
        Integer currentYear;
        if (currentMonth >= orgFiscalStartMonth) {
            currentYear = fiscalYearDetails.UsesStartDateAsFiscalYearName ? Date.today().year() : Date.today().year() + 1;
        }
        else {
            currentYear = fiscalYearDetails.UsesStartDateAsFiscalYearName ? Date.today().year() + 1 : Date.today().year();
        }
        return [
            SELECT Product__c
            FROM Product_Schedule__c
            WHERE
                Quarter__c = :String.valueOf(currentQuarter) AND
                Fiscal_Year__c = :String.valueOf(currentYear)
        ];
    }

    @AuraEnabled
    public static Map<Boolean,List<Product2>> getQualifyingProducts() {
        List<Product_Schedule__c> schedules = getCurrentProductSchedules();
        Set<Id> scheduledProductIds = Pluck.ids('Product__c', schedules);
        
        String baseQuery = 'SELECT Id, Name, ACD_Name__c, Type__c, Sub_Type__c, Product_Specifications__c,'
                            +    ' Image_URL__c, Tagline__c, One_Time_Price__c, Sustainer_Price__c, Description__c,'
                            +    ' Available_to_Ship_Date__c, Estimated_Shipping_Time__c, Live_on_Web__c '
                            + 'FROM Product2 ' 
                            + 'WHERE Live_on_Web__c = true ';
        List<Product2> otProducts = Database.query(baseQuery + ' AND Id IN :scheduledProductIds AND One_Time_Price__c != null ORDER BY One_Time_Price__c DESC');
        otProducts.addAll((List<Product2>)Database.query(baseQuery + ' AND Id NOT IN :scheduledProductIds AND One_Time_Price__c != null ORDER BY One_Time_Price__c DESC'));
        List<Product2> sgProducts = Database.query(baseQuery + ' AND Id IN :scheduledProductIds AND Sustainer_Price__c != null ORDER BY Sustainer_Price__c DESC');
        sgProducts.addAll((List<Product2>)Database.query(baseQuery + ' AND Id NOT IN :scheduledProductIds AND Sustainer_Price__c != null ORDER BY Sustainer_Price__c DESC'));
        Map<Boolean,List<Product2>> returnMap = new Map<Boolean,List<Product2>>();
        returnMap.put(true, sgProducts);
        returnMap.put(false, otProducts);
        return returnMap;
    }
}