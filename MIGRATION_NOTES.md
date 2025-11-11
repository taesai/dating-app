# Notes de Migration - Backend Local vers Appwrite

## Vue d'ensemble
Cette application fonctionne actuellement avec un backend local Node.js. Ce document liste toutes les modifications à apporter pour migrer vers Appwrite Cloud.

---

## 🔧 Configuration Backend

### Fichier de configuration principal
**Fichier**: `lib/core/config/backend_config.dart`

```dart
class BackendConfig {
  static const bool USE_LOCAL_BACKEND = true; // ← Passer à false pour Appwrite
}
```

**Action pour migration**:
- Changer `USE_LOCAL_BACKEND = false`

---

## 📁 Services Backend

### 1. Backend Service (Orchestrateur)
**Fichier**: `lib/core/services/backend_service.dart`

Ce fichier orchestre les appels entre le backend local et Appwrite. Toutes les méthodes vérifient `BackendConfig.USE_LOCAL_BACKEND` et appellent le service approprié.

**Méthodes qui nécessitent une implémentation Appwrite**:
- `getLikedVideos()` - Récupérer les vidéos likées par l'utilisateur
- `getNearbyUsers()` - Recherche géolocalisée (utilisée dans users_map_page.dart)
- `deleteProfilePhoto()` - Suppression de photos (actuellement non implémentée en local)

**Action pour migration**:
- Implémenter les méthodes manquantes dans `appwrite_service.dart`

---

### 2. Local Backend Service
**Fichier**: `lib/core/services/local_backend_service.dart`

Service spécifique au backend Node.js local. **Ce fichier ne sera PAS utilisé après migration**.

**Points importants**:
- `baseUrl = 'http://localhost:3000'` - URL du serveur local
- `getFileView()` - Génère les URLs pour photos: `http://localhost:3000/uploads/photos/{fileId}`
- `getVideoUrl()` - Génère les URLs pour vidéos: `http://localhost:3000/uploads/videos/{fileId}`

**Action pour migration**:
- Aucune modification nécessaire (service ignoré quand USE_LOCAL_BACKEND = false)

---

### 3. Appwrite Service
**Fichier**: `lib/core/services/appwrite_service.dart`

Service pour Appwrite Cloud. **Ce fichier sera activé après migration**.

**Méthodes à vérifier/implémenter**:
1. ✅ `login()` - Authentification
2. ✅ `createAccount()` - Création de compte
3. ✅ `getMatches()` - Récupération des matches
4. ✅ `likeUser()` - Like d'utilisateur
5. ❌ `getLikedVideos()` - **À IMPLÉMENTER**
6. ❌ `getNearbyUsers()` - **À IMPLÉMENTER** (avec géolocalisation)
7. ❌ `likeVideo()` - **À IMPLÉMENTER** (likes de vidéos)

**Action pour migration**:
- Implémenter les méthodes manquantes (marquées ❌)
- Vérifier les IDs de database/collection Appwrite

---

## 🗄️ Structure Base de Données

### Backend Local (Node.js)
**Fichier**: `dating_app_backend/database/db.json`

Collections:
- `users` - Profils utilisateurs
- `videos` - Métadonnées vidéos
- `likes` - Likes d'utilisateurs (pour matches)
- `video_likes` - **NOUVEAU** - Likes de vidéos
- `matches` - Matches entre utilisateurs

### Migration vers Appwrite

**Collections à créer dans Appwrite**:

#### 1. Collection `video_likes`
```json
{
  "id": "string (UUID)",
  "userId": "string (ID de l'utilisateur qui like)",
  "videoId": "string (ID de la vidéo)",
  "videoOwnerId": "string (ID du propriétaire de la vidéo)",
  "createdAt": "datetime"
}
```

**Indexes à créer**:
- Index sur `userId` (pour récupérer les likes donnés)
- Index sur `videoOwnerId` (pour récupérer les likes reçus)
- Index composite sur `userId + videoId` (pour éviter les doublons)

