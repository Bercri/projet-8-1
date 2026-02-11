/**
 * Classe de test pour TripService.
 * En Salesforce, il faut écrire du code pour tester son propre code.
 * "@IsTest" indique que cette classe ne compte pas dans la limite de code et sert uniquement aux tests.
 */
@IsTest
private class TripServiceTest {

    /**
     * Méthode SETUP : S'exécute avant CHAQUE méthode de test.
     * Elle prépare les données de base (utilisateurs, configurations...).
     */
    @TestSetup
    static void setup() {
        // On crée un utilisateur Standard pour tester avec ses droits
        Profile p = [SELECT Id FROM Profile WHERE UserType = 'Standard' LIMIT 1]; 
        User u = TestDataFactory.createBaseUser(p);
        insert u;
        
        // On lui donne les permissions nécessaires pour agir sur les voyages
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'GlobalGroupTravel_Admin'];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
    }

    /**
     * Teste la création automatique d'un Voyage quand une Opportunité est gagnée.
     */
    @IsTest
    static void testTripCreationFromOpportunity() {
        // On récupère l'utilisateur créé dans le setup
        User u = [SELECT Id FROM User WHERE LastName='Testing' LIMIT 1];
        
        // "System.runAs(u)" permet d'exécuter le code COMME SI on était cet utilisateur.
        // C'est très important pour vérifier la sécurité.
        System.runAs(u) {
            // Setup : On crée un Compte et une Opportunité
            Account acc = TestDataFactory.createAccount('Test Acc');
            Opportunity opp = TestDataFactory.createOpportunity('Test Opp', acc.Id);
            
            // Exécution : On bascule l'opportunité en "Gagnée" (Closed Won)
            // Test.startTest() / stopTest() permettent de réinitialiser les limites de gouverneur.
            Test.startTest();
            opp.StageName = 'Closed Won';
            update opp;
            Test.stopTest();
            
            // Vérification (Asserts) : On s'assure que le voyage a bien été créé.
            Trip__c trip = [SELECT Id, Name, Destination__c, Status__c, Total_Cost__c FROM Trip__c WHERE Opportunity__c = :opp.Id LIMIT 1];
            
            // AssertNotEquals : On vérifie que le voyage n'est pas "null" (donc qu'il existe)
            System.assertNotEquals(null, trip, 'Le voyage aurait dû être créé');
            
            // AssertEquals : On vérifie que les valeurs correspondent à ce qu'on attend
            System.assertEquals('Paris', trip.Destination__c);
            System.assertEquals('A venir', trip.Status__c);
            System.assertEquals(10000, trip.Total_Cost__c);
            System.assertEquals('Test Opp', trip.Name);
        }
    }
    
    /**
     * Teste la validation des dates (Date de fin > Date de début).
     */
    @IsTest
    static void testDateValidation() {
        User u = [SELECT Id FROM User WHERE LastName='Testing' LIMIT 1];
        
        System.runAs(u) {
            // On prépare un voyage invalide (Fin avant Début)
            Trip__c invalidTrip = new Trip__c(
                Start_Date__c = Date.today().addDays(10),
                End_Date__c = Date.today().addDays(5) // Erreur ici : Fin avant Début
            );
            
            Test.startTest();
            try {
                // On essaie d'insérer le voyage invalide
                insert invalidTrip;
                
                // Si on arrive ici, c'est que l'insertion a réussi ALORS QU'ELLE AURAIT DÛ ÉCHOUER.
                // Donc on force un échec du test.
                System.assert(false, 'Une exception aurait dû être levée');
            } catch (DmlException e) {
                // On s'attend à tomber ici (catch).
                // On vérifie que le message d'erreur est bien celui qu'on a programmé.
                System.assert(e.getMessage().contains('La date de fin doit être postérieure'), 'Message d\'erreur inattendu: ' + e.getMessage());
            }
            Test.stopTest();
        }
    }
}
