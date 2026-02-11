# Guide Simple du Projet : Comment ça marche ?

Ce document explique le fonctionnement du projet avec des analogies simples, pour comprendre "qui fait quoi".

## 1. Les Acteurs Principaux (Analogie)

Imaginons que Salesforce est une grande entreprise de voyage. Voici les rôles de chaque bout de code :

*   **Trigger (Le Déclencheur)** : C'est comme un **détecteur de mouvement**. Il surveille en permanence la base de données. Dès que quelque chose bouge (création, modification), il s'active.
*   **Service (Le Chef d'Orchestre)** : C'est le **cerveau**. Le Trigger est bête (il ne fait que détecter), donc il appelle le Service pour réfléchir et prendre les décisions importantes.
*   **Batch (L'Équipe de Nuit)** : C'est une tâche planifiée qui tourne souvent la nuit pour traiter de gros volumes de dossiers sans ralentir personne.
*   **DataManager (Le Vigile)** : C'est lui qui vérifie les badges à l'entrée. Avant d'écrire ou de supprimer quoi que ce soit, on passe par lui pour vérifier qu'on a le droit.

---

## 2. Scénario 1 : La Vente d'un Voyage (De l'Opportunité au Voyage)

C'est le cœur du système. Voici ce qui se passe quand un commercial gagne une affaire.

1.  **L'Action** : Le commercial change l'étape d'une Opportunité à "Gagnée" (Closed Won) et sauvegarde.
2.  **Le Réflexe (`OpportunityTrigger`)** : Le déclencheur "OpportunityTrigger" voit le changement. Il se dit : *"Tiens, une opportunité vient d'être mise à jour !"*.
3.  **La Délégation** : Le Trigger appelle immédiatement `TripService.createTripsFromOpportunities`.
4.  **L'Action (`TripService`)** : 
    *   La classe Service vérifie : "Est-ce que c'est bien une opportunité gagnée ?"
    *   Si oui, elle prépare un nouveau dossier **Voyage** (`Trip__c`).
    *   Elle recopie toutes les infos (Dates, Destination, Montant...).
    *   Elle appelle le **Vigile** (`DataManager`) pour sauvegarder le tout proprement.
5.  **Résultat** : Un nouveau Voyage apparaît dans le système, lié à l'Opportunité.

---

## 3. Scénario 2 : Le Contrôle Qualité (Validation des Dates)

On veut éviter les erreurs bêtes, comme un voyage qui finit avant d'avoir commencé.

1.  **L'Action** : Quelqu'un essaie de créer ou modifier un Voyage avec des dates incohérentes (Fin < Début).
2.  **Le Réflexe (`TripTrigger`)** : Le déclencheur "TripTrigger" s'active **AVANT** la sauvegarde (Before Insert/Update).
3.  **La Vérification (`TripService`)** :
    *   Le Trigger demande à `TripService.validateTripDates` de vérifier le dossier.
    *   Le Service compare les dates.
    *   Si `Fin <= Début`, il crie **STOP** (`addError`).
4.  **Résultat** : Salesforce bloque la sauvegarde et affiche un message d'erreur rouge à l'utilisateur. Rien n'est enregistré.

---

## 4. Scénario 3 : Le Nettoyage Automatique (Les Batchs)

Tous les jours (ou toutes les nuits), le système fait le ménage tout seul.

### A. L'Annulation Automatique (`TripCancellationBatch`)
*   **Mission** : Trouver les voyages qui partent dans 7 jours mais qui sont presque vides.
*   **Critères** : Départ = J+7 ET Participants < 10.
*   **Action** : Si un voyage correspond, le Batch passe son statut à "Annulé" et sauvegarde.

### B. La Mise à Jour des Statuts (`TripStatusUpdateBatch`)
*   **Mission** : Tenir à jour le statut des voyages en fonction de la date du jour.
*   **Logique** :
    *   Si on est *avant* le départ -> **"A venir"**
    *   Si on est *pendant* le voyage -> **"En cours"**
    *   Si on est *après* le retour -> **"Terminé"**

---

## En Résumé

| Fichier | C'est quoi ? | Rôle Simple |
| :--- | :--- | :--- |
| **OpportunityTrigger** | Déclencheur | *"Oh, une opportunité a changé !"* |
| **TripTrigger** | Déclencheur | *"Oh, on touche à un voyage !"* |
| **TripService** | Cerveau | *"Attends, je vérifie les règles et je prépare les dossiers..."* |
| **TripCancellationBatch** | Robot | *"Je cherche les voyages vides à annuler..."* |
| **TripStatusUpdateBatch** | Robot | *"Je mets à jour les étiquettes A venir / En cours / Terminé..."* |
| **DataManager** | Sécurité | *"Papiers s'il vous plaît ! Avez-vous le droit d'écrire ici ?"* |
