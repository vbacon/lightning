public class MembershipUtilities {
    // TO DO - These two lines should be removed in MER-756.
    public static final String MEMBERSHIP_TIER_BASIC = 'Basic';
    public static final String MEMBERSHIP_TIER_LEADERSHIP = 'Leadership';
    public static final String CONTACT_MEMBERSHIP_TIER_NONE = 'None';
    public static final String CONTACT_MEMBERSHIP_TIER_BASIC = 'Basic';
    public static final String CONTACT_MEMBERSHIP_TIER_LEADERSHIP = 'Leadership';
    public static final String ACCOUNT_MEMBERSHIP_TIER_NONE = 'None';
    public static final String ACCOUNT_MEMBERSHIP_TIER_BASIC = 'Basic';
    public static final String ACCOUNT_MEMBERSHIP_TIER_LEADERSHIP = 'Leadership';

    public static final Decimal MINIMUM_OT_LEADERSHIP = 150;
    public static final Decimal MINIMUM_SG_LEADERSHIP = 12.5;

    public static final String END_REASON_ONE_TIME_DEFAULT = 'End of Life';
    public static final String END_REASON_SUSTAINER_DEFAULT = 'Nonpayment';
    public static final String END_REASON_CANCELLED = 'Cancelled';

    public static Opportunity expireOpportunityMembership(Opportunity theOpp) {
        theOpp.Membership_Active__c = false;
        if (theOpp.End_Reason__c == null) {
            theOpp.End_Reason__c = theOpp.Is_Monthly__c ? END_REASON_SUSTAINER_DEFAULT : END_REASON_ONE_TIME_DEFAULT;
        }
        return theOpp;
    }

    public static Map<Id, String> getNewMembershipTiersByContact(Set <Id> contactIdsToRecalculate) {

        Map<Id, String> contactTiers = new Map<Id, String>();
        
        List<Opportunity> allRelatedOpportunities = new List<Opportunity>([SELECT Id, Membership_Tier__c, Contact__c
                FROM Opportunity WHERE Contact__c in :contactIdsToRecalculate AND Membership_Active__c = TRUE]);

        // Start by assuming all Contacts have no opportunities at all
        for (Id theContactId : contactIdsToRecalculate) {
            contactTiers.put(theContactId, MembershipUtilities.CONTACT_MEMBERSHIP_TIER_NONE);
        }

        Map<String,List<Opportunity>> relatedOppsByTier = GroupBy.strings('Membership_Tier__c', allRelatedOpportunities);
        if (relatedOppsByTier.containsKey(MembershipUtilities.CONTACT_MEMBERSHIP_TIER_BASIC)) {
            for (Opportunity anOpp : relatedOppsByTier.get(MembershipUtilities.MEMBERSHIP_TIER_BASIC)) {
                contactTiers.put(anOpp.Contact__c, MembershipUtilities.CONTACT_MEMBERSHIP_TIER_BASIC);
            }
        }
        if (relatedOppsByTier.containsKey(MembershipUtilities.CONTACT_MEMBERSHIP_TIER_LEADERSHIP)) {
            for (Opportunity anOpp : relatedOppsByTier.get(MembershipUtilities.MEMBERSHIP_TIER_LEADERSHIP)) {
                contactTiers.put(anOpp.Contact__c, MembershipUtilities.CONTACT_MEMBERSHIP_TIER_LEADERSHIP);
            }
        }

        return contactTiers;

    }
}