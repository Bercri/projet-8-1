@isTest
private class AccountServiceTest {

    @isTest
    static void testCreateAccount() {
        Test.startTest();
        Account acc = AccountService.createAccount('Test Account', 'Technology');
        Test.stopTest();

        System.assertNotEquals(null, acc.Id, 'Account Id should not be null');
        Account retrievedAcc = [SELECT Name, Industry FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Test Account', retrievedAcc.Name);
        System.assertEquals('Technology', retrievedAcc.Industry);
    }

    @isTest
    static void testUpdateAccount() {
        Account acc = AccountService.createAccount('Original Name', 'Energy');
        
        Test.startTest();
        acc.Name = 'Updated Name';
        AccountService.updateAccount(acc);
        Test.stopTest();

        Account retrievedAcc = [SELECT Name FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Updated Name', retrievedAcc.Name);
    }

    @isTest
    static void testDeleteAccount() {
        Account acc = AccountService.createAccount('To Delete', 'Education');
        
        Test.startTest();
        AccountService.deleteAccount(acc.Id);
        Test.stopTest();

        List<Account> accs = [SELECT Id FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, accs.size(), 'Account should be deleted');
    }

    @isTest
    static void testGetAccountsByIndustry() {
        AccountService.createAccount('Acc 1', 'Finance');
        AccountService.createAccount('Acc 2', 'Finance');
        AccountService.createAccount('Acc 3', 'Healthcare');

        Test.startTest();
        List<Account> financeAccs = AccountService.getAccountsByIndustry('Finance');
        Test.stopTest();

        System.assertEquals(2, financeAccs.size(), 'Should retrieve 2 Finance accounts');
    }
}
