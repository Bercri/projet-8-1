@isTest
private class OpportunityServiceTest {

    @testSetup
    static void setup() {
        Account acc = new Account(Name = 'Opp Test Account');
        insert acc;
    }

    @isTest
    static void testCreateOpportunity() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        Opportunity opp = OpportunityService.createOpportunity(acc.Id, 'New Deal', 'Prospecting', Date.today().addDays(30), 10000);
        Test.stopTest();

        System.assertNotEquals(null, opp.Id);
        System.assertEquals(acc.Id, opp.AccountId);
        System.assertEquals('New Deal', opp.Name);
        System.assertEquals(10000, opp.Amount);
    }

    @isTest
    static void testUpdateOpportunity() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = OpportunityService.createOpportunity(acc.Id, 'Deal to Update', 'Prospecting', Date.today().addDays(30), 5000);
        
        Test.startTest();
        opp.StageName = 'Negotiation/Review';
        OpportunityService.updateOpportunity(opp);
        Test.stopTest();

        Opportunity retrievedOpp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Negotiation/Review', retrievedOpp.StageName);
    }

    @isTest
    static void testDeleteOpportunity() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = OpportunityService.createOpportunity(acc.Id, 'Deal to Delete', 'Closed Lost', Date.today(), 0);
        
        Test.startTest();
        OpportunityService.deleteOpportunity(opp.Id);
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(0, opps.size());
    }

    @isTest
    static void testGetOpportunitiesByAccount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        OpportunityService.createOpportunity(acc.Id, 'Deal 1', 'Prospecting', Date.today(), 1000);
        OpportunityService.createOpportunity(acc.Id, 'Deal 2', 'Analysis', Date.today(), 2000);
        
        Test.startTest();
        List<Opportunity> opps = OpportunityService.getOpportunitiesByAccount(acc.Id);
        Test.stopTest();

        System.assertEquals(2, opps.size());
    }
}
