/**
 * Batch planifiable permettant d'annuler les voyages de moins de 10 participants à J-7.
 */
public with sharing class TripCancellationBatch implements Database.Batchable<SObject>, Schedulable {
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Récupère les voyages dans 7 jours, moins de 10 participants, non annulés
        return Database.getQueryLocator([
            SELECT Id, Status__c, Number_of_Participants__c 
            FROM Trip__c 
            WHERE Start_Date__c = NEXT_N_DAYS:7 
            AND Number_of_Participants__c < 10
            AND Status__c != 'Annulé'
        ]);
    }
    
    public void execute(Database.BatchableContext BC, List<Trip__c> scope) {
        for (Trip__c trip : scope) {
            trip.Status__c = 'Annulé';
        }
        DataManager.secureUpdate(scope);
    }
    
    public void finish(Database.BatchableContext BC) {
    }
    
    public void execute(SchedulableContext SC) {
        Database.executeBatch(new TripCancellationBatch());
    }
}
