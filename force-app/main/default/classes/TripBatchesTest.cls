/**
 * Classe de test pour les Batches (processus de fond).
 * On teste ici l'annulation automatique et la mise à jour des statuts.
 */
@IsTest
private class TripBatchesTest {
    
    @TestSetup
    static void setup() {
        // Création de l'utilisateur de test
        Profile p = [SELECT Id FROM Profile WHERE UserType = 'Standard' LIMIT 1]; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='ggttestuser' + DateTime.now().getTime() + '@testorg.com');
        insert u;
        
        // Attribution des droits
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'GlobalGroupTravel_Admin'];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
    }

    /**
     * Teste le Batch d'annulation (TripCancellationBatch).
     * Vérifie que les voyages peu remplis sont bien annulés à J-7.
     */
    @IsTest
    static void testTripCancellationBatch() {
        User u = [SELECT Id FROM User WHERE LastName='Testing' LIMIT 1];
        
        System.runAs(u) {
            // Cas 1 : Voyage à annuler (Départ dans 7 jours, < 10 participants)
            Trip__c trip = new Trip__c(
                Status__c = 'A venir',
                Start_Date__c = Date.today().addDays(7),
                End_Date__c = Date.today().addDays(14),
                Number_of_Participants__c = 5 // Moins que 10 -> Doit être annulé
            );
            insert trip;
            
            // Cas 2 : Voyage à garder (Départ dans 7 jours, mais assez de participants)
            Trip__c tripSafe = new Trip__c(
                Status__c = 'A venir',
                Start_Date__c = Date.today().addDays(7),
                End_Date__c = Date.today().addDays(14),
                Number_of_Participants__c = 15 // Assez de monde -> Ne pas annuler
            );
            insert tripSafe;
    
            // Exécution du Batch
            Test.startTest();
            Database.executeBatch(new TripCancellationBatch());
            Test.stopTest();
            
            // Vérifications
            Trip__c cancelled = [SELECT Status__c FROM Trip__c WHERE Id = :trip.Id];
            System.assertEquals('Annulé', cancelled.Status__c, 'Le voyage aurait dû être annulé');
            
            Trip__c safe = [SELECT Status__c FROM Trip__c WHERE Id = :tripSafe.Id];
            System.assertNotEquals('Annulé', safe.Status__c, 'Ce voyage ne devait PAS être annulé');
        }
    }
    
    /**
     * Teste le Batch de mise à jour des statuts (TripStatusUpdateBatch).
     */
    @IsTest
    static void testTripStatusUpdateBatch() {
         User u = [SELECT Id FROM User WHERE LastName='Testing' LIMIT 1];
        
         System.runAs(u) {
            Date today = Date.today();
            
            // Cas 1 : Voyage qui a commencé hier -> Doit passer "En cours"
            Trip__c tripOngoing = new Trip__c(
                Status__c = 'A venir', // Mauvais statut initial
                Start_Date__c = today.addDays(-1),
                End_Date__c = today.addDays(1)
            );
            
            // Cas 2 : Voyage fini hier -> Doit passer "Terminé"
            Trip__c tripDone = new Trip__c(
                Status__c = 'En cours', // Mauvais statut initial
                Start_Date__c = today.addDays(-5),
                End_Date__c = today.addDays(-1)
            );
            
            insert new List<Trip__c>{tripOngoing, tripDone};
            
            // Exécution du Batch
            Test.startTest();
            Database.executeBatch(new TripStatusUpdateBatch());
            Test.stopTest();
            
            // Vérifications
            Trip__c ongoing = [SELECT Status__c FROM Trip__c WHERE Id = :tripOngoing.Id];
            System.assertEquals('En cours', ongoing.Status__c);
            
            Trip__c done = [SELECT Status__c FROM Trip__c WHERE Id = :tripDone.Id];
            System.assertEquals('Terminé', done.Status__c);
         }
    }
    
    /**
     * Vérifie simplement que la planification (Schedule) fonctionne sans erreur.
     */
    @IsTest
    static void testSchedulable() {
        Test.startTest();
        // Expression Cron : Une façon textuelle de dire "Tous les jours à minuit"
        String cronExp = '0 0 0 15 3 ? 2099';
        System.schedule('Test Cancel Batch', cronExp, new TripCancellationBatch());
        System.schedule('Test Status Batch', cronExp, new TripStatusUpdateBatch());
        Test.stopTest();
        // Si on arrive ici sans erreur, c'est gagné.
    }
}
