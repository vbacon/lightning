@isTest
public class TestUtilities {

    public static Map<String, Id> productRecordTypes {
        get {
            if (productRecordTypes == null) {
                productRecordTypes = new Map<String,Id>();
                for (RecordType aRecordType : [SELECT Id, DeveloperName 
                                                FROM RecordType
                                                WHERE SObjectType = 'Product2' AND IsActive = true]) {
                    productRecordTypes.put(aRecordType.DeveloperName, aRecordType.Id);
                }
            }
            return productRecordTypes;
        }
        private set;
    }
    
    // To Create Accounts:
    // List<Account> myAccounts = TestUtilities.createAccounts();

    // To create Contacts:
    // List<Account> myAccounts = TestUtilities.createAccounts();
    // List<Contact> myContacts = TestUtilities.createContacts(myAccounts);


    // Create FIVE of each object and DO the Insert (creates a custom Pricebook, PB entries are linked to this)
    /////////////////////////////////////////////////
    // List<Account> myAccounts = TestUtilities.createAccounts();
    // List<Contact> myContacts = TestUtilities.createContacts(myAccounts);   // Optional
    // List<Campaign> myCampaigns = TestUtilities.createCampaigns();
    // List<Opportunity> myOpps = TestUtilities.createOpportunities(myAccounts, myCampaigns);
    // List<Product2> myProducts = TestUtilities.createProducts();
    // Pricebook2 myPricebook = TestUtilities.createPricebook();
    // List<PricebookEntry> myPricebookEntries = TestUtilities.createPricebookEntries(myProducts, Test.getStandardPricebookId(), false);
    // myPricebookEntries.addAll(TestUtilities.createPricebookEntries(myProducts, myPricebook.Id, false));
    // insert myPricebookEntries;
    // List<OpportunityLineItem> myOLIs = TestUtilities.createOpportunityLineItems(myOpps, myPricebookEntries);

    // Create FIVE of each object and DO the Insert (pricebook entries are linked to the standard pricebook)
    /////////////////////////////////////////////////
    // List<Account> myAccounts = TestUtilities.createAccounts();
    // List<Contact> myContacts = TestUtilities.createContacts(myAccounts);   // Optional
    // List<Campaign> myCampaigns = TestUtilities.createCampaigns();
    // List<Opportunity> myOpps = TestUtilities.createOpportunities(myAccounts, myCampaigns);
    // List<Product2> myProducts = TestUtilities.createProducts();
    // List<PricebookEntry> myPricebookEntries = TestUtilities.createPricebookEntries(myProducts, Test.getStandardPricebookId());
    // List<OpportunityLineItem> myOLIs = TestUtilities.createOpportunityLineItems(myOpps, myPricebookEntries);

    // Create X ('1') of each object and DO NOT do the Inserts (creates a custom Pricebook, PB entries are linked to this)
    /////////////////////////////////////////////////
    // List<Account> myAccounts = TestUtilities.createAccounts(1, false);
    // List<Contact> myContacts = TestUtilities.createContacts(myAccounts, 1, false);
    // List<Campaign> myCampaigns = TestUtilities.createCampaigns(1, false);
    // List<Opportunity> myOpps = TestUtilities.createOpportunities(myAccounts, myCampaigns, 1, false);
    // List<Product2> myProducts = TestUtilities.createProducts(1, false);
    // Pricebook2 myPricebook = TestUtilities.createPricebook();  // Always inserted
    // List<PricebookEntry> myPricebookEntries = TestUtilities.createPricebookEntries(myProducts, Test.getStandardPricebookId(), false);
    // myPricebookEntries.addAll(TestUtilities.createPricebookEntries(myProducts, myPricebook, false));
    // List<OpportunityLineItem> myOLIs = TestUtilities.createOpportunityLineItems(myOpps, myPricebookEntries, 1, false);

    // Create X ('1') of each object and DO NOT do the Inserts (pricebook entries are linked to the standard pricebook)
    /////////////////////////////////////////////////
    // List<Account> myAccounts = TestUtilities.createAccounts(1, false);
    // List<Contact> myContacts = TestUtilities.createContacts(myAccounts, 1, false);
    // List<Campaign> myCampaigns = TestUtilities.createCampaigns(1, false);
    // List<Opportunity> myOpps = TestUtilities.createOpportunities(myAccounts, myCampaigns, 1, false);
    // List<Product2> myProducts = TestUtilities.createProducts(1, false);
    // List<PricebookEntry> myPricebookEntries = TestUtilities.createPricebookEntries(myProducts, Test.getStandardPricebookId(), false);
    // List<OpportunityLineItem> myOLIs = TestUtilities.createOpportunityLineItems(myOpps, myPricebookEntries, 1, false);


