/**
 * Utility class pour gérer les opérations de base de données (CRUD) de manière SÉCURISÉE.
 * Salesforce impose de vérifier les permissions de l'utilisateur (FLS/CRUD) avant de toucher aux données.
 */
public with sharing class DataManager {
    
    /**
     * @description Insère des enregistrements (INSERT) en vérifiant les permissions.
     */
    public static void secureInsert(List<SObject> records) {
        if (records == null || records.isEmpty()) return;
        SObjectType type = records[0].getSObjectType();
        
        // Vérifie si l'utilisateur a le droit de CRÉER ce type d'objet
        if (!type.getDescribe().isCreateable()) {
            throw new SecurityException('Permissions insuffisantes pour créer des enregistrements de type ' + type);
        }
        
        // Nettoie les champs auxquels l'utilisateur n'a pas accès en écriture
        // (par exemple, empêche quelqu'un de forcer une valeur dans un champ qu'il n'est pas censé toucher)
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, records);
        insert decision.getRecords();
    }
    
    /**
     * @description Met à jour des enregistrements (UPDATE) en vérifiant les permissions.
     */
    public static void secureUpdate(List<SObject> records) {
        if (records == null || records.isEmpty()) return;
        SObjectType type = records[0].getSObjectType();
        
        // Vérifie si l'utilisateur a le droit de MODIFIER ce type d'objet
        if (!type.getDescribe().isUpdateable()) {
            throw new SecurityException('Permissions insuffisantes pour mettre à jour des enregistrements de type ' + type);
        }
        
        // Nettoie les champs inaccessibles
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, records);
        update decision.getRecords();
    }
    
     /**
     * @description Supprime des enregistrements (DELETE) en vérifiant les permissions.
     */
    public static void secureDelete(List<SObject> records) {
        if (records == null || records.isEmpty()) return;
        SObjectType type = records[0].getSObjectType();
        
        // Vérifie si l'utilisateur a le droit de SUPPRIMER ce type d'objet
        if (!type.getDescribe().isDeletable()) {
            throw new SecurityException('Permissions insuffisantes pour supprimer des enregistrements de type ' + type);
        }
        
        delete records;
    }
}
