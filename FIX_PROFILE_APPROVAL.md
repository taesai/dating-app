# Corriger le problème isProfileApproved

## Problème
Les nouveaux utilisateurs sont automatiquement approuvés (`isProfileApproved = true`) alors qu'ils devraient être en attente d'approbation admin (`false`).

## Solution en 2 étapes

### Étape 1: Corriger l'attribut par défaut dans Appwrite Console

1. Allez sur [Appwrite Console](https://cloud.appwrite.io/console/project-681829e4003b243e6681)
2. Connectez-vous avec votre compte admin
3. Naviguez vers: **Databases** → **dating_db** → **users**
4. Cliquez sur l'onglet **Attributes**
5. Trouvez l'attribut `isProfileApproved`
6. Cliquez sur le bouton **⋮** (trois points) → **Update**
7. **IMPORTANT**: Décochez "Default value" ou mettez la valeur par défaut à `false`
8. Sauvegardez

### Étape 2: Corriger les utilisateurs existants (optionnel)

Si vous voulez mettre tous les utilisateurs actuels en attente d'approbation:

```bash
cd d:\APPS\Flutter\WEB\dating_app
dart run scripts/fix_profile_approval_default.dart
```

Le script vous demandera:
1. Une confirmation que vous avez fait l'étape 1
2. Votre clé API Appwrite (à créer dans Settings → API Keys avec permissions "documents.write")
3. Il mettra ensuite `isProfileApproved = false` pour tous les utilisateurs

## Vérification

Après correction:
1. Créez un nouveau compte test
2. Allez dans le dashboard admin → "Approbation profils"
3. Le nouveau compte devrait apparaître dans "En attente"
4. Vous pouvez maintenant l'approuver manuellement

## Création d'une clé API (pour l'étape 2)

1. Allez sur [Appwrite Console](https://cloud.appwrite.io/console/project-681829e4003b243e6681/settings)
2. Settings → API Keys
3. Cliquez sur "Create API Key"
4. Nom: "Fix Profile Approval"
5. Scopes nécessaires:
   - `databases.read`
   - `databases.write`
6. Copiez la clé (elle ne sera montrée qu'une fois!)
7. Utilisez-la dans le script
8. **IMPORTANT**: Supprimez la clé après utilisation (pour sécurité)
