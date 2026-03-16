/**
 * @description Service class for Contract management.
 * Handles creation, update, and retrieval of Contracts regarding Accounts and Opportunities.
 */
public with sharing class ContractService {

    /**
     * @description Creates a new Contract linked to an Account.
     */
    public static Contract createContract(Id accountId, String status, Integer contractTermMonths) {
        Contract newContract = new Contract(
            AccountId = accountId,
            Status = status,
            StartDate = Date.today(),
            ContractTerm = contractTermMonths
        );
        DataManager.secureInsert(new List<Contract>{newContract});
        return newContract;
    }

    /**
     * @description Updates a Contract status.
     */
    public static void updateContractStatus(Id contractId, String newStatus) {
        Contract c = [SELECT Id, Status FROM Contract WHERE Id = :contractId LIMIT 1];
        c.Status = newStatus;
        DataManager.secureUpdate(new List<Contract>{c});
    }

    /**
     * @description Retrieves Contracts for a specific Account.
     */
    public static List<Contract> getContractsByAccount(Id accountId) {
        String query = 'SELECT Id, ContractNumber, Status, StartDate, EndDate FROM Contract WHERE AccountId = \'' + String.escapeSingleQuotes(accountId) + '\'';
        return (List<Contract>) DataManager.secureQuery(query);
    }
}
