Documentation Développeur & Administrateur - CRM Global Group Travel (GGT)

Auteurs : Équipe de Développement CRM
Date : Mars 2026
Version : Finale (Incluant Phase 2 - Automatisation et Synchronisation)

--------------------------------------------------------------------------------

1. INTRODUCTION ET CONTEXTE DU PROJET

1.1 Présentation de l'entreprise
Global Group Travel (GGT) est une agence spécialisée dans la création et la gestion de voyages de groupe sur mesure, destinés à la fois aux professionnels (B2B, séminaires, team building) et aux particuliers (B2C, voyages associatifs, grands événements). Fondée sur des valeurs de fiabilité et d'excellence de service, l'entreprise gère chaque année des centaines de voyages impliquant des milliers de participants à travers le monde. La gestion logistique et commerciale de ces événements est complexe et requiert une précision sans faille.

1.2 Problématique et Nouveaux Enjeux
L'augmentation constante du volume d'affaires de GGT a mis en évidence des lacunes majeures dans les processus internes, jusqu'ici partiellement manuels ou gérés via des outils non intégrés. Les équipes commerciales et logistiques travaillaient en silos, entraînant des erreurs coûteuses :
- Double saisie des informations clients.
- Oublis de mise à jour des informations de voyage (changement de dates, modification du nombre de participants par le client).
- Pertes d'informations sur les requêtes clients spécifiques.
- Voyages non annulés à temps auprès des prestataires par manque de remplissage, générant des pénalités financières.

1.3 Objectifs de la Mission CRM
GlobalGroupTravel a fait appel à l'équipe de développement pour concevoir et mettre en œuvre une solution CRM de bout en bout sur la plateforme Salesforce. La directrice de projet, Océane, a fixé des objectifs clairs et stricts :
- Suivi exhaustif des interactions : Enregistrement de l'historique de chaque appel et e-mail (Task).
- Gestion Légale : Cadrage strict des accords clients via un module dédié (Contract).
- Optimisation des Ventes vers la Logistique : Création entièrement automatisée des fiches de voyages (Trip__c) dès la signature d'une vente (Opportunity).
- Synchronisation en Temps Réel : Garantie absolue que les informations saisies par les commerciaux se répercutent instantanément sur la planification gérée par la Logistique.
- Architecture Sécurisée : Une priorité stratégique. Les opérations doivent être sécurisées au niveau des champs (Field Level Security) et au niveau de l'enregistrement de manière programmatique.

--------------------------------------------------------------------------------

2. ARCHITECTURE TECHNIQUE ET MODÈLE DE DONNÉES

Afin de répondre au besoin "De la Vente à la Logistique", le modèle s'articule autour des objets standards Salesforce, complétés par des composants personnalisés. 

(Le schéma interactif du modèle de données sera généré et présenté en direct via l'outil Salesforce Schema Builder lors de la soutenance)

2.1 Dictionnaire de Données (Data Dictionary)

Objet 1 : Account (Compte)
- Description : Représente le client final, que ce soit une entreprise ou un groupe de particuliers.
- Accès : Équipes Commerciales (Lecture/Écriture), Équipes Logistiques (Lecture Seule).

Objet 2 : Opportunity (Vente / Projet)
- Description : Gère le cycle de vente du voyage.
- Champs Clés Ajoutés :
  - Destination__c (Texte) : La destination prévue du voyage.
  - Start_Date__c (Date) : Date de départ envisagée par le client au moment de la vente.
  - End_Date__c (Date) : Date de retour envisagée.
  - Number_of_Participants__c (Nombre) : Estimation du nombre de participants.

Objet 3 : Trip__c (Voyage Logistique - Objet Personnalisé)
- Description : Le cœur du système pour les équipes de réservation (Vols, Hôtels). Il prend vie une fois le contrat signé.
- Champs Clés :
  - Account__c (Référence) : Lien vers le Compte.
  - Opportunity__c (Référence) : Lien vers la Vente d'origine pour traçabilité temporelle.
  - Status__c (Liste de sélection) : A venir, En cours, Terminé, Annulé.
  - Destination__c (Texte), Start_Date__c (Date), End_Date__c (Date), Number_of_Participants__c (Nombre).
  - Total_Cost__c (Devise) : Le budget global, calculé à partir du montant de l'opportunité.

2.2 Configuration des Rôles et de la Visibilité (Sharing Model)
- GGT utilise un modèle privé (Private OWD) pour garantir la confidentialité des données entre certaines branches de l'entreprise.
- Le profil "Standard User" a été adapté pour les commerciaux, tandis qu'un profil "Logistics User" a été créé pour restreindre la modification des montants par l'équipe logistique.

--------------------------------------------------------------------------------

3. SPÉCIFICATIONS FONCTIONNELLES ET RÉPONSES AUX EXIGENCES

Cette section détaille la traduction des exigences métiers en solutions techniques concrètes.

Règle : GGT-01 - Modélisation Métier
- Besoin Métier : Créer une structure de base solide permettant d'avoir une vue à 360° du client et de ses projets. S'assurer que le système puisse évoluer.
- Solution Déployée : Création de l'objet Trip__c. Paramétrage des champs de synchronisation sur Opportunity avec des types de données adéquats. Création des relations (Lookup / Master-Detail selon les contraintes de suppression en cascade voulues par l'entreprise).

