/**
 * Batch pour annuler automatiquement les voyages.
 * Un Batch est un processus qui tourne en arrière-plan pour traiter beaucoup de données à la fois.
 * "Schedulable" signifie qu'on peut programmer ce batch pour qu'il se lance tout seul à une heure précise.
 */
public with sharing class TripCancellationBatch implements Database.Batchable<SObject>, Schedulable {
    
    /**
     * Méthode START : C'est ici qu'on définit QUELLES données on va traiter.
     */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // On récupère les Voyages qui commencent dans EXACTEMENT 7 jours (NEXT_N_DAYS:7 fait ça pour nous)
        // ET qui ont moins de 10 participants
        // ET qui ne sont pas déjà Annulés.
        return Database.getQueryLocator([
            SELECT Id, Status__c, Number_of_Participants__c 
            FROM Trip__c 
            WHERE Start_Date__c = NEXT_N_DAYS:7 
            AND Number_of_Participants__c < 10
            AND Status__c != 'Annulé'
        ]);
    }
    
    /**
     * Méthode EXECUTE : C'est ici qu'on traite les données récupérées par le start.
     * Salesforce découpe les données en petit paquets (scope) pour ne pas tout charger d'un coup.
     */
    public void execute(Database.BatchableContext BC, List<Trip__c> scope) {
        // On boucle sur chaque voyage du paquet
        for (Trip__c trip : scope) {
            // On change le statut à 'Annulé'
            trip.Status__c = 'Annulé';
        }
        
        // On sauvegarde les modifications de manière sécurisée
        DataManager.secureUpdate(scope);
    }
    
    /**
     * Méthode FINISH : S'exécute une fois que tout le traitement est terminé.
     * Utile pour envoyer un email de confirmation par exemple.
     */
    public void finish(Database.BatchableContext BC) {
        // Optionnel : Envoyer un email récapitulatif
    }
    
    /**
     * Méthode EXECUTE (Schedule) : C'est celle qui est appelée par le planificateur (l'horloge).
     * Elle lance simplement le batch.
     */
    public void execute(SchedulableContext SC) {
        Database.executeBatch(new TripCancellationBatch());
    }
}
