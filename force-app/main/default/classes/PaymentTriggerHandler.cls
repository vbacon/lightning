/**
* @author Adam Gallinat
* @date March 2018
*
* @description Trigger handler on Payment__c. Extends base TriggerHandler class
*/

public class PaymentTriggerHandler extends TriggerHandler {
    
    public override void afterUpdate() {
        List<Payment__c> filteredPayments = filterApprovedPayments((List<Payment__c>)Trigger.new, (Map<Id,Payment__c>)Trigger.oldMap);
        List<Payment__c> newPayments = getNewPayments(filteredPayments);
        insertNewPayments((List<Payment__c>)Trigger.new, newPayments);
        List<Payment__c> filteredUpdatedPayments = filterUpdatedPayments((List<Payment__c>)Trigger.new, (Map<Id,Payment__c>)Trigger.oldMap);
        List<Opportunity> opportunityUpdate = updateOpportunityProjectedEndDate(filteredUpdatedPayments);

    }

    /**
    * @description Given a list of payments, filter to include only those
    * where the status has changed to 'approved'
    * @return the list of filtered payments
    */
    @TestVisible
    private static List<Payment__c> filterApprovedPayments(List<Payment__c> newList, Map<Id,Payment__c> oldMap) {
        List<Payment__c> filteredPayments = new List<Payment__c>();
        Map<Id,Opportunity> opps = new Map<Id,Opportunity>(
            [SELECT Is_Monthly__c FROM Opportunity WHERE Id IN :Pluck.ids('Opportunity__c', newList)]
        );
        for (Payment__c aPayment : newList) {
            if ((aPayment.Status__c == PaymentServices.APPROVED_STATUS) && 
                    (aPayment.Status__c != oldMap.get(aPayment.Id).Status__c) &&
                    aPayment.Post_Date__c != null &&
                    opps.get(aPayment.Opportunity__c).Is_Monthly__c) {
                filteredPayments.add(aPayment);
            }
        }
        return filteredPayments;
    }

    /**
    * @description Given a list of payments, return a list of new payments
    * identical to the original list, with start dates one month into the future
    * @param payments The list of payments to "clone" into the future
    * @return The list of newly built payments
    */
    @TestVisible
    private static List<Payment__c> getNewPayments(List<Payment__c> payments) {
        List<Payment__c> newPayments = new List<Payment__c>();
        for (Payment__c aPayment : payments) {
            Payment__c aNewPayment = PaymentServices.scheduleNext(aPayment);
            newPayments.add(aNewPayment);
        }
        return newPayments;
    }

    /**
    * @description Insert a list of newly built payments, assigning any dml errors
    * to the corresponding original payment
    * @param oldPayments The payments to clone from the trigger context
    * @param newPayments The newly built payments
    */
    @TestVisible
    private static void insertNewPayments(List<Payment__c> oldPayments, List<Payment__c> newPayments) {
        try {
            insert newPayments;
        }
        catch (DMLException e) {
            for (Integer i = 0; i < e.getNumDml(); i++) {
                Payment__c failedPayment = oldPayments[e.getDmlIndex(i)];
                failedPayment.addError(e.getDmlMessage(i));
            }
        }
    }

    @TestVisible
    private static List<Payment__c> filterUpdatedPayments(List<Payment__c> newList, Map<Id,Payment__c> oldMap) {
        List<Payment__c> filteredPayments = new List<Payment__c>();
        Map<Id,Opportunity> opps = new Map<Id,Opportunity>(
            [SELECT Is_Monthly__c FROM Opportunity WHERE Id IN :Pluck.ids('Opportunity__c', newList)]
        );
        for (Payment__c aPayment : newList) {
            if (aPayment.Status__c == PaymentServices.APPROVED_STATUS && 
                    (aPayment.Status__c != oldMap.get(aPayment.Id).Status__c) &&
                    aPayment.Post_Date__c != null &&
                    opps.get(aPayment.Opportunity__c).Is_Monthly__c) {
                filteredPayments.add(aPayment);
            }
        }
        return filteredPayments;
    }

    @TestVisible
    private static List<Opportunity> updateOpportunityProjectedEndDate(List<Payment__c> newList) {
        Map<Id,Date> projectedEndDateMap = new Map<Id,Date>();
        List<Opportunity> opportunityUpdate = new List<Opportunity>();
        Set<Id> oppIds = new Set<Id>();
        for (Payment__c aPayment : newList) {
                oppIds.add(aPayment.Opportunity__c);
                Date postDate = aPayment.Post_Date__c;
                Date oneMonthLater = postDate.addMonths(1);
                Integer lastDayOfMonth = Date.daysInMonth(oneMonthLater.year(), oneMonthLater.month());
                Date projectedEndDate = Date.newInstance(oneMonthLater.year(), oneMonthLater.month(), lastDayOfMonth);
                if (projectedEndDateMap.containsKey(aPayment.Opportunity__c)) { // This opp is already in the map
                    if (projectedEndDate > projectedEndDateMap.get(aPayment.Opportunity__c)) {  // Use latest date for this opp
                        projectedEndDateMap.put(aPayment.Opportunity__c, projectedEndDate);  
                    } // else, latest date is already in map, do nothing
                } else {
                    projectedEndDateMap.put(aPayment.Opportunity__c, projectedEndDate);
                }
        }
        List<Opportunity> oppList = [SELECT Id, Projected_End_Date__c FROM Opportunity WHERE Id IN :oppIds];
        for (Opportunity anOpp : oppList) {
            if (projectedEndDateMap.containsKey(anOpp.Id)) {
                anOpp.Projected_End_Date__c = projectedEndDateMap.get(anOpp.Id);
                opportunityUpdate.add(anOpp);
            }
        }
        try {
            update opportunityUpdate;
        } catch (DMLException e) {
            for (Integer i = 0; i < e.getNumDml(); i++) {
                for (Integer j = 0; j < newList.size(); j ++) {
                    if (newList[j].Opportunity__c == e.getDmlId(i)) {
                        newList[j].addError(e.getDmlMessage(i));
                    }
                }    
            }
        }
        return opportunityUpdate;
    }
}