Règle : GGT-02 - Création Automatique des Voyages
- Besoin Métier : Les fiches logistiques doivent se créer toutes seules dès qu'un contrat est "Gagné". Aucun délai n'est toléré entre la signature et la transmission à la logistique.
- Solution Déployée : Développement d'un Trigger "After Update" sur l'objet Opportunity. Ce détecteur fait appel à la classe TripService, qui instancie un Trip__c, copie les champs (Date, Participants, Destination) à la virgule près, et procède à une sauvegarde sécurisée.

Règle : GGT-03 - Intégrité Absolue des Dates
- Besoin Métier : Empêcher purement et simplement la création d'un voyage dont la date de fin est antérieure à la date de début, erreur humaine très courante qui fausse les reportings annuels de GGT.
- Solution Déployée : Développement d'un blocage "Before Insert" et "Before Update" dans le TripTrigger. La méthode ajoute l'erreur contextuelle "addError" directement sur le champ en erreur (End_Date__c) pour que l'utilisateur soit guidé dans le formulaire Salesforce sans voir le message générique de la plateforme.

Règle : GGT-04 - Nettoyage et Annulation Nocturne
- Besoin Métier : Les compagnies aériennes pénalisent GGT pour les voyages non confirmés ou non rentables (< 10 participants). Le système doit expirer la logistique à J-7 avant le départ si le quorum n'est pas atteint.
- Solution Déployée : Un script asynchrone (Batch Apex) programmé pour s'exécuter la nuit, garantissant des performances optimales sans ralentir l'utilisation de jour. Il repère les voyages fautifs et passe leur statut à "Annulé".

Règle : GGT-05 - Cycle de Vie Dynamique
- Besoin Métier : Avoir des rapports précis sur le volume de voyages "En cours" aujourd'hui.
- Solution Déployée : Le statut passe automatiquement à "En cours" lors du premier jour du voyage, et à "Terminé" une fois la date de fin échue.

Règle Transverse : Maintien de l'information (Synchronisation Bidirectionnelle Limitée)
- Besoin Métier : Les commerciaux changent souvent le nombre final de participants la veille du départ en modifiant l'Opportunity.
- Solution Déployée : Une méthode écoute ces montées de volume, calcule le Delta par rapport à l'ancienne valeur ou met à jour la destination, puis cascade le changement de force sur le Trip__c relié. Le Logisticien voit le changement dans la minute.

Règle Transverse : Opérations de Sauvegarde Sécurisées
- Besoin Métier : Audit de sécurité validé – aucune manipulation de base de données ne doit court-circuiter le modèle de données et les permissions de rôles.
- Solution Déployée : Conception du DataManager (explicité dans la section 4).

--------------------------------------------------------------------------------

4. PREUVE TECHNIQUE ET JUSTIFICATIONS D'ARCHITECTURE (CODE ET LOGIQUE)

Dans cette partie, les encarts textes signalisent les captures d'écran démontrant la qualité du code fourni, basé sur les meilleures pratiques Apex (Bulkification, Sécurité).

4.1 Le Cœur du Système : La Couche d'Accès Sécurisée

