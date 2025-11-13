# Architecture du Projet - Dating App

## Vue d'ensemble

Ce projet est une application de rencontres Flutter Web utilisant:
- **Architecture:** MVC (Model-View-Controller) avec Riverpod pour la gestion d'état
- **Backend:** Appwrite Cloud (BaaS)
- **CDN:** Cloudinary pour les vidéos
- **Base de données:** Appwrite Database (NoSQL)

## Structure des Dossiers

```
lib/
├── core/                           # Code partagé et infrastructure
│   ├── config/                     # Configuration de l'app
│   │   ├── appwrite_config.dart    # Config Appwrite Cloud
│   │   ├── cloudinary_config.dart  # Config Cloudinary CDN
│   │   ├── feature_flags.dart      # Feature toggles
│   │   └── subscription_features.dart
│   │
│   ├── models/                     # Modèles de données (Model)
│   │   ├── dating_user.dart        # Modèle utilisateur
│   │   ├── video_model.dart        # Modèle vidéo
│   │   ├── match_model.dart        # Modèle match
│   │   ├── chat_message_model.dart # Modèle message
│   │   └── ...
│   │
│   ├── providers/                  # State Management (Riverpod)
│   │   ├── auth_provider.dart      # État authentification
│   │   ├── likes_provider.dart     # État likes/matches
│   │   └── theme_provider.dart     # État thème
│   │
│   ├── services/                   # Services métier (Controller)
│   │   ├── backend_service.dart    # Service principal backend
│   │   ├── appwrite_service.dart   # API Appwrite
│   │   ├── cloudinary_service.dart # API Cloudinary
│   │   ├── compression_service.dart # Compression vidéo
│   │   └── ...
│   │
│   ├── utils/                      # Utilitaires
│   │   ├── page_transitions.dart   # Animations de navigation
│   │   └── responsive_helper.dart  # Helpers responsive
│   │
│   └── widgets/                    # Widgets réutilisables
│       ├── web_video_player.dart   # Lecteur vidéo custom
│       ├── shimmer_loading.dart    # Effet de chargement
│       └── subscription_badge.dart
│
├── features/                       # Fonctionnalités (View)
│   ├── admin/                      # Module admin
│   │   ├── admin_dashboard_page.dart
│   │   └── content_moderation_page.dart
│   │
│   ├── pages/                      # Pages principales
│   │   ├── swipe_page.dart         # Page swipe (TikTok-style)
│   │   ├── likes_page.dart         # Page likes reçus/envoyés
│   │   ├── matches_page.dart       # Page matches et chat
│   │   ├── dating_profile_page.dart # Page profil utilisateur
│   │   ├── users_map_page.dart     # Carte utilisateurs à proximité
│   │   └── ...
│   │
│   └── widgets/                    # Widgets spécifiques features
│       ├── modern_swipe_card.dart  # Carte swipe vidéo
│       ├── animated_like_card.dart # Carte like avec animation
│       ├── swipe_action_buttons.dart
│       └── ...
│
└── main.dart                       # Point d'entrée de l'app
```

## Architecture MVC avec Riverpod

### Model (Modèles de données)
**Localisation:** `lib/core/models/`

Classes immuables représentant les données métier:
- `DatingUser` - Utilisateur de l'app
- `VideoModel` - Vidéo uploadée
- `MatchModel` - Match entre 2 utilisateurs
- `ChatMessageModel` - Message de chat

**Exemple:**
```dart
class VideoModel {
  final String id;
  final String userId;
  final int views;
  final int likes;
  // ...

  VideoModel copyWith({int? views, int? likes}) {
    // Permet la mise à jour immutable
  }
}
```

### Controller (Services)
**Localisation:** `lib/core/services/`

Logique métier et communication avec le backend:

#### Services principaux:
- **`backend_service.dart`** - Facade principale, gère le routage vers Appwrite
- **`appwrite_service.dart`** - Communication directe avec Appwrite Cloud
- **`cloudinary_service.dart`** - Upload et gestion des vidéos

#### Services utilitaires:
- `compression_service.dart` - Compression vidéo client-side
- `usage_tracking_service.dart` - Suivi des quotas utilisateur
- `sound_service.dart` - Effets sonores

**Exemple:**
```dart
class BackendService {
  final AppwriteService _appwrite = AppwriteService();

  Future<List<VideoModel>> getVideosPaginated({
    required int limit,
    required int offset,
  }) async {
    final response = await _appwrite.getVideosPaginated(
      limit: limit,
      offset: offset,
    );
    // Traitement et retour
  }
}
```

### View (Pages et Widgets)
**Localisation:** `lib/features/pages/` et `lib/features/widgets/`

