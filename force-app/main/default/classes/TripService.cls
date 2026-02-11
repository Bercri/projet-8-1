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
        // On prépare une liste vide pour stocker les nouveaux voyages qu'on va créer.
        List<Trip__c> tripsToInsert = new List<Trip__c>();
        
        // On boucle sur chaque opportunité reçue (celle qui vient d'être modifiée/créée)
        for (Opportunity opp : newOpportunities) {
            // On récupère l'ancienne version de cette opportunité (si elle existe)
            Opportunity oldOpp = oldMap != null ? oldMap.get(opp.Id) : null;
            
            // On vérifie deux conditions :
            // 1. La nouvelle étape est 'Closed Won' (Gagnée)
            // 2. L'ancienne étape (si elle existe) N'ÉTAIT PAS 'Closed Won'
            // Cela permet de n'exécuter ce code QUE lorsque l'opportunité PASSE à 'Closed Won'.
            if (opp.StageName == 'Closed Won' && (oldOpp == null || oldOpp.StageName != 'Closed Won')) {
                
                // On crée un nouvel objet Voyage (Trip__c) en mémoire
                Trip__c newTrip = new Trip__c();
                
                // On recopie les informations de l'Opportunité vers le Voyage
                newTrip.Name = opp.Name; // Le nom du voyage sera le nom de l'opportunité
                newTrip.Status__c = 'A venir'; // Statut par défaut demandé par le client
                newTrip.Destination__c = opp.Destination__c;
                newTrip.Start_Date__c = opp.Start_Date__c;
                newTrip.End_Date__c = opp.End_Date__c;
                newTrip.Number_of_Participants__c = opp.Number_of_Participants__c;
                newTrip.Total_Cost__c = opp.Amount; // Le montant de l'opportunité devient le coût total
                newTrip.Account__c = opp.AccountId; // On lie le voyage au même compte client
                newTrip.Opportunity__c = opp.Id;    // On garde un lien vers l'opportunité d'origine
                
                // On ajoute ce nouveau voyage à notre liste (on ne l'insère pas encore en base)
                tripsToInsert.add(newTrip);
            }
        }
        
        // Si on a créé au moins un voyage dans la liste...
        if (!tripsToInsert.isEmpty()) {
            // ... on demande au DataManager de l'insérer en base de données de manière sécurisée.
            DataManager.secureInsert(tripsToInsert);
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
}