**Permissions**:
- Read: Propriétaire uniquement
- Create: Utilisateurs authentifiés
- Update: Aucun
- Delete: Propriétaire uniquement

---

## 🎨 Modèles de Données

### DatingUser Model
**Fichier**: `lib/core/models/dating_user.dart`

**Propriété importante pour migration**:
```dart
List<String> get photoUrlsFull {
  final backend = BackendService();
  return photoUrls.map((fileId) => backend.getFileView(fileId)).toList();
}
```

Cette propriété génère automatiquement les URLs complètes des photos. Elle fonctionne pour les deux backends car elle utilise `BackendService` qui délègue au bon service.

**Action pour migration**:
- Vérifier que `appwrite_service.getPhotoUrl()` retourne les URLs Appwrite Storage

---

### VideoModel
**Fichier**: `lib/core/models/video_model.dart`

**Méthode ajoutée**:
```dart
VideoModel copyWith({...}) // Pour mise à jour immutable du compteur de likes
```

**Action pour migration**:
- Aucune - compatible Appwrite

---

## 🔄 Routes Backend Local à Reproduire

### Routes video_likes (NOUVEAU)
**Fichier**: `dating_app_backend/routes/video_likes.js`

**Endpoints implémentés**:
1. `POST /video-likes/:videoId` - Liker une vidéo
2. `GET /video-likes/received` - Likes reçus (avec déduplication par userId)
3. `GET /video-likes/given` - Likes donnés
4. `DELETE /video-likes/:videoId` - Unlike une vidéo

**Logique importante - Déduplication** (ligne 63-70):
```javascript
// Garder seulement le plus récent like de chaque utilisateur
const uniqueLikes = new Map();
likes.forEach(like => {
  const existing = uniqueLikes.get(like.userId);
  if (!existing || new Date(like.createdAt) > new Date(existing.createdAt)) {
    uniqueLikes.set(like.userId, like);
  }
});
```

**Action pour migration**:
- Implémenter la même logique côté Appwrite avec des requêtes ou des Cloud Functions

---

## 📱 Pages Modifiées

### 1. SwipePage
**Fichier**: `lib/features/pages/swipe_page.dart`

**Fonctionnalités ajoutées**:
- ✅ Chargement des vidéos déjà likées au démarrage (`_loadLikedVideos()`)
- ✅ Like automatique de vidéo lors du swipe droite (`_likeVideoById()`)
- ✅ Vérification anti-double-like avant swipe
- ✅ Swipe vertical vers le profil (GestureDetector)
- ✅ Badge informatif des likes (non cliquable)

**Dépendances backend**:
- `getLikedVideos()` - **Nécessite implémentation Appwrite**
- `likeVideo(videoId)` - **Nécessite implémentation Appwrite**

---

### 2. LikesPage
**Fichier**: `lib/features/pages/likes_page.dart`

**Modifications importantes**:
- ✅ Affiche les **photos de profil** au lieu des vidéos (économie de ressources)
- ✅ Utilise `photoUrlsFull` pour les URLs complètes
- ✅ Pas de VideoPlayerController (performances optimisées)

**Dépendances backend**:
- `getLikesReceived()` - Appel à `/video-likes/received`

**Action pour migration**:
- S'assurer que Appwrite retourne les données au même format

---

### 3. DatingHomePage
**Fichier**: `lib/features/pages/dating_home_page.dart`

**Modifications badges**:
- ✅ Badge Likes se remet à 0 quand on clique (index 1)
- ✅ Badge Matches se remet à 0 quand on clique (index 3)
- ✅ Pas de rechargement automatique qui réinitialise les badges

**Action pour migration**:
- Aucune - compatible Appwrite

---

### 4. UsersMapPage
**Fichier**: `lib/features/pages/users_map_page.dart`

**Modifications**:
- ✅ Carte en mode sombre (`dark_all` theme)
- ✅ Marqueurs colorés par genre (rose/bleu/violet)
- ✅ Utilise `getNearbyUsers()` avec paramètre `radiusKm`

