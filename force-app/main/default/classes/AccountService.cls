/**
 * @description Service class for Account management.
 * Handles business logic and delegates CRUD operations to DataManager.
 */
public with sharing class AccountService {

    /**
     * @description Creates a new Account.
     */
    public static Account createAccount(String name, String industry) {
        Account newAcc = new Account(Name = name, Industry = industry);
        DataManager.secureInsert(new List<Account>{newAcc});
        return newAcc; // Returns the account with ID populated
    }

    /**
     * @description Updates an existing Account.
     */
    public static void updateAccount(Account acc) {
        DataManager.secureUpdate(new List<Account>{acc});
    }

    /**
     * @description Deletes an Account.
     */
    public static void deleteAccount(Id accountId) {
        Account acc = [SELECT Id FROM Account WHERE Id = :accountId LIMIT 1];
        DataManager.secureDelete(new List<Account>{acc});
    }

    /**
     * @description Retrieves Accounts by Industry securely.
     */
    public static List<Account> getAccountsByIndustry(String industry) {
        String query = 'SELECT Id, Name, Industry, AnnualRevenue FROM Account WHERE Industry = \'' + String.escapeSingleQuotes(industry) + '\'';
        return (List<Account>) DataManager.secureQuery(query);
    }
}
