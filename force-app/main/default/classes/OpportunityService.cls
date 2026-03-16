/**
 * @description Service class for Opportunity management.
 */
public with sharing class OpportunityService {

    /**
     * @description Creates a new Opportunity.
     */
    public static Opportunity createOpportunity(Id accountId, String name, String stage, Date closeDate, Decimal amount) {
        Opportunity opp = new Opportunity(
            AccountId = accountId,
            Name = name,
            StageName = stage,
            CloseDate = closeDate,
            Amount = amount
        );
        DataManager.secureInsert(new List<Opportunity>{opp});
        return opp;
    }

    /**
     * @description Updates an Opportunity.
     */
    public static void updateOpportunity(Opportunity opp) {
        DataManager.secureUpdate(new List<Opportunity>{opp});
    }

    /**
     * @description Deletes an Opportunity.
     */
    public static void deleteOpportunity(Id oppId) {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :oppId LIMIT 1];
        DataManager.secureDelete(new List<Opportunity>{opp});
    }

    /**
     * @description Retrieves Opportunities for an Account.
     */
    public static List<Opportunity> getOpportunitiesByAccount(Id accountId) {
         String query = 'SELECT Id, Name, StageName, Amount, CloseDate FROM Opportunity WHERE AccountId = \'' + String.escapeSingleQuotes(accountId) + '\'';
         return (List<Opportunity>) DataManager.secureQuery(query);
    }
}