    public static Integer defaultNumberToCreate = 5;

    public static List<Account> createAccounts() {
   		List<Account> theAccounts = createAccounts(defaultNumberToCreate, true);
   		return theAccounts;
    }
    public static List<Account> createAccounts(Integer numberToCreate, Boolean doTheInsert) {
        List<Account> theAccounts = new List<Account>();

        for (Integer i = 0; i < numberToCreate; i ++) {
        	Account a = new Account();
        	a.Name = 'Account' + i;
            a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household Account').getRecordTypeId();
			theAccounts.add(a);
        }

        if (doTheInsert) {
        	insert theAccounts;
        }
        return theAccounts;
    }

    public static List<Account> createVendors(Integer numberToCreate, Boolean doTheInsert) {
        List<Account> theAccounts = new List<Account>();

        for (Integer i = 0; i < numberToCreate; i ++) {
        	Account a = new Account();
        	a.Name = 'Account' + i;
            a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor Distributor').getRecordTypeId();
			theAccounts.add(a);
        }

        if (doTheInsert) {
        	insert theAccounts;
        }
        return theAccounts;
    }

    public static List<Contact> createContacts(Integer numberToCreate, Boolean doTheInsert) {
        List<Contact> theContacts = new List<Contact>();
        for (Integer i = 0; i < numberToCreate; i++) {
            Contact c = new Contact();
        	c.firstName = 'First' + i;
        	c.lastName = 'Last' + i;
        	c.email = 'test' + i + '@test.com';
        	theContacts.add(c);
        }

        if (doTheInsert) {
            insert theContacts;
        }
        return theContacts;
    }

    public static List<Contact> createContacts(List<Account> theAccounts) {
		List<Contact> theContacts = createContacts(theAccounts, 1, true);
		return theContacts;
    }

    public static List<Contact> createContacts(List<Account> theAccounts, Integer numberToCreate, Boolean doTheInsert) {
   	    List<Contact> theContacts = new List<Contact>();

        if (theAccounts == null) {
        	return null;
        }

        for (Account anAccount : theAccounts) {
            for (Integer i = 0; i < numberToCreate; i ++) {
                Contact c = new Contact();
                c.AccountId = anAccount.Id;
                c.firstName = 'First' + i;
                c.lastName = 'Last' + i;
                c.Phone = '8877878788';
                c.MailingStreet = 'Mariposa';
                c.MailingCity = 'San Francisco';
                c.MailingState = 'CA';
                c.MailingPostalCode = '90000';
                c.email = 'test' + i + '@test.com';
                theContacts.add(c);
            }
        }

        if (doTheInsert) {
        	insert theContacts;
        }
        return theContacts;
    }

    public static List<Campaign> createCampaigns() {
		List <Campaign> theCampaigns = createCampaigns(defaultNumberToCreate, true);
		return theCampaigns;
    }
    public static List<Campaign> createCampaigns(Integer numberToCreate, Boolean doTheInsert) {
		List <Campaign> theCampaigns = new List<Campaign>();

        for (Integer i = 0; i < numberToCreate; i ++) {
        	Campaign c = new Campaign();
        	c.Name = 'Campaign ' + i;
        	theCampaigns.add(c);
        }

        if (doTheInsert) {
    		insert theCampaigns;
        }
        return theCampaigns;
    }

    public static List<Product2> createProducts(Integer numberToCreate, Id accountId, Boolean doInsert) {
		List <Product2> theProducts = new List<Product2>();

		for (Integer i = 0; i < numberToCreate; i ++) {
        	Product2 p = new Product2();
        	p.Name = 'Product ' + i;
            p.ACD_Name__c = p.Name;
        	p.ProductCode = 'Product Code' + i;
        	//p.DefaultPrice = (50 + (i * 20));
        	p.IsActive = true;
        	p.Description = 'Product Description ' + i;
            p.Image_Url__c = 'http://www.placecage.com/200/200';
            p.Live_On_Web__c = true;
            p.Vendor__c = accountId;
            p.Distributor__c = accountId;
            p.One_Time_Price__c = 12;
            p.Sustainer_Price__c = 1;
        	theProducts.add(p);
        }

    	if (doInsert) {
    		insert theProducts;
    	}
		return theProducts;
    }