#### Pages principales:
- **SwipePage** - Page de swipe des vidéos (cœur de l'app)
- **LikesPage** - Gestion des likes reçus/envoyés
- **MatchesPage** - Liste des matches et accès au chat
- **DatingProfilePage** - Profil détaillé d'un utilisateur
- **UsersMapPage** - Carte interactive des utilisateurs

#### Widgets réutilisables:
- `ModernSwipeCard` - Carte vidéo swipeable
- `AnimatedLikeCard` - Carte de like avec animation
- `WebVideoPlayer` - Lecteur vidéo HTML5 optimisé

**Exemple:**
```dart
class SwipePage extends ConsumerStatefulWidget {
  @override
  ConsumerState<SwipePage> createState() => _SwipePageState();
}

class _SwipePageState extends ConsumerState<SwipePage> {
  final BackendService _backendService = BackendService();

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final videos = await _backendService.getVideosPaginated(...);
    setState(() => _videos = videos);
  }
}
```

## State Management avec Riverpod

### Providers actuels:

#### AuthProvider
**Fichier:** `lib/core/providers/auth_provider.dart`
**Rôle:** Gère l'état d'authentification de l'utilisateur

```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
```

#### LikesProvider
**Fichier:** `lib/core/providers/likes_provider.dart`
**Rôle:** Gère les compteurs de likes/matches en temps réel

#### ThemeProvider
**Fichier:** `lib/core/providers/theme_provider.dart`
**Rôle:** Gère le thème de l'application

### Migration future vers Riverpod (recommandé)

Pour améliorer la structure, il est recommandé de créer plus de providers:

```dart
// Exemple de structure recommandée
final videosProvider = StateNotifierProvider<VideosNotifier, VideosState>((ref) {
  return VideosNotifier(ref.read(backendServiceProvider));
});

final matchesProvider = StateNotifierProvider<MatchesNotifier, MatchesState>((ref) {
  return MatchesNotifier(ref.read(backendServiceProvider));
});
```

## Flux de Données

### Exemple: Liker une vidéo

```
1. USER ACTION (View)
   └─> SwipePage: onSwipeRight()

2. CONTROLLER (Service)
   └─> BackendService.likeVideo(videoId)
       └─> AppwriteService.createDocument(...)

3. BACKEND (Appwrite Cloud)
   └─> Crée document dans collection "videoLikes"
   └─> Met à jour compteur "likes" dans "videos"
   └─> Vérifie si match mutuel

4. RESPONSE
   └─> {'success': true, 'totalLikes': 42, 'isMatch': true}

5. UPDATE STATE (View)
   └─> setState() met à jour l'UI
   └─> Affiche dialog si match
```

## Conventions de Nommage

### Fichiers
- Pages: `*_page.dart` (ex: `swipe_page.dart`)
- Widgets: `*_widget.dart` ou descriptif (ex: `modern_swipe_card.dart`)
- Modèles: `*_model.dart` (ex: `video_model.dart`)
- Services: `*_service.dart` (ex: `backend_service.dart`)
- Providers: `*_provider.dart` (ex: `auth_provider.dart`)

### Classes
- PascalCase: `DatingUser`, `VideoModel`, `BackendService`
- Suffixes:
  - Pages: `*Page` (ex: `SwipePage`)
  - Services: `*Service` (ex: `BackendService`)
  - Models: pas de suffixe (ex: `DatingUser`)

### Variables et fonctions
- camelCase: `currentUser`, `loadVideos()`
- Privées: `_currentUser`, `_loadVideos()`
- Constantes: `kDefaultRadius`, `kMaxVideoSize`

## Backend (Appwrite Cloud)

### Collections principales:

#### users
Stocke les profils utilisateurs
- Attributs: name, age, gender, bio, photoUrls, videoIds, latitude, longitude, etc.
- Index: userId, gender, age

#### videos
Stocke les métadonnées des vidéos
- Attributs: userId, fileId (URL Cloudinary), title, description, views, likes, isApproved
- Les fichiers vidéo sont sur Cloudinary CDN

#### videoLikes
Table de jonction pour les likes de vidéos
- Attributs: userId, videoId
- Utilisé pour détecter les matches

#### matches
Stocke les matches entre utilisateurs
- Attributs: user1Id, user2Id, isActive, lastMessageAt

#### messages
Stocke les messages de chat
- Attributs: matchId, senderId, content, type, createdAt

## Performances et Optimisations

### Chargement parallèle
Les appels API sont parallélisés avec `Future.wait()`:

```dart
// ❌ Séquentiel (lent)
for (var user in users) {
  final profile = await backend.getUserProfile(user.id);
}

// ✅ Parallèle (rapide)
final futures = users.map((user) => backend.getUserProfile(user.id));
final profiles = await Future.wait(futures);
```

### Pagination
Les vidéos sont chargées par batch de 20:

```dart
await backend.getVideosPaginated(
  limit: 20,
  offset: currentPage * 20,
);
```

### Préchargement
Les vidéos utilisent `preload='auto'` pour un chargement anticipé.

### Cache
Les images utilisent `CachedNetworkImage` pour éviter les rechargements.

## Tests

### Structure (à créer)
```
test/
├── unit/              # Tests unitaires des services
├── widget/            # Tests de widgets
└── integration/       # Tests end-to-end
```

### Commandes
```bash
# Lancer tous les tests
flutter test

# Tests avec couverture
flutter test --coverage

# Tests d'un fichier spécifique
flutter test test/unit/backend_service_test.dart
```

## Déploiement

### Web
```bash
# Build production
flutter build web --release

# Deploy sur Netlify/Vercel
# Les fichiers sont dans build/web/
```

### Configuration requise
- **Appwrite Cloud:** Endpoint, Project ID, Database ID
- **Cloudinary:** Cloud name, API key, API secret
- Voir `lib/core/config/` pour les configurations

## Contribuer

### Workflow
1. Créer une branche feature: `git checkout -b feature/nom-feature`
2. Développer en suivant l'architecture MVC
3. Tester localement
4. Commit avec message descriptif
5. Push et créer une Pull Request

### Standards de code
- Suivre les conventions Dart/Flutter
- Utiliser `dart format` avant commit
- Commenter le code complexe
- Respecter l'architecture MVC/Riverpod

## Ressources

- [Documentation Flutter](https://flutter.dev/docs)
- [Documentation Riverpod](https://riverpod.dev)
- [Documentation Appwrite](https://appwrite.io/docs)
- [Documentation Cloudinary](https://cloudinary.com/documentation)

---

**Version:** 1.0
**Dernière mise à jour:** 2025-01-13
