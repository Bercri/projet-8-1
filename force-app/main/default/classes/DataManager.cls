public with sharing class DataManager {
    public static void secureInsert(List<SObject> records) {
        if (records == null || records.isEmpty()) return;
        SObjectType type = records[0].getSObjectType();
        if (!type.getDescribe().isCreateable()) {
            throw new SecurityException('Permissions insuffisantes pour créer des enregistrements de type ' + type);
        }
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, records);
        insert decision.getRecords();
    }
    public static void secureUpdate(List<SObject> records) {
        if (records == null || records.isEmpty()) return;
        SObjectType type = records[0].getSObjectType();
        if (!type.getDescribe().isUpdateable()) {
            throw new SecurityException('Permissions insuffisantes pour mettre à jour des enregistrements de type ' + type);
        }
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, records);
        update decision.getRecords();
    }
    public static void secureDelete(List<SObject> records) {
        if (records == null || records.isEmpty()) return;
        SObjectType type = records[0].getSObjectType();
        if (!type.getDescribe().isDeletable()) {
            throw new SecurityException('Permissions insuffisantes pour supprimer des enregistrements de type ' + type);
        }
        delete records;
    }
    public static List<SObject> secureQuery(String query) {
        if (String.isBlank(query)) {
            return new List<SObject>();
        }
        return Database.query(query, AccessLevel.USER_MODE);
    }
}
