# Guide de Contribution

## Bienvenue !

Merci de contribuer à ce projet. Ce guide vous aidera à maintenir la cohérence et la qualité du code.

## Structure du Projet

Consultez [ARCHITECTURE.md](./ARCHITECTURE.md) pour comprendre:
- L'architecture MVC avec Riverpod
- L'organisation des dossiers
- Les flux de données
- Les conventions de nommage

## Workflow de Développement

### 1. Configuration de l'environnement

```bash
# Cloner le repo
git clone [url-du-repo]
cd dating_app

# Installer les dépendances
flutter pub get

# Lancer l'app en mode dev
flutter run -d chrome
```

### 2. Créer une branche feature

```bash
# Depuis main
git checkout main
git pull origin main

# Créer la branche
git checkout -b feature/nom-descriptif
# Exemples:
# - feature/add-video-filters
# - fix/match-notification-bug
# - refactor/optimize-likes-loading
```

### 3. Développer la feature

#### Règles générales:
- **Suivre l'architecture MVC**
  - Models dans `lib/core/models/`
  - Controllers (services) dans `lib/core/services/`
  - Views (pages/widgets) dans `lib/features/`

- **Utiliser Riverpod pour l'état partagé**
  - Créer des providers dans `lib/core/providers/`
  - Éviter `setState()` pour l'état global

- **Optimiser les performances**
  - Paralléliser les appels API avec `Future.wait()`
  - Utiliser la pagination pour les listes
  - Implémenter le lazy loading

#### Exemple: Ajouter une nouvelle page

```dart
// 1. Créer le fichier dans lib/features/pages/
// lib/features/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          // Contenu
        ],
      ),
    );
  }
}
```

#### Exemple: Ajouter un nouveau service

```dart
// 1. Créer le fichier dans lib/core/services/
// lib/core/services/notification_service.dart

class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> sendNotification(String userId, String message) async {
    // Logique métier
  }
}

// 2. Créer un provider si nécessaire
// lib/core/providers/notification_provider.dart

final notificationProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
```

### 4. Tester localement

```bash
# Lancer l'app
flutter run -d chrome

# Vérifier le formatage
dart format lib/

# Analyser le code
flutter analyze

# Lancer les tests (si présents)
flutter test
```

### 5. Commiter les changements

#### Convention de messages:

```
<type>(<scope>): <description courte>

<description détaillée optionnelle>

<footer optionnel>
```

**Types:**
- `feat`: Nouvelle fonctionnalité
- `fix`: Correction de bug
- `refactor`: Refactoring sans changement de fonctionnalité
- `perf`: Amélioration de performance
- `docs`: Modification de documentation
- `style`: Formatage, points-virgules manquants, etc.
- `test`: Ajout ou modification de tests
- `chore`: Maintenance (dépendances, config, etc.)

**Exemples:**

```bash
git add lib/features/pages/settings_page.dart
git commit -m "feat(settings): Add settings page with theme toggle

- Add SettingsPage with dark/light theme switch
- Integrate with ThemeProvider
- Add navigation from profile menu"

# OU plus simple:
git commit -m "feat: Add settings page"
```

### 6. Pousser et créer une Pull Request

```bash
# Pousser la branche
git push origin feature/nom-descriptif

# Créer la PR sur GitHub
# Décrire les changements, ajouter des screenshots si UI
```

## Standards de Code

### Formatage

```bash
# Formatter tout le projet
dart format lib/

# Formatter un fichier
dart format lib/features/pages/settings_page.dart
```

### Nommage

#### Fichiers et dossiers
- `snake_case` pour les fichiers: `settings_page.dart`, `notification_service.dart`
- Suffixes:
  - `*_page.dart` pour les pages
  - `*_widget.dart` pour les widgets réutilisables
  - `*_model.dart` pour les modèles
  - `*_service.dart` pour les services
  - `*_provider.dart` pour les providers Riverpod

#### Classes et enums
- `PascalCase`: `SettingsPage`, `NotificationService`, `UserRole`

#### Variables et fonctions
- `camelCase`: `userName`, `loadSettings()`
- Privées avec `_`: `_currentUser`, `_loadData()`
- Constantes: `kDefaultRadius`, `kMaxFileSize`

#### Booléens
- Préfixer avec `is`, `has`, `should`: `isLoading`, `hasError`, `shouldRefresh`

### Commentaires

```dart
// ✅ Bon: Explique le "pourquoi"
// Attendre 300ms pour que le lecteur vidéo s'initialise complètement
await Future.delayed(const Duration(milliseconds: 300));

// ❌ Mauvais: Répète le code
// Attendre 300 millisecondes
await Future.delayed(const Duration(milliseconds: 300));

/// ✅ Documentation de classe/fonction
/// Service pour gérer les notifications push.
///
/// Utilise Firebase Cloud Messaging pour envoyer des notifications
/// aux utilisateurs en temps réel.
class NotificationService {
  // ...
}
```

### Gestion des erreurs

