/**
 * Trigger sur l'objet Trip__c (Voyage).
 * Ici, il se déclenche AVANT une insertion (before insert) ou AVANT une mise à jour (before update).
 * C'est le bon moment pour valider les données et éventuellement bloquer la sauvegarde si quelque chose ne va pas.
 */
trigger TripTrigger on Trip__c (before insert, before update) {
    
    // On vérifie si nous sommes bien AVANT la sauvegarde (Before)
    // ET si c'est une Insertion OU une Mise à jour.
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        
        // On appelle la méthode validateTripData pour vérifier la cohérence des dates et des montants.
        // On lui passe Trigger.new qui contient la liste des voyages en cours de sauvegarde.
        TripService.validateTripData(Trigger.new);
    }
}
