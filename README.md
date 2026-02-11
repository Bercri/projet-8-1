# GlobalGroupTravel CRM

Bienvenue sur le projet CRM de GlobalGroupTravel, conçu pour gérer les Opportunités et les Voyages de groupe sur Salesforce.

## Architecture du Projet
Ce projet utilise Salesforce DX et respecte les bonnes pratiques de développement modulaire.
- **Trip__c (Voyage)** : Objet central stockant les infos du voyage.
- **Automation** : Triggers et Batches pour la création automatique et la gestion du cycle de vie.
- **Sécurité** : Gestion stricte des droits via `DataManager` et Permission Sets.

## Fonctionnalités Principales
1. **Création Automatique** : Une opportunité gagnée génère un Voyage.
2. **Validation** : Les dates des voyages sont vérifiées (Fin > Début).
3. **Nettoyage** : Annulation automatique des voyages vide à J-7.
4. **Cycle de Vie** : Mise à jour automatique des status (A venir -> En cours -> Terminé).

## Installation et Déploiement

### Pré-requis
- Salesforce CLI (sf)
- VS Code avec Salesforce Extension Pack

### Déploiement
Pour déployer tout le code et la configuration :
```sh
sf project deploy start --target-org YOUR_ORG_ALIAS
```

### Tests
Pour lancer tous les tests unitaires :
```sh
sf apex run test --code-coverage --result-format human -w 10
```

## Documentation
Une documentation technique détaillée est disponible dans le fichier `Project_Documentation.md`.
