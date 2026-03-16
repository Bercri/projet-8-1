/**
 * Script d'initialisation des données pour GlobalGroupTravel.
 * Exécuter via : sfdx force:apex:execute -f scripts/apex/initial_data.apex
 */

System.debug('--- Lancement du script de données initiales ---');

// 1. Création de Comptes (Clients)
List<Account> accounts = new List<Account>();
accounts.add(new Account(Name = 'Tech Solutions Inc.', Industry = 'Technology'));
accounts.add(new Account(Name = 'Green Earth NGO', Industry = 'Non-Profit'));
accounts.add(new Account(Name = 'Global Corp', Industry = 'Finance'));

insert accounts;
System.debug('Comptes créés : ' + accounts.size());

// 2. Création de Contacts
List<Contact> contacts = new List<Contact>();
contacts.add(new Contact(FirstName = 'John', LastName = 'Doe', AccountId = accounts[0].Id, Email='john@tech.com'));
contacts.add(new Contact(FirstName = 'Jane', LastName = 'Smith', AccountId = accounts[1].Id, Email='jane@green.org'));

insert contacts;
System.debug('Contacts créés : ' + contacts.size());

// 3. Création d'Opportunités (Dont une gagnée pour déclencher le Trip)
List<Opportunity> opps = new List<Opportunity>();

// Opp 1 : Gagnée -> Doit créer un voyage "A venir"
opps.add(new Opportunity(
    Name = 'Voyage Séminaire Tech 2026',
    AccountId = accounts[0].Id,
    StageName = 'Closed Won',
    CloseDate = Date.today(),
    Amount = 50000,
    Destination__c = 'Tokyo',
    Start_Date__c = Date.today().addDays(30),
    End_Date__c = Date.today().addDays(37), // 1 semaine
    Number_of_Participants__c = 20
));

// Opp 2 : En négociation -> Pas de voyage
opps.add(new Opportunity(
    Name = 'Voyage Humanitaire',
    AccountId = accounts[1].Id,
    StageName = 'Negotiation/Review',
    CloseDate = Date.today().addDays(15),
    Amount = 15000,
    Destination__c = 'Lima',
    Start_Date__c = Date.today().addDays(60),
    End_Date__c = Date.today().addDays(70),
    Number_of_Participants__c = 10
));

insert opps;
System.debug('Opportunités créées : ' + opps.size());

// Vérification automatique du Voyage créé par le Trigger
List<Trip__c> createdTrips = [SELECT Id, Name, Status__c FROM Trip__c WHERE Opportunity__c = :opps[0].Id];
if (!createdTrips.isEmpty()) {
    System.debug('SUCCÈS : Voyage généré automatiquement -> ' + createdTrips[0].Name);
} else {
    System.debug('ERREUR : Aucun voyage généré pour l\'opportunité gagnée.');
}

// 4. Création de Contrats (Contract)
List<Contract> contracts = new List<Contract>();
contracts.add(new Contract(
    AccountId = accounts[0].Id,
    Status = 'Draft',
    StartDate = Date.today(),
    ContractTerm = 12
));
insert contracts;
System.debug('Contrats créés : ' + contracts.size());

// 5. Création de Tâches (Task) - Historique des interactions
List<Task> tasks = new List<Task>();
tasks.add(new Task(
    Subject = 'Call Client for Trip details',
    Status = 'Not Started',
    Priority = 'Normal',
    WhatId = opps[0].Id,
    ActivityDate = Date.today().addDays(2)
));
tasks.add(new Task(
    Subject = 'Send Contract for signature',
    Status = 'Completed',
    Priority = 'High',
    WhatId = accounts[0].Id,
    ActivityDate = Date.today().addDays(-1)
));
insert tasks;
System.debug('Tâches créées : ' + tasks.size());

System.debug('--- Fin du script ---');