```dart
// ✅ Bon: Gestion explicite avec logs
try {
  final user = await _backend.getUserProfile(userId);
  return user;
} catch (e) {
  print('❌ Erreur chargement profil $userId: $e');
  // Option 1: Retourner une valeur par défaut
  return null;
  // Option 2: Relancer l'erreur
  // rethrow;
}

// ❌ Mauvais: Silencieux
try {
  final user = await _backend.getUserProfile(userId);
  return user;
} catch (e) {
  return null; // Pas de log, impossible de débugger
}
```

### Performances

#### Paralléliser les appels API

```dart
// ❌ Séquentiel: ~5 secondes
for (var user in users) {
  final profile = await backend.getProfile(user.id);
  profiles.add(profile);
}

// ✅ Parallèle: ~0.5 seconde
final futures = users.map((u) => backend.getProfile(u.id));
final profiles = await Future.wait(futures);
```

#### Utiliser const

```dart
// ✅ Widgets constants
const SizedBox(height: 16),
const Icon(Icons.favorite),

// ❌ Non-constants inutiles
SizedBox(height: 16), // Recréé à chaque build
Icon(Icons.favorite),
```

#### Éviter les rebuilds inutiles

```dart
// ✅ Séparer les parties statiques
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _StaticHeader(), // Ne rebuild jamais
        _DynamicContent(),      // Rebuild quand nécessaire
      ],
    );
  }
}

// ❌ Tout rebuild ensemble
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),  // Rebuild même si statique
        _buildContent(), // Rebuild nécessaire
      ],
    );
  }
}
```

## Debugging

### Logs utiles

```dart
// Utiliser des emojis pour identifier rapidement
print('🚀 Initialisation de la page');
print('📥 Chargement de ${users.length} utilisateurs');
print('✅ Chargement terminé');
print('❌ Erreur: $e');
print('⚠️ Attention: vidéo introuvable');
print('🔍 Debug: $_currentIndex');
```

### DevTools Flutter

```bash
# Ouvrir DevTools
flutter run -d chrome --dart-define=DEBUG_MODE=true

# Inspector: Inspecter le widget tree
# Performance: Analyser les performances
# Network: Voir les requêtes API
```

## Checklist avant PR

- [ ] Code formaté (`dart format lib/`)
- [ ] Aucune erreur d'analyse (`flutter analyze`)
- [ ] Tests passent (`flutter test`)
- [ ] Documentation ajoutée si nécessaire
- [ ] Logs de debug retirés ou commentés
- [ ] Screenshots ajoutés si changement UI
- [ ] Branch à jour avec `main`

## Architecture Guidelines

### Quand créer un Provider?

✅ **Créer un provider pour:**
- État partagé entre plusieurs pages
- Données nécessitant des mises à jour réactives
- Cache de données API
- Configuration globale

❌ **NE PAS créer de provider pour:**
- État local à une seule page → utiliser `setState()`
- Données temporaires
- UI state simple (scroll position, tab index, etc.)

### Quand créer un Service?

✅ **Créer un service pour:**
- Communication avec une API
- Logique métier complexe
- Fonctionnalités réutilisables

❌ **NE PAS créer de service pour:**
- Logique UI simple
- Formatage de texte
- Calculs simples

### Quand créer un Widget?

✅ **Créer un widget réutilisable pour:**
- Code UI dupliqué (utilisé 2+ fois)
- Composant avec logique propre
- Améliorer la lisibilité

❌ **Ne PAS créer de widget pour:**
- Code utilisé une seule fois
- Micro-optimisation prématurée

## Questions Fréquentes

### Comment ajouter une nouvelle collection Appwrite?

1. Créer la collection dans Appwrite Console
2. Définir les attributs et index
3. Créer le modèle dans `lib/core/models/`
4. Ajouter les méthodes CRUD dans `AppwriteService`
5. Exposer via `BackendService`

### Comment optimiser le chargement d'une liste?

```dart
// 1. Pagination
final videos = await backend.getVideosPaginated(
  limit: 20,
  offset: page * 20,
);

// 2. Lazy loading
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    // Charger plus quand on arrive à la fin
    if (index == items.length - 3) {
      _loadMore();
    }
    return ItemWidget(items[index]);
  },
);

// 3. Chargement parallèle
final futures = items.map((item) => loadDetails(item));
await Future.wait(futures);
```

### Comment débugger un problème de performance?

1. **Identifier:** Utiliser DevTools → Performance
2. **Mesurer:** Ajouter des logs avec timestamps
3. **Analyser:** Chercher les appels séquentiels
4. **Optimiser:** Paralléliser avec `Future.wait()`
5. **Vérifier:** Re-mesurer après optimisation

## Ressources

- [Architecture du projet](./ARCHITECTURE.md)
- [Documentation Flutter](https://flutter.dev/docs)
- [Guide Riverpod](https://riverpod.dev/docs/introduction/getting_started)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)

## Contact

Pour toute question, ouvrir une issue sur GitHub ou contacter l'équipe de développement.

---

Merci de contribuer ! 🚀