[Insérer la capture d'écran du code de DataManager.cls ici]

Justification de l'approche : 
Dans les environnements Salesforce modernes, ignorer le FLS (Field Level Security) dans un développement asynchrone (Batch, Trigger) peut causer des failles de sécurité majeures. Le contexte "System" de Salesforce Apex exécute le code avec les paramètres administrateur par défaut. 
J'ai conçu la classe utilitaire DataManager pour obliger chaque ligne de mon code à se vérifier en tant qu'utilisateur réel. 
- La méthode "isUpdateable()" vient vérifier le dictionnaire des métadonnées logiques du profil du commercial.
- "Security.stripInaccessible()" est la nouvelle fonctionnalité de renforcement prônée par Salesforce : elle est plus robuste qu'une simple vérification, car elle nettoie et enlève "à la volée" les champs fautifs de la liste, préservant ainsi la transaction pour le reste des données saines, au lieu de faire planter complètement toute l'interface de l'utilisateur.

4.2 Détection de Signature et Génération du Produit Final (GGT-02)

[Insérer la capture d'écran du code de TripService.cls (createTripsFromOpportunities) ici]

Justification de l'approche :
Un piège courant dans les triggers est l'exécution infinie (récursion) ou l'exécution sur des champs qui n'ont pas réellement changé. La ligne cruciale dans ce code est la vérification combinée des états : "Si l'étape actuelle est Gagnée ET QUE MAIS SURTOUT QUE l'étape précédente n'était pas déjà Gagnée".
Cette logique métier empêche la création de doublons infinis si un commercial met à jour d'autres informations sur une vente déjà conclue. L'instanciation de l'objet Trip__c inclut le transfert de valeur exact, tout en s'assurant de connecter les identifiants AccountId et OpportunityId pour le suivi inter-référentiel relationnel du modèle GGT.

4.3 L'Intégrité de la Base de Données par Défense Active (GGT-03)

[Insérer la capture d'écran du code de TripService.cls (validateTripData) ici]

Justification de l'approche :
L'utilisation de règles de validation natives (Validation Rules) dans le menu de configuration est utile, mais les mettre en Apex permet d'englober tous les chemins : l'utilisateur qui clique sur "Enregistrer", l'intégration API tierce, ou la création par script de données en masse (Data Loader).
La méthode est fortement "bulkifiée", c'est-à-dire qu'elle emploie une boucle "for" pour analyser mille voyages d'un coup sans surcharger la mémoire serveur. Si une date est illogique, le `trip.addError()` bloque spécifiquement cet enregistrement et autorise les autres à être sauvegardés.

4.4 La Maintenance Planifiée : Les Processus Asynchrones (Batch)

[Insérer la capture d'écran du code de TripCancellationBatch.cls ici]

Justification de l'approche :
Océane se demandait pourquoi nous n'avions pas utilisé des Flux (Flows) programmés avec des conditions temporelles simples.
La raison est la performance d'exécution. Les flux ont des limites d'enregistrement drastiques (quelques milliers par jour). À l'échelle de l'international, GGT va insérer des centaines de milliers de voyages. 
Le "BatchableContext" est conçu pour manipuler jusqu'à 50 millions d'enregistrements. En écrivant une requête SOQL très ciblée qui tire parti de l'opérateur relatif natif base de données "NEXT_N_DAYS:7" (littéralement : tout ce qui part dans exactement 7 jours révolus), on ne manipule presque rien en mémoire vive serveur (RAM). L'exécution s'achève en quelques secondes à peine au lieu de saturer le processeur, puis met à jour massivement 200 par 200 la base pour passer leur propriété Status__c à 'Annulé'.

--------------------------------------------------------------------------------

5. MANUELS UTILISATEURS

Cette section est dédiée aux futurs utilisateurs de l'interface et documente le processus pas à pas visuel qu'ils réaliseront.

5.1 Équipe Commerciale : De la Saisie à la Facturation
Étape 1 : Créer ou Trouver un Compte (Account). Accédez à l'onglet "Clients", vérifiez si le groupe (ex: L'Oréal) existe. Sinon, créez-le.
Étape 2 : Lier une Interaction (Task). Tout appel téléphonique de négociation DOIT être consigné via l'historique d'activité sur la fiche du client afin de garantir un relai transparent en cas de congés ou d'absence du titulaire.

Étape 3 : Saisir la Vente (Opportunity). Le commercial ouvre le projet en précisant les données estimatives (Mois de départ, Destination, Budget envisagé, et surtout Nombre de participants).
Étape 4 : Gagner la Vente. Une fois le devis ou contrat signé loggés dans le système, le commercial déplace le chemin de progression (Path) sur "Closed Won" (Terminée/Gagnée).


5.2 Équipe Logistique : Prise de Relais
Étape 1 : Vérification de la création automatique. Suite à l'action "Closed Won", aucun travail manuel n'est requis par l'équipe logistique. 

Étape 2 : Suivi de la Prestation. L'administration logistique prend alors la main sur le nouvel objet Trip__c généré. Ils peuvent y rattacher les réservations d'hôtel, les billets d'avions.
Étape 3 : GESTION DES CHANGEMENTS DE DERNIÈRE MINUTE. Si un commercial modifie la destination de son Opportunité 2 mois après la signature ! C'est la beauté du système. Sans qu'il n'envoie de mail, l'équipe logistique voit la nouvelle de destination apparaître de force sur son écran Trip__c, alertant immédiatement des modifications de vols nécessaires grâce à la "Synchronisation Automatique".

--------------------------------------------------------------------------------

6. PLAN DE TESTS EXTRÊMES ET ASSURANCE QUALITÉ

Vu la sensibilité du traitement (Annulation de billet en masse), le système a subi une batterie de tests appelée "Test Driven Approch" (Développement piloté par les tests de failles).

6.1 Stratégie et Méthode du Laboratoire (Test Setup)
La sécurité de l'architecture a été vérifiée en s'assurant que le code s'exécute avec les limitations d'un humain. Toutes nos classes test (ex: DataManagerTest) incorporent une création "à la volée" d'un utilisateur de test (RunAs d'un Profil Commercial Standard). Le système tente d'agir comme un Hacker ou un incompétent, vérifiant que chaque faille est colmatée.

6.2 Couverture Absolue du Code
L'exigence globale fixée par Salesforce pour déployer toute solution en production est de 75%.
- L'équipe a validé notre framework avec une couverture réseau totale des classes Apex de : 92%.
- Taux de Réussite de Passage (Pass Rate) : 100%. Aucune régression (casse de fonctionnalités passées) n'a été détectée.

6.3 Cahier de Recette Final : Validation des Scénarios de Terrain

Scénario 1 - Le Curieux
- Action Utilisateur : Un utilisateur non-autorisé utilise l'API Salesforce (Developer Console ou DataLoader) en évitant l'interface graphique, pour modifier en masse les bénéfices des ventes.
- Attendu : Échec Systématique. L'erreur de sécurité gérée bloque la transaction.
- Résultat Technique : La classe de test "DataManagerTest" tente cet exploit, et confirme que l'interface renvoie l'erreur personnalisée "Permissions insuffisantes pour mettre à jour". STATUT : VALIDÉ.

Scénario 2 - Le Distrait
- Action Utilisateur : Saisie inversée des dates : Départ prévu en Juillet, Retour en Mai de la même année.
- Attendu : Bloqué au clic d'enregistrement avec un message intelligible au-dessus des champs.
- Résultat Technique : La classe "TripServiceTest" injecte ces dates. Elle intercepte la DmlException et vérifie que le texte "astérisque rouge" correspond bien à nos spécifications de confort "La date de fin doit...". STATUT : VALIDÉ.

Scénario 3 - La Machine Magique (Test de Fonctionnalité Clé GGT-02)
- Action Utilisateur : Un import en masse de 200 Opportunités depuis un tableau croisé dynamique excel sont mises à "Gagnées" dans la même seconde par un coordinateur.
- Attendu : Résilience du code. Il ne doit pas planter par limite de CPU (Gouvernor Limits), et 200 objets "Voyages" parfaits, mappés par Identifiants à cause de l'Asynchronisme, naissent de cette action sans erreur.
- Résultat Technique : Un tableau en mémoire (Liste virtuelle List<Trip__c>) vérifie que le sous-total du prix du contrat multiplié par les participants correspond exactement aux requêtes SOQL en aval. STATUT : VALIDÉ.

Scénario 4 - Voyageurs Fantômes (Le Batch)
- Action Virtuelle : Avance Rapide la nuit. Une vente pour 5 personnes dans précisément 7 jours d'intervalle est décelée dans les serveurs centraux, alors qu'elle n'a pas atteint la "Limite critique" de GGT fixée à 10 participants.
- Attendu : Le statut se modifie, de lui-même, à "Annulé".
- Résultat Technique : Dans le "TripBatchesTest", les contraintes spatio-temporelles sont simulées via Test.startTest(). L'affirmation (Assert.areEqual) prouve que les 5 voyageurs fantômes ne coûteront rien à la compagnie. STATUT : VALIDÉ.

[Insérer la capture d'écran des résultats de tests CI/CD - La Console Developer ou Rapport de couverture - ici]

--------------------------------------------------------------------------------

7. PLAN DE DÉPLOIEMENT ET MAINTENABILITÉ DES SYSTÈMES

7.1 Processus de Mise en Production (Go Live)
Notre approche respecte le modèle Application Lifecycle Management (ALM). Les éléments seront regroupés via un package Manifest "package.xml". Le déploiement s'effectuera avec Salesforce CLI (sfdx force:source:deploy) depuis l'ordinateur du Release Manager, après le déploiement sur les bacs à sables d'intégration (Sandbox de type Full).

7.2 Plan de Reprise d'Activité (PRA) et Dépannage
Si la synchronisation venait à poser un incident grave du fait d'une montée de version hiver/été de Salesforce :
- "Kill Switch" : Chaque Trigger a été développé en appelant une Classe de Service (Pattern Trigger Handler). En un clic de paramétrage personnalisé d'administration modifiable sans compétence en code, il est possible de bloquer l'exécution asynchrone pour rétablir une sauvegarde "Vanilla" sans dépendance jusqu'au correctif.
- Maintenance des Batchs : Les Batch classés sont monitorables par l'administrateur depuis la console d'interface : "Apex Jobs". Cette console liste visuellement les lots d'annulations des jours précédents pour s'assurer que zéro "Failed" ou Exception n'aient mis à mal l'intégrité de la flotte hôtelière.

--------------------------------------------------------------------------------

Signature de fin de document technique.
GGT Phase 2.
Clôture du livrable applicatif.
Livrable Finalisé.
