public without sharing class ContactMatch {
    
    public static Contact getUniqueContact(Contact theContact) {
        Datacloud.MatchRecord highestMatchingContact = getHighestMatchRecord(theContact);
        if (highestMatchingContact == null) {
            System.debug('NO DUPLICATE EXISTS!');
        }
        else {
            System.debug('CONFIDENCE SCORE: ' + highestMatchingContact.getMatchConfidence());
            Decimal threshold = Contact_Match_Threshold__c.getInstance().Min_Threshold__c;
            if (threshold == null) threshold = 95;
            if (highestMatchingContact.getMatchConfidence() >= threshold) {  // Using duplicate contact, NOT creating a new one
                Id matchId = highestMatchingContact.getRecord().Id;
                theContact.Id = matchId;
            } else {  // A potential duplicate exists but the score is below the threshold.  New contact will be created.
                theContact.Possible_Duplicate__c = true;
            } 
        }
        return theContact;
    }

    private static Datacloud.MatchRecord getHighestMatchRecord(Contact theContact) {
        Datacloud.MatchRecord highestRecord;
        List<Datacloud.FindDuplicatesResult> findDuplicateResults = Datacloud.FindDuplicates.findDuplicates(new List<Contact>{theContact});
        List<Datacloud.DuplicateResult> duplicateResults = findDuplicateResults[0].duplicateresults;
        for (Datacloud.DuplicateResult dr : duplicateResults) {
            List<Datacloud.MatchResult> matchResults = dr.getMatchResults(); // unlikely to ever be more than 2 matchResults per duplicateResult
            if (matchResults != null && !matchResults.isEmpty()) {
                for (Datacloud.MatchResult mResult : matchResults) {
                    List<Datacloud.MatchRecord> matchRecords = mResult.getMatchRecords();
                    if (matchRecords != null && !matchRecords.isEmpty()) {
                        for (Datacloud.MatchRecord mRecord : matchRecords) {
                            if ((highestRecord == null || mRecord.getMatchConfidence() > highestRecord.getMatchConfidence()) && (mRecord.getRecord() instanceof Contact)) {
                                highestRecord = mRecord;
                            }
                        }
                    }
                }
            }
        }
        return highestRecord;
    }

}