    public static Pricebook2 createPricebook(String name, Boolean doInsert) {
		Pricebook2 pb2 = new Pricebook2();
		pb2.IsActive = true;
		pb2.Name = name;
		if (doInsert)
            insert pb2;
		return pb2;
    }

    // Testing an implementation that requires multiple OpportunityLineItems for a given Opportunity was quite a pain to
    // implement.  Created the following method to allow one to create multiple Products/OLIs for a given Opportunity.
    // This is somewhat redundant from the createOpportunityLineItems method below but only requires an Opp Id.
    public static List<OpportunityLineItem> createOLIs(List<PricebookEntry> pbes, Id theAccountId, Id theOppId, Boolean doInsert) {
        List<OpportunityLineItem> theOLIs = new List<OpportunityLineItem> ();
        
        for (PricebookEntry aPbe : pbes) {
            OpportunityLineItem anOLI = new OpportunityLineItem(OpportunityId = theOppId, Product2Id = aPbe.Product2Id, 
                    Quantity = 1, PricebookEntryId = aPbe.Id, TotalPrice = 100);
            theOLIs.add(anOLI);
        }
        if (doInsert) {
            insert theOLIs;
        }
        return theOLIs;        
    }    

    // Takes standard or custom pricebook Id.  Creates one PB entry for each product for that pricebook
    public static List<PricebookEntry> createPricebookEntries(List<Product2> theProducts, Id pb2Id) {
   		List<PricebookEntry> thePricebookEntries = createPricebookEntries(theProducts, pb2Id, true);
   		return thePricebookEntries;
    }
    public static List<PricebookEntry> createPricebookEntries(List<Product2> theProducts, Id pb2Id, Boolean doTheInsert) {
   		List<PricebookEntry> thePricebookEntries = new List<PricebookEntry>();
        for (Product2 aProduct : theProducts) {
        	PricebookEntry pe = new PricebookEntry();
        	pe.UnitPrice = 100;
        	pe.IsActive = true;
        	pe.Pricebook2Id = pb2Id;
        	pe.Product2Id = aProduct.Id;
        	thePricebookEntries.add(pe);
        }

        if (doTheInsert) {
        	insert thePricebookEntries;
        }
        return thePricebookEntries;
    }

    public static List<Opportunity> createOpportunities(List<Account> theAccounts, List<Campaign> theCampaigns) {
   		List <Opportunity> theOpportunities = createOpportunities(theAccounts, theCampaigns, defaultNumberToCreate, true);
   		return theOpportunities;
    }
    public static List<Opportunity> createOpportunities(List<Account> theAccounts, Integer numToCreate, Boolean doInsert) {
        List<Opportunity> theOpportunities = new List<Opportunity>();

        for (Account anAccount : theAccounts) {
            for (Integer i = 0; i < numToCreate; i++) {
                Opportunity o = new Opportunity();
                o.AccountId = anAccount.Id;
                o.Initial_Payment_Amount__c = 50;
                o.StageName = 'Closed Won';
                o.CloseDate = Date.today();
                o.Name = 'Opportunity ' + i + anAccount.Id;
                o.Membership_Tier__c = 'Basic';
                o.Membership_Active__c = true;
                o.Projected_End_Date__c = Date.today().addMonths(1);
                theOpportunities.add(o);
            }
        }
        if (doInsert) {
            insert theOpportunities;
        }
        return theOpportunities;
    }
    public static List<Opportunity> createOpportunities(List<Contact> contacts, Integer numToCreate, Boolean doInsert) {
        List<Opportunity> theOpportunities = new List<Opportunity>();
        for (Contact aContact : contacts) {
            for (Integer i = 0; i < numToCreate; i++) {
                Opportunity o = new Opportunity();
                o.AccountId = aContact.AccountId;
                o.Contact__c = aContact.Id;
                o.Initial_Payment_Amount__c = 10;
                o.StageName = 'Closed Won';
                o.CloseDate = Date.today();
                o.Name = aContact.Id + ' : ' + i;
                o.Membership_Tier__c = 'Basic';
                o.Membership_Active__c = true;
                o.Projected_End_Date__c = Date.today().addMonths(1);
                o.Shipping_Street__c = i + ' Test Blvd';
                o.Shipping_City__c = 'San Francisco';
                o.Shipping_State__c = 'CA';
                o.Shipping_Postal_Code__c = '98765';
                theOpportunities.add(o);
            }
        }
        if (doInsert) {
            insert theOpportunities;
        }
        return theOpportunities;
    }
    public static List<Opportunity> createOpportunities(List<Account> theAccounts, List<Contact> theContacts, Integer numberToCreate, Boolean doInsert) {
        List<Opportunity> theOpportunities = new List<Opportunity>();

        if (theAccounts == null || theAccounts.size() < numberToCreate || theContacts == null || theContacts.size() < numberToCreate) {
        	return null;
        }
         for (Integer i = 0; i < numberToCreate; i ++) {
        	Opportunity o = new Opportunity();
        	o.Account = theAccounts[i];
        	o.Contact__c = theContacts[i].Id;
            o.Initial_Payment_Amount__c = 10;
            o.Worldpay_Token__c = '1111000268290009';
            o.Card_Expiration__c = '0918';
            o.StageName = 'Closed Won';
        	o.CloseDate = Date.today();
        	o.Name = 'Opportunity ' + i;
            o.Membership_Tier__c = 'Basic';
            o.Membership_Active__c = true;
            o.Projected_End_Date__c = Date.today().addMonths(1);
        	theOpportunities.add(o);
        }
        if (doInsert) {
            insert theOpportunities;
        }
        return theOpportunities;
    }
    public static List<Opportunity> createOpportunities(List<Account> theAccounts, List<Campaign> theCampaigns, Integer numberToCreate, Boolean doTheInsert) {
		List <Opportunity> theOpportunities = new List<Opportunity>();

        if (theAccounts == null || theAccounts.size() < numberToCreate || theCampaigns == null || theCampaigns.size() < numberToCreate) {
        	return null;
        }

        for (Integer i = 0; i < numberToCreate; i ++) {
        	Opportunity o = new Opportunity();
        	o.Account = theAccounts[i];
        	o.Campaign = theCampaigns[i];
        	o.StageName = 'Closed Won';
        	o.CloseDate = Date.today();
        	o.Name = 'Opportunity ' + i;
            o.Membership_Tier__c = 'Basic';
            o.Membership_Active__c = true;
            o.Projected_End_Date__c = Date.today().addMonths(1);
        	theOpportunities.add(o);
        }

    	if (doTheInsert) {
    		insert theOpportunities;
    	}
        return theOpportunities;
    }

