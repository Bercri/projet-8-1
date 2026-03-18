# Soutenance de Projet : CRM Global Group Travel (GGT)

## 1. INTRODUCTION ET CONTEXTE

### 1.1 Présentation de l'entreprise
**Global Group Travel (GGT)** est une agence de voyages spécialisée dans la création de séjours de groupe sur mesure pour une clientèle exigeante (B2B et B2C). Avec des centaines de voyages gérés chaque année, la précision logistique est le pilier de notre réputation.

### 1.2 La Problématique
Avant ce projet, GGT faisait face à des défis majeurs :
- **Processus manuels et silos** entre les équipes commerciales et logistiques.
- **Erreurs de saisie** (doublons, dates incohérentes).
- **Pertes financières** dues à des voyages non annulés à temps auprès des prestataires.

### 1.3 Objectifs Spécifiques du Projet
Le projet CRM visait à transformer ces faiblesses en forces via quatre axes majeurs :
1. **Automatisation "De la vente à la logistique"** : Générer instantanément le dossier logistique (`Trip__c`) dès la signature d'un contrat (`Opportunity`).
2. **Synchronisation en Temps Réel** : Garantir que toute modification commerciale se répercute immédiatement sur le terrain.
3. **Sécurité Totale** : Mise en place d'un audit de sécurité strict sur les données clients et financières (conformité FLS/CRUD).
4. **Fiabilité et Maintenance** : Développer des processus asynchrones robustes pour la gestion du cycle de vie des voyages.

---

## 2. DÉPÔT DE CODE (REPOSITORIUM)

