# Dating App 💕

Application de rencontres moderne avec vidéos courtes (style TikTok), développée avec Flutter Web.

## 🌟 Fonctionnalités Principales

- **Swipe de vidéos** - Interface TikTok-style pour découvrir des profils via des vidéos courtes
- **Système de matches** - Algorithme de matching mutuel avec chat intégré
- **Géolocalisation** - Carte interactive pour trouver des utilisateurs à proximité
- **Likes et Super Likes** - Système de likes avec animations fluides
- **Chat en temps réel** - Messagerie instantanée avec les matches
- **Profils complets** - Photos, vidéos, centres d'intérêt, préférences
- **Administration** - Dashboard admin pour modération de contenu
- **Plans d'abonnement** - FREE et PREMIUM avec quotas

## 🚀 Démarrage Rapide

### Prérequis

- Flutter SDK (≥ 3.0.0)
- Dart SDK (≥ 3.0.0)
- Compte Appwrite Cloud
- Compte Cloudinary (pour CDN vidéo)

### Installation

```bash
# Cloner le repository
git clone [url-du-repo]
cd dating_app

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run -d chrome
```

### Configuration

1. **Appwrite Cloud:**
   - Créer un projet sur [cloud.appwrite.io](https://cloud.appwrite.io)
   - Configurer les collections (users, videos, matches, messages, etc.)
   - Copier l'endpoint, project ID et database ID dans `lib/core/config/appwrite_config.dart`

2. **Cloudinary:**
   - Créer un compte sur [cloudinary.com](https://cloudinary.com)
   - Obtenir cloud name, API key et API secret
   - Configurer dans `lib/core/config/cloudinary_config.dart`

Voir [APPWRITE_SETUP.md](./APPWRITE_SETUP.md) et [DEPLOIEMENT_INSTRUCTIONS.md](./DEPLOIEMENT_INSTRUCTIONS.md) pour plus de détails.

## 📁 Structure du Projet

```
lib/
├── core/                    # Code partagé
│   ├── config/             # Configuration (Appwrite, Cloudinary, features flags)
│   ├── models/             # Modèles de données
│   ├── providers/          # State management (Riverpod)
│   ├── services/           # Logique métier et API
│   ├── utils/              # Utilitaires
│   └── widgets/            # Widgets réutilisables
│
├── features/               # Fonctionnalités
│   ├── admin/             # Module admin
│   ├── pages/             # Pages principales
│   └── widgets/           # Widgets spécifiques
│
└── main.dart              # Point d'entrée
```

Voir [ARCHITECTURE.md](./ARCHITECTURE.md) pour une description complète.

## 🛠️ Stack Technique

- **Framework:** Flutter Web
- **State Management:** Riverpod
- **Architecture:** MVC (Model-View-Controller)
- **Backend:** Appwrite Cloud (BaaS)
- **CDN:** Cloudinary
- **Base de données:** Appwrite Database (NoSQL)
- **Storage:** Cloudinary pour vidéos, Appwrite Storage pour photos
- **Real-time:** Appwrite Realtime pour notifications et chat

## 🎨 Fonctionnalités Détaillées

### Page Swipe
- Vidéos en autoplay avec lecteur custom HTML5
- Swipe gauche (dislike), droite (like), haut (voir profil)
- Animations fluides et particles de cœurs
- Préchargement intelligent des vidéos suivantes
- Compteurs de vues et likes en temps réel

### Page Likes
- Onglets "Reçus" et "Envoyés"
- Grilles responsive adaptées à la taille d'écran
- Chargement parallèle optimisé (~90% plus rapide)
- Animations d'apparition des cartes

### Page Matches
- Liste des matches avec derniers messages
- Indicateurs de messages non lus
- Accès direct au chat
- Chargement parallèle des profils

### Carte Interactive
- Zoom ajusté pour voir ~200km de rayon
- Clustering des marqueurs
- Panneau latéral avec liste des utilisateurs
- Animations fluides lors du chargement
- Filtrage par rayon dynamique

### Profils Utilisateurs
- Galerie de photos avec swipe
- Liste des vidéos
- Informations détaillées
- Swipe haut/bas pour fermer
- Options de signalement et blocage

## ⚡ Optimisations de Performance

### Chargement Parallèle
Les appels API sont parallélisés pour réduire les temps de chargement:
- **Avant:** 10-15 secondes
- **Après:** 1-2 secondes

```dart
// Chargement parallèle avec Future.wait()
final futures = users.map((u) => backend.getProfile(u.id));
final profiles = await Future.wait(futures);
```

### Pagination
- Chargement par batch de 20 vidéos
- Lazy loading au scroll
- Préchargement des 3 prochaines vidéos

### Préchargement Vidéo
- `preload='auto'` pour téléchargement anticipé
- Délai d'autoplay réduit à 50ms
- Compression client-side avec audio préservé

### Cache
- Images mises en cache avec `CachedNetworkImage`
- Données utilisateur cachées localement
- Offline support pour données critiques

## 🔐 Sécurité

- Authentification via Appwrite Account API
- Permissions au niveau document (Appwrite)
- Validation côté serveur pour uploads
- Modération admin pour contenu
- Signalement et blocage d'utilisateurs
- Rate limiting sur API

## 📱 Responsive Design

L'application s'adapte à 3 breakpoints:
- **Mobile** (< 600px): Interface verticale optimisée
- **Tablette** (600-900px): Layout avec panneaux latéraux
- **Desktop** (> 900px): Interface large avec colonnes

## 🧪 Tests

```bash
# Lancer tous les tests
flutter test

# Tests avec couverture
flutter test --coverage

# Analyse statique
flutter analyze

# Formatage
dart format lib/
```

## 📦 Build et Déploiement

### Build Web Production

```bash
flutter build web --release
```

Les fichiers sont générés dans `build/web/`

### Déploiement

Plusieurs options supportées:
- **Netlify** (recommandé)
- **Vercel**
- **Firebase Hosting**
- **Appwrite Sites**

Voir [DEPLOIEMENT_INSTRUCTIONS.md](./DEPLOIEMENT_INSTRUCTIONS.md) pour les étapes détaillées.

## 🤝 Contribution

Les contributions sont les bienvenues ! Veuillez consulter [CONTRIBUTING.md](./CONTRIBUTING.md) pour:
- Workflow de développement
- Standards de code
- Conventions de nommage
- Guidelines d'architecture
- Checklist avant PR

## 📚 Documentation

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Architecture détaillée du projet
- [CONTRIBUTING.md](./CONTRIBUTING.md) - Guide de contribution
- [APPWRITE_SETUP.md](./APPWRITE_SETUP.md) - Configuration Appwrite
- [DEPLOIEMENT_INSTRUCTIONS.md](./DEPLOIEMENT_INSTRUCTIONS.md) - Guide de déploiement
- [FEATURE_FLAGS.md](./FEATURE_FLAGS.md) - Feature toggles disponibles

## 📋 Roadmap

### ✅ Fait
- [x] Système de swipe vidéo
- [x] Matching et chat
- [x] Géolocalisation
- [x] Profils complets
- [x] Administration
- [x] Plans d'abonnement
- [x] Optimisations de performance
- [x] Animations fluides

### 🚧 En cours
- [ ] Tests unitaires et d'intégration
- [ ] PWA avec offline support
- [ ] Notifications push

### 📅 À venir
- [ ] Filtres de recherche avancés
- [ ] Stories (vidéos éphémères 24h)
- [ ] Appels vidéo
- [ ] Jeux brise-glace
- [ ] Badges de vérification

## 🐛 Bugs Connus

Aucun bug critique connu. Pour signaler un bug, ouvrir une issue sur GitHub.

## 📄 Licence

[À définir]

## 👥 Équipe

Développé avec ❤️ par [Votre Nom/Équipe]

## 🙏 Remerciements

- Flutter team pour le framework
- Appwrite pour le backend
- Cloudinary pour le CDN
- Communauté Flutter pour les packages

---

**Version:** 1.0.0
**Dernière mise à jour:** 2025-01-13

Pour toute question: [email de contact ou lien GitHub issues]
