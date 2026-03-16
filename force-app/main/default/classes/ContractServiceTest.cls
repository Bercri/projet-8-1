@isTest
private class ContractServiceTest {

    @testSetup
    static void setup() {
        Account acc = new Account(Name = 'Contract Test Account');
        insert acc;
    }

    @isTest
    static void testCreateContract() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        Contract c = ContractService.createContract(acc.Id, 'Draft', 12);
        Test.stopTest();

        System.assertNotEquals(null, c.Id);
        System.assertEquals(acc.Id, c.AccountId);
        System.assertEquals('Draft', c.Status);
        System.assertEquals(12, c.ContractTerm);
    }

    @isTest
    static void testUpdateContractStatus() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contract c = ContractService.createContract(acc.Id, 'Draft', 6);
        
        Test.startTest();
        ContractService.updateContractStatus(c.Id, 'Activated');
        Test.stopTest();

        Contract retrievedC = [SELECT Status FROM Contract WHERE Id = :c.Id];
        System.assertEquals('Activated', retrievedC.Status);
    }

    @isTest
    static void testGetContractsByAccount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        ContractService.createContract(acc.Id, 'Draft', 12);
        ContractService.createContract(acc.Id, 'Draft', 24);
        
        Test.startTest();
        List<Contract> contracts = ContractService.getContractsByAccount(acc.Id);
        Test.stopTest();

        System.assertEquals(2, contracts.size());
    }
}
