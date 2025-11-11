# 🔄 Guide de basculement LOCAL ↔ CLOUD

## ✅ Configuration terminée !

Votre application peut maintenant basculer facilement entre Appwrite LOCAL et CLOUD.

---

## 🎯 Comment basculer

### **Pour utiliser Appwrite CLOUD** :

1. Ouvrez le fichier : `lib/core/config/appwrite_config.dart`
2. Ligne 7, changez :
   ```dart
   static const bool USE_CLOUD = true; // ← mettez true
   ```
3. Sauvegardez
4. Hot reload ou redémarrez l'app

### **Pour revenir à LOCAL** :

1. Ouvrez le fichier : `lib/core/config/appwrite_config.dart`
2. Ligne 7, changez :
   ```dart
   static const bool USE_CLOUD = false; // ← mettez false
   ```
3. Sauvegardez
4. Hot reload ou redémarrez l'app

---

## 📋 État actuel

✅ **Collections créées dans le Cloud** :
- users
- videos
- matches
- chat_messages
- videoLikes
- photos
- reports
- blockedUsers
- likes

⚠️ **Bucket Storage** :
- Limite atteinte sur le plan gratuit
- **Solution** : Allez dans **Appwrite Cloud Console → Storage**
  - Si vous avez un bucket existant → Utilisez-le
  - Sinon → Supprimez un bucket inutile et créez "medias"

⚠️ **Attributs manquants** :
Dans la collection `users`, il manque `latitude` et `longitude` (erreur API).

**Pour les ajouter manuellement** :
1. Appwrite Cloud Console → Databases → dating_app_db → users
2. Create Attribute → Float :
   - Key: `latitude`
   - Required: No
3. Create Attribute → Float :
   - Key: `longitude`
   - Required: No

---

## 🚀 Prochaines étapes

### **Étape 1 : Corriger le bucket** ✅ PRIORITAIRE
Allez dans Appwrite Cloud Console et créez/configurez un bucket "medias"

### **Étape 2 : Ajouter latitude/longitude**
Créez les 2 attributs manquants (voir ci-dessus)

### **Étape 3 : Migrer vos données**

**Option A : Export/Import manuel** (Recommandé pour tests)
1. Appwrite LOCAL Console → Databases → Export data (JSON)
2. Appwrite CLOUD Console → Databases → Import data

**Option B : Garder vide pour tests**
- Créez des utilisateurs de test directement dans le Cloud
- Testez l'app sans données migrées

### **Étape 4 : Basculer vers le Cloud**
1. Changez `USE_CLOUD = true` dans `appwrite_config.dart`
2. Testez l'application en local
3. Vérifiez que tout fonctionne

### **Étape 5 : Déployer sur Firebase Hosting**
Une fois que l'app fonctionne avec Appwrite Cloud :

```bash
# Installer Firebase CLI
npm install -g firebase-tools

# Se connecter
firebase login

# Initialiser
cd D:\APPS\Flutter\WEB\dating_app
firebase init hosting

# Builder l'app
flutter build web --release

# Déployer
firebase deploy --only hosting
```

---

## 🔍 Vérification

Pour vérifier quelle configuration est active, regardez les logs au démarrage de l'app :

```
═══════════════════════════════════════════════════════
📡 CONFIGURATION APPWRITE ACTIVE
═══════════════════════════════════════════════════════
Mode: ☁️ CLOUD  (ou 🏠 LOCAL)
Endpoint: https://cloud.appwrite.io/v1
Project: 681829e4003b243e6681
Database: 68db88f700374422bfc7
═══════════════════════════════════════════════════════
```

---

## ⚡ Résumé rapide

| Action | Fichier | Ligne | Valeur |
|--------|---------|-------|--------|
| **Basculer vers CLOUD** | `lib/core/config/appwrite_config.dart` | 7 | `USE_CLOUD = true` |
| **Basculer vers LOCAL** | `lib/core/config/appwrite_config.dart` | 7 | `USE_CLOUD = false` |

---

## ❓ Besoin d'aide ?

- Les collections sont créées ✅
- La configuration fonctionne ✅
- Il reste juste à :
  1. Créer/configurer le bucket "medias"
  2. Ajouter latitude/longitude
  3. Tester avec `USE_CLOUD = true`
  4. Déployer sur Firebase

Bon courage ! 🚀
