/**
 * Batch pour mettre à jour automatiquement le Statut des voyages (A venir / En cours / Terminé).
 * Il se lance tous les jours pour vérifier les dates et ajuster le statut si besoin.
 */
public with sharing class TripStatusUpdateBatch implements Database.Batchable<SObject>, Schedulable {
    
    /**
     * Méthode START : Sélectionne tous les voyages qui ne sont PAS annulés.
     */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Status__c, Start_Date__c, End_Date__c 
            FROM Trip__c 
            WHERE Status__c != 'Annulé'
        ]);
    }
    
    /**
     * Méthode EXECUTE : Traite chaque paquet de voyages.
     */
    public void execute(Database.BatchableContext BC, List<Trip__c> scope) {
        List<Trip__c> tripsToUpdate = new List<Trip__c>();
        Date today = Date.today(); // La date du jour
        
        for (Trip__c trip : scope) {
            String newStatus = trip.Status__c;
            
            // On vérifie que les dates sont bien remplies
            if (trip.Start_Date__c != null && trip.End_Date__c != null) {
                
                // Si la date du jour est AVANT le début -> "A venir"
                if (today < trip.Start_Date__c) {
                    newStatus = 'A venir';
                } 
                // Si la date du jour est ENTRE le début et la fin (inclus) -> "En cours"
                else if (today >= trip.Start_Date__c && today <= trip.End_Date__c) {
                    newStatus = 'En cours';
                } 
                // Si la date du jour est APRES la fin -> "Terminé"
                else if (today > trip.End_Date__c) {
                    newStatus = 'Terminé';
                }
            }
            
            // Si le statut calculé est DIFFÉRENT du statut actuel, on le prépare pour la mise à jour.
            // Cela évite de faire des mises à jour inutiles si rien n'a changé.
            if (newStatus != trip.Status__c) {
                trip.Status__c = newStatus;
                tripsToUpdate.add(trip);
            }
        }
        
        // Si on a des voyages à mettre à jour, on sauvegarde.
        if (!tripsToUpdate.isEmpty()) {
            DataManager.secureUpdate(tripsToUpdate);
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        // Rien de spécial à faire à la fin
    }
    
    // Planification automatique
    public void execute(SchedulableContext SC) {
        Database.executeBatch(new TripStatusUpdateBatch());
    }
}