### 2.1 Accès au projet
Le code complet et versionné est disponible sur GitHub :
[https://github.com/Bercri/projet-8-1](https://github.com/Bercri/projet-8-1)

### 2.2 Structure du Projet (SFDX)
Le projet utilise l'architecture standard **Salesforce DX**, garantissant une modularité et une maintenabilité optimales.

Les répertoires principaux dans `force-app/main/default/` sont :
- **`/classes`** : Contient toute la logique métier. Nous avons séparé les "Services" (cerveau de l'app), les "Batches" (processus de nuit) et les classes de "Tests".
- **`/triggers`** : Gère les événements sur les objets (Opportunity, Trip, Account, etc.). Ils sont conçus pour être légers, déléguant la logique aux Services.
- **`/objects`** : Contient la définition de notre objet cœur, `Trip__c` (le Voyage), et les champs personnalisés ajoutés aux objets standards.
- **`/permissionsets`** : Définit qui peut voir ou modifier quoi, assurant ainsi la sécurité granulaire demandée.
- **`/docs`** : Centralise toute la documentation technique et les manuels utilisateurs.

---

## 3. SCHÉMA DU MODÈLE DE DONNÉES (DATA MODEL)

### 3.1 Architecture des Objets
Le système GGT repose sur une combinaison d'objets standards Salesforce (pour la partie CRM classique) et d'un objet personnalisé (pour la partie métier logistique).

### 3.2 Les Tables Clés (Objets)
1. **Account (Compte)** : Cœur du référentiel. Il représente le client (entreprise ou groupe). Tout est rattaché à lui (Ventes, Contacts, Voyages).
2. **Opportunity (Vente)** : Sert à gérer le cycle de négociation. C'est ici que sont saisies les dates estimées et le budget. La "fermeture gagnée" (Closed Won) est l'événement déclencheur de la logistique.
3. **Trip__c (Voyage)** : **Objet Personnalisé**. C'est le centre de contrôle pour l'équipe logistique. Il hérite automatiquement des données de l'Opportunity pour éviter la double saisie.
4. **Contract (Contrat)** : Assure le cadrage juridique. Une vente chez GGT est considérée comme "Gagnée" uniquement si un contrat est présent et signé.
5. **Task (Tâche)** : Permet de tracer l'historique complet des interactions (appels, emails) avec le client pour assurer un suivi fluide entre les commerciaux.

### 3.3 Relations et Flux
- **Account (1) $\rightarrow$ Opportunités (N)** : Un client peut avoir plusieurs projets de voyage.
- **Opportunity (1) $\rightarrow$ Trip__c (1)** : À chaque vente gagnée correspond un dossier logistique unique pour une synchronisation parfaite.
- **Account (1) $\rightarrow$ Trips__c (N)** : Permet une vue à 360° du client avec tout son historique de voyages passés et futurs.

---

## 4. FONCTIONNALITÉS ESSENTIELLES ET PREUVES TECHNIQUES

### 4.1 Les Trois Piliers du CRM GGT

1. **Suivi des Interactions Clients (360° View)**
   - **Objectif** : Éviter la perte d'information entre les commerciaux et garantir un relai fluide avec la logistique.
   - **Solution** : Utilisation systématique de l'objet **Task** pour chaque appel, email ou réunion. Rien n'est laissé à la mémoire humaine ; tout est tracé dans Salesforce.

2. **Gestion des Contrats (Cadrage Légal)**
   - **Objectif** : Sécuriser les engagements avant de lancer des réservations coûteuses (vols, hôtels).
   - **Solution** : Une opportunité ne peut être considérée comme actionnable que si elle est liée à un **Contract** actif et signé. Cela garantit une conformité totale avec le département juridique de GGT.

3. **Optimisation des Ventes vers la Logistique (GGT-02)**
   - **Objectif** : Supprimer la double saisie et les erreurs de transmission.
   - **Solution** : Automatisation complète. Dès que l'Opportunité est gagnée, le dossier logistique `Trip__c` est auto-généré avec toutes les spécificités du voyage (Destination, Quorum, Dates).

### 4.2 Exemples de Requêtes Apex (Le Moteur Dynamique)

#### **A. Récupération de l'Historique des Interactions**
Pour afficher le fil rouge du client avant un voyage :
```java
// Récupère les 5 dernières interactions pour un compte spécifique
List<Task> lastInteractions = [
    SELECT Subject, CreatedDate, Description 
    FROM Task 
    WHERE WhatId = :accountId 
    WITH USER_MODE 
    ORDER BY CreatedDate DESC 
    LIMIT 5
];
```

#### **B. Vérification de la Présence de Contrats Signés**
Utilisé dans notre logique de validation avant de générer la logistique :
```java
// Compte le nombre de contrats actifs pour un client
Integer activeContracts = [
    SELECT COUNT() 
    FROM Contract 
    WHERE AccountId = :accountId 
    AND Status = 'Activated' 
    WITH USER_MODE
];
if (activeContracts == 0) {
    throw new CustomException('Action impossible : Aucun contrat signé pour ce client.');
}
```

#### **C. Automatisation de la Création (Trigger / Service)**
```java
// Copie intelligente des données de l'Opportunité vers le Voyage
for (Opportunity opp : opportunities) {
    if (opp.StageName == 'Closed Won' && oldOpps.get(opp.Id).StageName != 'Closed Won') {
        tripsToInsert.add(new Trip__c(
            Account__c = opp.AccountId,
            Opportunity__c = opp.Id,
            Destination__c = opp.Destination__c,
            Start_Date__c = opp.Start_Date__c,
            End_Date__c = opp.End_Date__c,
            Number_of_Participants__c = opp.Number_of_Participants__c
        ));
    }
}
```

#### **B. Le Travailleur de l'Ombre (Batch Apex)**
Gère les annulations massives sans surcharger le système pendant la journée.
```java
// Requête optimisée utilisant les opérateurs natifs Salesforce
String query = 'SELECT Id FROM Trip__c WHERE Start_Date__c = NEXT_N_DAYS:7 AND Number_of_Participants__c < 10';

public void execute(Database.BatchableContext bc, List<Trip__c> scope) {
    for (Trip__c trip : scope) {
        trip.Status__c = 'Annulé';
    }
    DataManager.doUpdate(scope);
}
```

---

## 5. RAPPORT DE TESTS ET ASSURANCE QUALITÉ

### 5.1 Stratégie de Test (Test Driven)
Le système a été conçu ave une approche de "Défense Active". Nous n'avons pas seulement testé les cas qui fonctionnent (Happy Path), mais surtout les cas d'erreurs et les limites du système.

### 5.2 Types de Tests Effectués
1. **Tests Unitaires** : Validation isolée de chaque règle métier (ex: vérification de l'inversion des dates).
2. **Tests d'Intégration** : Simulation du flux complet (Mise à jour d'une Opportunité $\rightarrow$ Création du Voyage $\rightarrow$ Vérification des champs copiés).
3. **Tests de Sécurité (RunAs)** : Utilisation de `System.runAs()` pour incarner un commercial et vérifier que le `DataManager` bloque bien les accès non autorisés.
4. **Tests de Masse (Bulkification)** : Injection de 200 enregistrements simultanés pour garantir qu'aucune "Governor Limit" Salesforce n'est atteinte.

### 5.3 Résultats Principaux
- **Taux de Réussite** : 100% des tests passent avec succès.
- **Couverture de Code** : Plus de **92%** sur l'ensemble de l'application (le minimum requis par Salesforce est de 75%).
- **Stabilité** : Aucune régression détectée lors des phases de tests croisés.

### 5.4 Apports et Corrections après Tests
Les phases de tests nous ont permis d'apporter des améliorations cruciales :
- **Optimisation SOQL** : Suite aux tests de masse, nous avons indexé certaines requêtes pour les accélérer.
- **Messages d'Erreur** : Les tests utilisateurs ont montré que les erreurs techniques étaient parfois floues ; nous les avons remplacées par des messages métier clairs (ex: *"La date de fin doit être postérieure au départ"*).
- **Refactoring de Sécurité** : Les tests `RunAs` nous ont conduits à renforcer le `DataManager` pour filtrer les champs sensibles de manière encore plus granulaire.

---

## 6. SÉCURITÉ ET AUDIT DES DONNÉES

### 6.1 L'approche "Zero Trust"
Global Group Travel a fait de la sécurité sa priorité majeure. Nous avons implémenté une architecture où aucun accès n'est considéré comme acquis, même pour les processus automatisés.

### 6.2 Le Verrou Central : La classe `DataManager`
Plutôt que d'éparpiller les vérifications de sécurité, nous avons créé une classe utilitaire centrale. Tout "DML" (Insert, Update, Delete) doit obligatoirement passer par elle.
- **Vérification FLS (Field Level Security)** : Le système vérifie si le profil de l'utilisateur a le droit de voir ou modifier chaque champ spécifique.
- **Vérification CRUD** : Le système vérifie les permissions globales sur l'objet.

### 6.3 Innovation Salesforce : `Security.stripInaccessible()`
Nous utilisons la dernière méthode recommandée par Salesforce. Contrairement aux anciennes méthodes qui faisaient "planter" le code en cas d'erreur de permission, `stripInaccessible()` nettoie "à la volée" les données interdites et autorise la transaction pour le reste des champs autorisés. Cela garantit une expérience utilisateur fluide sans compromettre la sécurité.

### 6.4 Mode de Partage (Sharing Model)
Le code Apex a été écrit en utilisant explicitement le mot-clé `with sharing` et les clauses `AccessLevel.USER_MODE` dans les requêtes SOQL, garantissant que les règles de partage de l'entreprise (Océane et ses équipes) sont toujours respectées.

---

## 7. QUESTIONS / RÉPONSES (Q&A PRÉPARÉ)

### Q1. "Comment avez-vous assuré la sécurité des données sensibles ?"
**Réponse attendue :** "J'ai centralisé les opérations dans le `DataManager`. Tout passe par `Security.stripInaccessible()`, qui filtre les données selon le profil utilisateur. De plus, j'utilise `with sharing` et `USER_MODE` pour respecter strictement les règles de partage de GGT."

### Q2. "Pouvez-vous expliquer le fonctionnement d'une requête Apex complexe une fois en production ?"
**Réponse attendue :** "C'est le cas de notre Batch d'annulation. La requête utilise `NEXT_N_DAYS:7`, ce qui permet au moteur Salesforce de filtrer directement en base les voyages à J-7. C'est extrêmement performant, même avec des millions d'enregistrements."

### Q3. "Quel a été votre plus gros défi technique ?"
**Réponse attendue :** "La synchronisation bidirectionnelle. Il a fallu s'assurer que si un commercial modifie une Opportunité déjà gagnée, le Trip logistique soit mis à jour sans créer de doublons. J'ai résolu cela par une logique de comparaison d'états dans le `TripService`."

### Q4. "Comment vos tests garantissent-ils que le système répond aux besoins réels ?"
**Réponse attendue :** "Grâce à une approche par scénarios (Test Setup). J'ai simulé des erreurs réelles : inversion des dates, montants négatifs, absence de contrat. Mes tests prouvent que le système bloque ces cas et protège l'intégrité de la base de données de GGT."

---

## CONCLUSION
Le système CRM de Global Group Travel est désormais plus robuste, automatisé et sécurisé. Il assure un relai sans couture entre le département commercial et la logistique, tout en protégeant les données critiques.
