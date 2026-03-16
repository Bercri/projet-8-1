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
     * Teste la mise à jour automatique d'un Voyage quand l'Opportunité associée (Closed Won) est modifiée.
     */
    @IsTest
    static void testTripSyncFromOpportunityUpdate() {
        User u = [SELECT Id FROM User WHERE LastName='Testing' LIMIT 1];
        
        System.runAs(u) {
            // Setup : On crée un Compte et une Opportunité
            Account acc = TestDataFactory.createAccount('Test Acc Sync');
            Opportunity opp = TestDataFactory.createOpportunity('Test Opp Sync', acc.Id);
            
            // On la passe en "Closed Won" pour générer le voyage initial
            opp.StageName = 'Closed Won';
            update opp;
            
            // On vérifie que le voyage initial a le bon montant et la bonne destination (qui sont null/vides par défaut dans le Setup, mais disons 10000 et Paris)
            Trip__c initialTrip = [SELECT Id, Total_Cost__c, Destination__c FROM Trip__c WHERE Opportunity__c = :opp.Id LIMIT 1];
            System.assertEquals(10000, initialTrip.Total_Cost__c);
            System.assertEquals('Paris', initialTrip.Destination__c);
            
            // Exécution : on modifie l'Opportunité
            Test.startTest();
            opp.Amount = 25000;
            opp.Destination__c = 'Tokyo';
            update opp;
            Test.stopTest();
            
            // Vérification : le voyage doit avoir hérité des modifications
            Trip__c updatedTrip = [SELECT Id, Total_Cost__c, Destination__c FROM Trip__c WHERE Id = :initialTrip.Id LIMIT 1];
            System.assertEquals(25000, updatedTrip.Total_Cost__c, 'Le montant du voyage aurait dû être synchronisé.');
            System.assertEquals('Tokyo', updatedTrip.Destination__c, 'La destination du voyage aurait dû être synchronisée.');
        }
    }
    /**
     * Teste la validation des dates (Date de fin > Date de début).
     */
    @IsTest
    static void testDateValidation() {
        User u = [SELECT Id FROM User WHERE LastName='Testing' LIMIT 1];
        
        System.runAs(u) {
            // On crée un Compte et une Opportunité pour le lien Master-Detail
            Account acc = TestDataFactory.createAccount('Test Acc Invalid');
            Opportunity opp = TestDataFactory.createOpportunity('Test Opp Invalid', acc.Id);
            
            // On prépare un voyage invalide (Fin avant Début)
            Trip__c invalidTrip = new Trip__c(
                Start_Date__c = Date.today().addDays(10),
                End_Date__c = Date.today().addDays(5), // Erreur ici : Fin avant Début
                Opportunite__c = opp.Id,
                Opportunity__c = opp.Id
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

    @IsTest
    static void testUpdateTrip() {
        User u = [SELECT Id FROM User WHERE LastName='Testing' LIMIT 1];
        System.runAs(u) {
             Account acc = TestDataFactory.createAccount('Update Test Acc');
             Opportunity opp = TestDataFactory.createOpportunity('Update Test Opp', acc.Id);
             
             Trip__c trip = new Trip__c(
                 Name = 'Trip to Update',
                 Status__c = 'A venir',
                 Account__c = acc.Id,
                 Opportunity__c = opp.Id,
                 Opportunite__c = opp.Id
             );
             insert trip;

             Test.startTest();
             trip.Status__c = 'En cours';
             TripService.updateTrip(trip);
             Test.stopTest();

             Trip__c updatedTrip = [SELECT Status__c FROM Trip__c WHERE Id = :trip.Id];
             System.assertEquals('En cours', updatedTrip.Status__c);
        }
    }

    @IsTest
    static void testDeleteTrip() {
        User u = [SELECT Id FROM User WHERE LastName='Testing' LIMIT 1];
        System.runAs(u) {
             Account acc = TestDataFactory.createAccount('Delete Test Acc');
             Opportunity opp = TestDataFactory.createOpportunity('Delete Test Opp', acc.Id);
             
             Trip__c trip = new Trip__c(
                 Name = 'Trip to Delete',
                 Status__c = 'A venir',
                 Account__c = acc.Id,
                 Opportunity__c = opp.Id,
                 Opportunite__c = opp.Id
             );
             insert trip;

             Test.startTest();
             TripService.deleteTrip(trip.Id);
             Test.stopTest();

             List<Trip__c> trips = [SELECT Id FROM Trip__c WHERE Id = :trip.Id];
             System.assertEquals(0, trips.size());
        }
    }

    @IsTest
    static void testGetTrips() {
        User u = [SELECT Id FROM User WHERE LastName='Testing' LIMIT 1];
        System.runAs(u) {
             Account acc = TestDataFactory.createAccount('Get Test Acc');
             Opportunity opp = TestDataFactory.createOpportunity('Get Test Opp', acc.Id);
             
             Trip__c trip1 = new Trip__c(Name = 'Trip 1', Account__c=acc.Id, Opportunity__c=opp.Id, Opportunite__c=opp.Id);
             Trip__c trip2 = new Trip__c(Name = 'Trip 2', Account__c=acc.Id, Opportunity__c=opp.Id, Opportunite__c=opp.Id);
             insert new List<Trip__c>{trip1, trip2};

             Test.startTest();
             List<Trip__c> trips = TripService.getTrips();
             Test.stopTest();

             // We expect at least these 2, but there might be more from other tests (though tests are isolated data-wise usually, User Mode might see others if sharing rules allow, but @IsTest uses isolation by default).
             // Actually, @IsTest default is SeeAllData=false, so isolation is true.
             System.assertEquals(2, trips.size());
        }
    }
}
