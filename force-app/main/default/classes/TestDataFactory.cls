@IsTest
public class TestDataFactory {

    /**
     * @description Crée un utilisateur Standard avec un profil donné.
     * Utile pour tester les permissions.
     */
    public static User createBaseUser(Profile p) {
        // On génère un nom unique pour éviter les doublons
        String uniqueName = 'user' + DateTime.now().getTime();
        User u = new User(
            Alias = 'stdusr', 
            Email = uniqueName + '@testorg.com', 
            EmailEncodingKey = 'UTF-8', 
            LastName = 'Testing', 
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = p.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = uniqueName + '@testorg.com'
        );
        return u;
    }

    /**
     * @description Crée un Compte basique.
     * Sert de parent pour les opportunités.
     */
    public static Account createAccount(String name) {
        Account acc = new Account(Name = name);
        insert acc;
        return acc;
    }

    /**
     * @description Crée une Opportunité liée à un Compte.
     * Pré-remplie avec des données valides pour générer un Voyage.
     */
    public static Opportunity createOpportunity(String name, Id accountId) {
        Opportunity opp = new Opportunity(
            Name = name,
            StageName = 'Prospecting', // Étape initiale
            CloseDate = Date.today().addDays(30),
            AccountId = accountId,
            Destination__c = 'Paris',
            Start_Date__c = Date.today().addDays(10),
            End_Date__c = Date.today().addDays(20),
            Number_of_Participants__c = 10,
            Amount = 10000
        );
        insert opp;
        return opp;
    }
}
