/**
 * Trigger sur l'objet Opportunity (Opportunité).
 * Un trigger est un bout de code qui se déclenche automatiquement quand des enregistrements sont créés, modifiés ou supprimés.
 * Ici, il se déclenche APRÈS une insertion (after insert) ou APRÈS une mise à jour (after update).
 */
trigger OpportunityTrigger on Opportunity (after insert, after update) {
    
    // On vérifie si le trigger est en contexte "After" (après la sauvegarde en base)
    // ET si c'est une Insertion OU une Mise à jour.
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            // On appelle la méthode createTripsFromOpportunities de notre classe TripService.
            // On lui passe :
            // - Trigger.new : La liste des opportunités qui viennent d'être sauvegardées.
            // - Trigger.oldMap : Une "carte" des anciennes versions de ces opportunités.
            TripService.createTripsFromOpportunities(Trigger.new, Trigger.oldMap);
        }
        
        if (Trigger.isUpdate) {
            // Synchronisation : on met à jour les Voyages existants si l'Opportunité change.
            TripService.updateTripsFromOpportunities(Trigger.new, Trigger.oldMap);
        }
    }
}
