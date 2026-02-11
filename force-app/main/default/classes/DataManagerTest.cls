/**
 * Classe de test pour DataManager.
 * On vérifie ici que notre couche de sécurité fonctionne bien.
 */
@IsTest
private class DataManagerTest {
    
    /**
     * Teste l'insertion sécurisée (secureInsert).
     */
    @IsTest
    static void testSecureInsert() {
        // Préparation des données (un Compte)
        Account acc = new Account(Name = 'Test Account');
        List<Account> accounts = new List<Account>{acc};
        
        Test.startTest();
        // On demande l'insertion via notre manager sécurisé
        DataManager.secureInsert(accounts);
        Test.stopTest();
        
        // Vérification : Le compte doit exister en base
        List<Account> inserted = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        System.assertNotEquals(0, inserted.size(), 'Le compte aurait dû être inséré');
    }
    
    /**
     * Teste la mise à jour sécurisée (secureUpdate).
     */
    @IsTest
    static void testSecureUpdate() {
        // On crée d'abord un compte normalement
        Account acc = new Account(Name = 'Original Name');
        insert acc;
        
        // On modifie son nom en mémoire
        acc.Name = 'Updated Name';
        List<Account> accounts = new List<Account>{acc};
        
        Test.startTest();
        // On applique la mise à jour via le manager
        DataManager.secureUpdate(accounts);
        Test.stopTest();
        
        // Vérification : Le nom doit avoir changé en base
        Account refreshed = [SELECT Name FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Updated Name', refreshed.Name, 'Le nom du compte aurait dû être mis à jour');
    }
    
    /**
     * Teste la suppression sécurisée (secureDelete).
     */
    @IsTest
    static void testSecureDelete() {
        // On crée un compte
        Account acc = new Account(Name = 'To Delete');
        insert acc;
        List<Account> accounts = new List<Account>{acc};
        
        Test.startTest();
        // On demande sa suppression via le manager
        DataManager.secureDelete(accounts);
        Test.stopTest();
        
        // Vérification : Le compte ne doit plus exister
        List<Account> remaining = [SELECT Id FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, remaining.size(), 'Le compte aurait dû être supprimé');
    }
}
