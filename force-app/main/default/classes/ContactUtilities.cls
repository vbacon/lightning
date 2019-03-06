public with sharing class ContactUtilities {

    // Creates a map of the various member levels and strings that contains all of the benefits for that member level.
    public static Map<Member_Level__c, String> getMemberBenefitStrings() { 

        List <Member_Level__c> memberLevels = new List<Member_Level__c>([SELECT Name, Member_Level_Value__c 
                FROM Member_Level__c ORDER BY Member_Level_Value__c DESC]);

        List <Member_Benefit_Level__c> memberBenefitLevels = new List<Member_Benefit_Level__c>([SELECT Member_Benefit__c,
                Member_Level__c, Member_Level__r.Name, Member_Benefit__r.Name FROM Member_Benefit_Level__c ]);

        Map<Member_Level__c, String> memberLevelBenefits = new Map<Member_Level__c, String>();

        for (Member_Level__c memberLevel : memberLevels) {
            String benefitString = '';
            for (Member_Benefit_Level__c mbl : memberBenefitLevels) {
                if (memberLevel.Id == mbl.Member_Level__c) {
                    benefitString += mbl.Member_Benefit__r.Name + ', ';
                }
            }
            if (benefitString.contains(', ')) {
                benefitString = benefitString.substring(0, benefitString.length()-2);
            }        
            memberLevelBenefits.put(memberLevel, benefitString);
        }

        return memberLevelBenefits;
    }

    // This function mimics the four batch files that are used to calculate the annual donation values.
    // It is called upon updates to Opportunities that could result in the Contact's values changing.
    // There were too many possible Opportunity updates (i.e. refund, change in payment amount or Contact, 
    // deletion) to handle them individually.  Instead, this method recalcs all of the values from scratch.
    public static void recalcAnnualDonationValues(List<Opportunity> updatedOpps) {

        // Start by taking the updated Opportunities, getting the associated Contacts,
        // and then getting all of the Opportunities related to these Contacts.
        Set<Id> contactIds = new Set<Id>();
        for (Opportunity anOpp : updatedOpps) {
            if (anOpp.Contact__c != null) {
                contactIds.add(anOpp.Contact__c);
            }
        }

        Map<Id, Contact> relatedContacts = new Map<Id, Contact>([SELECT Id, Sum_One_Time_Last_Year_Donations__c, 
                Sum_Annualized_Sustaining_Donations__c, Sum_Inactive_Last_Year_Donations__c
                FROM Contact WHERE Id IN :contactIds]);

        // Need all of the Opportunities associated with all of the related Contacts
        List<Opportunity> relatedOpportunities = new List<Opportunity>([SELECT Id, Contact__c
            FROM Opportunity WHERE Contact__c IN :contactIds]);

        Set<Id> relatedOpportunityIds = new Set<Id>();
        Map<Id, Id> opportunityToContact = new Map<Id, Id>();
        for (Opportunity anOpp : relatedOpportunities) {
            opportunityToContact.put(anOpp.Id, anOpp.Contact__c);
            relatedOpportunityIds.add(anOpp.Id);
        }

        // Then we begin the recalculation process by first zeroing out all of the three fields 
        // that make up the annual donation amount, and then recalculating each of them.
        for (Contact c : relatedContacts.values()) {
            c.Sum_One_Time_Last_Year_Donations__c = null;
            c.Sum_Annualized_Sustaining_Donations__c = null;
            c.Sum_Inactive_Last_Year_Donations__c = null;
        }

        // ONE TIME DONATIONS (Payments associated with non-recurring Opportunities)
        String oneTimePaymentQuery = 'SELECT Id, Opportunity__c, Opportunity__r.Contact__c, Amount__c' 
                        		+ ' FROM Payment__c' 
                                + ' WHERE Opportunity__r.Is_Monthly__c = false'
                                + ' AND Status__c NOT IN (\'' + PaymentServices.CANCELLED_STATUS + '\''
                                + ' , \'' + PaymentServices.FAILED_STATUS + '\''
                                + ' , \'' + PaymentServices.PENDING_STATUS + '\''
                                + ' , \'' + PaymentServices.DECLINED_STATUS + '\')'
                                + ' AND Post_Date__c = LAST_N_DAYS:' + OpportunityServices.DAYS_TO_QUERY
                                + ' AND Opportunity__c IN :relatedOpportunityIds';
        List<Payment__c> oneTimePayments = Database.query(oneTimePaymentQuery);

        for (Payment__c paym: oneTimePayments) {
            relatedContacts.get(opportunityToContact.get(paym.Opportunity__c)).Sum_One_Time_Last_Year_Donations__c = 
                Utilities.add(relatedContacts.get(opportunityToContact.get(paym.Opportunity__c)).Sum_One_Time_Last_Year_Donations__c, 
                paym.Amount__c); 
        }

        // ACTIVE RECURRING DONATIONS (All active recurring Opportunities annualized to 12 months)
        // TO DO - In MER-730 two new fields will be generated to capture the amount of a one time donation
        // or the recurring payment amount.  The Initial_Payment_Amount__c field below should be changed to the 
        // field where the one time donation value will be stored.
        String activeRecurringOppsQuery = 'SELECT Id, Contact__c, Initial_Payment_Amount__c' 
                        		+ ' FROM Opportunity'
                                + ' WHERE Is_Monthly__c = true AND Membership_Active__c = true'
                                + ' AND Id IN :relatedOpportunityIds';
        List<Opportunity> activeRecurringOpps = Database.query(activeRecurringOppsQuery);
        
        for (Opportunity opp : activeRecurringOpps) {
            if (opp.Initial_Payment_Amount__c != null) {
                relatedContacts.get(opportunityToContact.get(opp.Id)).Sum_Annualized_Sustaining_Donations__c = 
                    Utilities.add(relatedContacts.get(opportunityToContact.get(opp.Id)).Sum_Annualized_Sustaining_Donations__c, 
                    opp.Initial_Payment_Amount__c * 12); 
            }
        }

        // INACTIVE RECURRING DONATIONS (Payments associated with inactive, recurring Oportunities made within the last 12 months)
        String inactiveRecurringPaymentsQuery = 'SELECT Id, Opportunity__c, Opportunity__r.Contact__c, Amount__c' 
                        		+ ' FROM Payment__c' 
                                + ' WHERE Opportunity__r.Is_Monthly__c = true AND Opportunity__r.Membership_Active__c = false'
                                + ' AND Status__c NOT IN (\'' + PaymentServices.CANCELLED_STATUS + '\''
                                + ' , \'' + PaymentServices.FAILED_STATUS + '\''
                                + ' , \'' + PaymentServices.PENDING_STATUS + '\''
                                + ' , \'' + PaymentServices.DECLINED_STATUS + '\')'
                                + ' AND Post_Date__c = LAST_N_DAYS:' + OpportunityServices.DAYS_TO_QUERY
                                + ' AND Opportunity__c IN :relatedOpportunityIds';
        List<Payment__c> inactiveRecurringPayments = Database.query(inactiveRecurringPaymentsQuery);
        
        for (Payment__c paym : inactiveRecurringPayments) {
            relatedContacts.get(opportunityToContact.get(paym.Opportunity__c)).Sum_Inactive_Last_Year_Donations__c = 
                Utilities.add(relatedContacts.get(opportunityToContact.get(paym.Opportunity__c)).Sum_Inactive_Last_Year_Donations__c, 
                paym.Amount__c); 
        }           

        try {
            update relatedContacts.values();
        } catch (DmlException ex) {
            ErrorLog.logError(ex, 'ContactUtilities', 'Error updating Contact values in recalcAnnualDonationValues.');
            ErrorLog.commitErrors();
            return;            
        }

    }    
}