**Dépendances backend**:
- `getNearbyUsers(latitude, longitude, radiusKm)` - **Nécessite implémentation Appwrite avec géolocalisation**

**Action pour migration**:
- Implémenter la recherche géolocalisée dans Appwrite (utiliser Appwrite Database Queries avec les attributs latitude/longitude)

---

## ⚠️ Points d'Attention pour la Migration

### 1. URLs des Médias
**Problème**: Les URLs photos/vidéos sont différentes entre local et Appwrite.

**Local**: `http://localhost:3000/uploads/photos/{fileId}`
**Appwrite**: URL Appwrite Storage

**Solution**: Le code utilise déjà `BackendService.getFileView()` qui délègue automatiquement.

**À faire**:
- Vérifier que `appwrite_service.getPhotoUrl()` et `getVideoUrl()` retournent les bonnes URLs Appwrite Storage

---

### 2. Likes de Vidéos
**Problème**: Nouvelle fonctionnalité pas encore implémentée côté Appwrite.

**À faire**:
1. Créer la collection `video_likes` dans Appwrite
2. Implémenter `likeVideo()` dans `appwrite_service.dart`
3. Implémenter `getLikedVideos()` dans `appwrite_service.dart`
4. Implémenter `getLikesReceived()` avec déduplication

---

### 3. Recherche Géolocalisée
**Problème**: `getNearbyUsers()` utilise calcul de distance.

**À faire**:
1. Ajouter des indexes sur `latitude` et `longitude` dans Appwrite
2. Implémenter la recherche avec Appwrite Queries
3. Option: Utiliser Appwrite Cloud Functions pour le calcul de distance

---

## 🚀 Procédure de Migration

### Étape 1: Préparation Appwrite
1. ✅ Vérifier que toutes les collections existent
2. ✅ Créer la collection `video_likes`
3. ✅ Configurer les indexes et permissions
4. ✅ Vérifier Appwrite Storage (buckets photos et vidéos)

### Étape 2: Code Flutter
1. ✅ Implémenter méthodes manquantes dans `appwrite_service.dart`
2. ✅ Tester chaque méthode individuellement
3. ✅ Changer `BackendConfig.USE_LOCAL_BACKEND = false`
4. ✅ Tester l'application complète

### Étape 3: Migration des Données
1. ⚠️ Exporter les données de `db.json`
2. ⚠️ Importer dans Appwrite (via script ou manuellement)
3. ⚠️ Migrer les fichiers uploads (photos et vidéos) vers Appwrite Storage

### Étape 4: Tests
1. ✅ Test d'authentification
2. ✅ Test de création de profil
3. ✅ Test d'upload photo/vidéo
4. ✅ Test de swipe et likes
5. ✅ Test de matches
6. ✅ Test de la carte géolocalisée

---

## 📝 Checklist Avant Migration

- [ ] Toutes les méthodes Appwrite implémentées
- [ ] Collection `video_likes` créée avec indexes
- [ ] Buckets Appwrite Storage configurés
- [ ] URLs des médias testées
- [ ] Recherche géolocalisée fonctionnelle
- [ ] Données migrées
- [ ] Tests complets réussis

---

## 🔗 Fichiers Clés à Modifier

1. `lib/core/config/backend_config.dart` - Activer Appwrite
2. `lib/core/services/appwrite_service.dart` - Implémenter méthodes manquantes
3. Appwrite Console - Créer collections et configurer permissions

---

## 💡 Recommandations

1. **Tester d'abord localement**: Garder `USE_LOCAL_BACKEND = true` pendant le développement
2. **Migration progressive**: Activer Appwrite page par page si possible
3. **Logging**: Ajouter des logs pour débugger les problèmes de migration
4. **Backup**: Sauvegarder `db.json` avant migration

---

**Date**: 2025-10-09
**Auteur**: Claude Code Assistant
**Version Backend Local**: Node.js + Express
**Version Cible**: Appwrite Cloud
