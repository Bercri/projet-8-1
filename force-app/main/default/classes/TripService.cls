/**
 * La classe TripService contient la logique métier (le "cerveau") pour gèrer les Voyages.
 * C'est une bonne pratique de mettre le code ici plutôt que directement dans les triggers.
 * "with sharing" signifie que le code respecte les règles de partages de Salesforce (qui voit quoi).
 */
public with sharing class TripService {
    
    /**
     * @description Crée automatiquement des enregistrements de Voyage à partir des Opportunités gagnées.
     * Règle métier : GGT-02
     */
    public static void createTripsFromOpportunities(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldMap) {
        List<Trip__c> tripsToInsert = new List<Trip__c>();
        
        for (Opportunity opp : newOpportunities) {
            Opportunity oldOpp = oldMap != null ? oldMap.get(opp.Id) : null;
            
            // Crée un voyage uniquement au passage à l'étape 'Closed Won'
            if (opp.StageName == 'Closed Won' && (oldOpp == null || oldOpp.StageName != 'Closed Won')) {
                Trip__c newTrip = new Trip__c();
                
                newTrip.Name = opp.Name;
                newTrip.Status__c = 'A venir';
                newTrip.Destination__c = opp.Destination__c;
                newTrip.Start_Date__c = opp.Start_Date__c;
                newTrip.End_Date__c = opp.End_Date__c;
                newTrip.Number_of_Participants__c = opp.Number_of_Participants__c;
                newTrip.Total_Cost__c = opp.Amount;
                newTrip.Account__c = opp.AccountId;
                newTrip.Opportunity__c = opp.Id;
                newTrip.Opportunite__c = opp.Id;
                
                tripsToInsert.add(newTrip);
            }
        }
        
        if (!tripsToInsert.isEmpty()) {
            DataManager.secureInsert(tripsToInsert);
        }
    }

    /**
     * @description Met à jour les enregistrements de Voyage quand l'Opportunité associée (Closed Won) est modifiée.
     */
    public static void updateTripsFromOpportunities(List<Opportunity> updatedOpportunities, Map<Id, Opportunity> oldMap) {
        // 1. Identifier les opportunités "Closed Won" qui ont été modifiées sur des champs clés
        Set<Id> oppIdsToSync = new Set<Id>();
        for (Opportunity opp : updatedOpportunities) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            
            // On ne synchronise que si l'opportunité est TOUJOURS "Closed Won"
            if (opp.StageName == 'Closed Won' && oldOpp.StageName == 'Closed Won') {
                // Vérifier si un champ clé a changé
                if (opp.Amount != oldOpp.Amount || 
                    opp.Destination__c != oldOpp.Destination__c || 
                    opp.Start_Date__c != oldOpp.Start_Date__c || 
                    opp.End_Date__c != oldOpp.End_Date__c ||
                    opp.Number_of_Participants__c != oldOpp.Number_of_Participants__c) {
                    oppIdsToSync.add(opp.Id);
                }
            }
        }
        
        if (oppIdsToSync.isEmpty()) return;
        
        // 2. Récupérer les voyages associés à ces opportunités de manière sécurisée
        String oppIdsStr = '(\'';
        List<Id> oppIdsList = new List<Id>(oppIdsToSync);
        for(Integer i=0; i<oppIdsList.size(); i++) {
            oppIdsStr += String.escapeSingleQuotes(oppIdsList[i]);
            if(i < oppIdsList.size() - 1) oppIdsStr += '\',\'';
        }
        oppIdsStr += '\')';
        
        String query = 'SELECT Id, Total_Cost__c, Destination__c, Start_Date__c, End_Date__c, Number_of_Participants__c, Opportunity__c ' +
                       'FROM Trip__c WHERE Opportunity__c IN ' + oppIdsStr;
                       
        List<Trip__c> tripsToUpdate = (List<Trip__c>) DataManager.secureQuery(query);
        
        // 3. Mettre à jour les voyages avec les nouvelles valeurs de l'opportunité
        if (!tripsToUpdate.isEmpty()) {
            // Créer une map pour retrouver facilement l'Opportunité à partir du Voyage
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(updatedOpportunities);
            
            for (Trip__c trip : tripsToUpdate) {
                if (trip.Opportunity__c != null && oppMap.containsKey(trip.Opportunity__c)) {
                    Opportunity syncedOpp = oppMap.get(trip.Opportunity__c);
                    trip.Total_Cost__c = syncedOpp.Amount;
                    trip.Destination__c = syncedOpp.Destination__c;
                    trip.Start_Date__c = syncedOpp.Start_Date__c;
                    trip.End_Date__c = syncedOpp.End_Date__c;
                    trip.Number_of_Participants__c = syncedOpp.Number_of_Participants__c;
                }
            }
            
            // 4. Sauvegarder les modifications via le DataManager
            DataManager.secureUpdate(tripsToUpdate);
        }
    }
    
    /**
     * @description Valide les données des voyages (Dates, Montants, Participants).
     * Règle métier : GGT-03 (Dates) + Logique métier (Pas de montants négatifs)
     */
    public static void validateTripData(List<Trip__c> trips) {
        // On boucle sur chaque voyage à vérifier
        for (Trip__c trip : trips) {
            
            // 1. Validation des Dates
            if (trip.Start_Date__c != null && trip.End_Date__c != null) {
                if (trip.End_Date__c <= trip.Start_Date__c) {
                    trip.addError('La date de fin doit être postérieure à la date de début.');
                }
            }
            
            // 2. Validation des Montants (Ne doit pas être négatif)
            if (trip.Total_Cost__c != null && trip.Total_Cost__c < 0) {
                trip.addError('Le coût total ne peut pas être négatif.');
            }
            
    // 3. Validation des Participants (Ne doit pas être négatif)
            if (trip.Number_of_Participants__c != null && trip.Number_of_Participants__c < 0) {
                trip.addError('Le nombre de participants ne peut pas être négatif.');
            }
        }
    }

    /**
     * @description Updates a Trip.
     */
    public static void updateTrip(Trip__c trip) {
        DataManager.secureUpdate(new List<Trip__c>{trip});
    }

    /**
     * @description Deletes a Trip.
     */
    public static void deleteTrip(Id tripId) {
        Trip__c trip = [SELECT Id FROM Trip__c WHERE Id = :tripId LIMIT 1];
        DataManager.secureDelete(new List<Trip__c>{trip});
    }

    /**
     * @description Retrieves Trips securely.
     */
    public static List<Trip__c> getTrips() {
        String query = 'SELECT Id, Name, Status__c, Start_Date__c, End_Date__c, Destination__c FROM Trip__c LIMIT 100';
        return (List<Trip__c>) DataManager.secureQuery(query);
    }
}