    public static List<OpportunityLineItem> createOpportunityLineItems(List<Opportunity> theOpps, List<PricebookEntry> thePricebookEntries) {
    	List <OpportunityLineItem> theOLIs = createOpportunityLineItems(theOpps, thePricebookEntries, defaultNumberToCreate, true);
    	return theOLIs;
    }
    public static List<OpportunityLineItem> createOpportunityLineItems(List<Opportunity> theOpps, List<PricebookEntry> thePricebookEntries, Integer numberToCreate, Boolean doTheInsert) {
    	List <OpportunityLineItem> theOLIs = new List<OpportunityLineItem>();

    	if (theOpps == null || theOpps.size() < numberToCreate || thePricebookEntries == null || thePricebookEntries.size() < numberToCreate) {
        	return null;
        }

        for (Integer i = 0; i < numberToCreate; i ++) {
        	OpportunityLineItem oli = new OpportunityLineItem();
        	oli.OpportunityId = theOpps[i].Id;
        	oli.PricebookEntryId = thePricebookEntries[i].Id;
        	oli.Quantity = 1;
        	oli.TotalPrice = 50;
        	theOLIs.add(oli);
        }

    	if (doTheInsert) {
    		insert theOLIs;
    	}
        return theOLIs;
	}

    public static Payment__c createPayment(Opportunity anOpportunity, Boolean doInsert) {
        return createPayments(new List<Opportunity>{anOpportunity}, doInsert)[0];
    }

    public static List<Payment__c> createPayments(List<Opportunity> opps, Boolean doInsert) {
        List<Payment__c> payments = new List<Payment__c>();
        for (Integer i = 0; i < opps.size(); i++) {
            Payment__c testPayment = new Payment__c();
            testPayment.Opportunity__c = opps[i].Id;
            testPayment.Amount__c = 10;
            testPayment.Scheduled_Post_Date__c = Date.today();
            testPayment.Status__c = 'Pending';
            testPayment.Payment_Method__c = 'Credit Card';
            testPayment.Card_Type__c = 'Visa';
            testPayment.Worldpay_Order_Id__c = '1234asdfASDF' + i;
            testPayment.Worldpay_Token__c = opps[i].Worldpay_Token__c;
            payments.add(testPayment);
        }
        if (doInsert) {
            insert payments;
        }
        return payments;
    }

}