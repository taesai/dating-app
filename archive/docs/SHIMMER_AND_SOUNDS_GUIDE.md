# Guide des Shimmer Effects et Effets Sonores

## 🎨 Shimmer Effects

Les shimmer effects ajoutent des animations de chargement élégantes pour améliorer l'UX pendant les temps d'attente.

### 📦 Widgets Disponibles

#### 1. ShimmerWidget (Base)
Widget de base pour créer n'importe quel effet shimmer personnalisé.

```dart
ShimmerWidget(
  child: Container(
    width: 200,
    height: 20,
    color: Colors.grey[300],
  ),
)
```

#### 2. ProfileShimmer
Skeleton loader pour les pages de profil.

```dart
// Utilisation simple
if (isLoading) {
  return ProfileShimmer();
} else {
  return UserProfileWidget(user: user);
}
```

#### 3. CardShimmer
Skeleton loader pour les cartes de swipe.

```dart
// Dans swipe_page.dart
if (isLoading) {
  return CardShimmer();
} else {
  return UserCard(user: user);
}
```

#### 4. MessageListShimmer
Skeleton loader pour liste de messages.

```dart
// Dans chat_page.dart
if (_isLoading) {
  return MessageListShimmer(itemCount: 5);
} else {
  return ListView.builder(...);
}
```

#### 5. MatchListShimmer
Skeleton loader pour grille de matchs.

```dart
// Dans matches_page.dart
if (_isLoading) {
  return MatchListShimmer(itemCount: 6);
} else {
  return GridView.builder(...);
}
```

#### 6. ListTileShimmer
Skeleton loader générique pour listes.

```dart
// Pour n'importe quelle liste
if (isLoading) {
  return ListTileShimmer(itemCount: 5);
}
```

#### 7. NetworkImageWithShimmer
Image réseau avec shimmer pendant le chargement.

```dart
NetworkImageWithShimmer(
  imageUrl: user.photoUrls[0],
  width: 120,
  height: 120,
  borderRadius: BorderRadius.circular(60),
)
```

### 🎯 Exemples d'Intégration

#### Dans SwipePage
```dart
class _SwipePageState extends State<SwipePage> {
  bool _isLoading = true;
  List<DatingUser> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final users = await _backend.getNearbyUsers(...);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CardShimmer(); // Affiche le shimmer
    }

    return SwipeCards(users: _users);
  }
}
```

#### Dans ChatPage
```dart
Widget _buildMessageList() {
  if (_isLoading) {
    return MessageListShimmer(itemCount: 5);
  }

  return ListView.builder(
    itemCount: _messages.length,
    itemBuilder: (context, index) {
      return MessageBubble(message: _messages[index]);
    },
  );
}
```

#### Dans ProfilePage
```dart
FutureBuilder<DatingUser>(
  future: _loadUserProfile(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return ProfileShimmer();
    }

    if (snapshot.hasError) {
      return ErrorWidget(error: snapshot.error);
    }

    return UserProfile(user: snapshot.data!);
  },
)
```

### 🎨 Personnalisation

```dart
// Changer les couleurs
ShimmerWidget(
  baseColor: Colors.blue[300],
  highlightColor: Colors.blue[100],
  child: YourWidget(),
)

// Changer la durée
ShimmerWidget(
  duration: Duration(milliseconds: 2000),
  child: YourWidget(),
)

// Désactiver temporairement
ShimmerWidget(
  enabled: false, // Pas de shimmer
  child: YourWidget(),
)
```

---

## 🔊 Effets Sonores

Les effets sonores ajoutent du feedback audio pour améliorer l'engagement et l'expérience utilisateur.

### 🎵 Sons Disponibles

| Son | Méthode | Usage |
|-----|---------|-------|
| Swipe Right (Like) | `playSwipeRight()` | Quand l'utilisateur like |
| Swipe Left (Pass) | `playSwipeLeft()` | Quand l'utilisateur passe |
| Match | `playMatch()` | Nouveau match détecté |
| Super Like | `playSuperLike()` | Super like envoyé |
| Message envoyé | `playMessageSent()` | Message envoyé dans le chat |
| Message reçu | `playMessageReceived()` | Nouveau message reçu |
| Notification | `playNotification()` | Notification générale |
| Tap/Clic | `playTap()` | Clic sur bouton |
| Succès | `playSuccess()` | Action réussie |
| Erreur | `playError()` | Erreur survenue |
| Whoosh | `playWhoosh()` | Transition de page |

### 📝 Utilisation

#### 1. Initialiser le service (main.dart)
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le service de sons
  await SoundService().init();

  runApp(MyApp());
}
```

#### 2. Utiliser dans les widgets

**Méthode 1: Appel direct**
```dart
import '../../core/services/sound_service.dart';

class MyWidget extends StatelessWidget {
  final SoundService _soundService = SoundService();

  void _handleLike() {
    _soundService.playSwipeRight();
    // ... logique de like
  }
}
```

**Méthode 2: Avec le Mixin**
```dart
import '../../core/services/sound_service.dart';

class _MyPageState extends State<MyPage> with SoundMixin {
  void _handleMatch() {
    playMatch(); // Utilise le mixin
    // ... logique de match
  }
}
```

**Méthode 3: SoundButton widget**
```dart
SoundButton(
  soundType: 'tap',
  onPressed: () {
    // Action du bouton
  },
  child: ElevatedButton(
    child: Text('Cliquer'),
  ),
)
```

### 🎯 Exemples d'Intégration

#### Dans SwipePage (Likes/Pass)
```dart
class _SwipePageState extends State<SwipePage> with SoundMixin {
  void _handleSwipe(int index, SwipeDirection direction) {
    if (direction == SwipeDirection.right) {
      playSwipeRight(); // Son de like
      _likeUser(users[index]);
    } else if (direction == SwipeDirection.left) {
      playSwipeLeft(); // Son de pass
    } else if (direction == SwipeDirection.up) {
      playSuperLike(); // Son de super like
      _superLikeUser(users[index]);
    }
  }
}
```

#### Dans ChatPage (Messages)
```dart
class _ChatPageState extends State<ChatPage> with SoundMixin {
  Future<void> _sendMessage(String message) async {
    // Envoyer le message
    await _backend.sendMessage(...);

    // Jouer le son
    playMessageSent();

    // Mettre à jour l'UI
    setState(() {
      _messages.add(newMessage);
    });
  }

  @override
  void initState() {
    super.initState();

    // Écouter les nouveaux messages
    _subscribeToMessages();
  }

  void _onNewMessageReceived(ChatMessage message) {
    playMessageReceived(); // Son de réception

    setState(() {
      _messages.add(message);
    });
  }
}
```

#### Dans MatchDialog (Nouveau match)
```dart
void _showMatchDialog(DatingUser matchedUser) {
  // Jouer le son de match
  SoundService().playMatch();

  showDialog(
    context: context,
    builder: (context) => MatchDialog(user: matchedUser),
  );
}
```

#### Dans Notifications
```dart
void _showNotification(String title, String body) {
  SoundService().playNotification();

  // Afficher la notification
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(body)),
  );
}
```

### ⚙️ Page de Paramètres

Ajouter la page de configuration des sons dans les paramètres utilisateur :

```dart
// Dans settings_page.dart ou edit_profile_page.dart
import 'package:dating_app/features/pages/sound_settings_page.dart';

// Ajouter dans la liste
ListTile(
  leading: Icon(Icons.volume_up),
  title: Text('Effets sonores'),
  subtitle: Text('Gérer les sons de l\'application'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SoundSettingsPage(),
      ),
    );
  },
)

// OU utiliser le widget compact
SoundToggleWidget(), // Switch direct dans les paramètres
```

### 🎛️ Contrôler les Sons

```dart
final soundService = SoundService();

// Activer/désactiver
await soundService.setSoundsEnabled(false);

// Changer le volume (0.0 à 1.0)
await soundService.setVolume(0.7);

// Vérifier l'état
bool isEnabled = soundService.soundsEnabled;
double currentVolume = soundService.volume;
```

### 💾 Persistance

Les préférences sont automatiquement sauvegardées dans localStorage :
- État activé/désactivé
- Niveau de volume

Les préférences sont restaurées au prochain lancement.

---

## 🎬 Combinaison Shimmer + Sons

Exemple complet d'une page avec shimmer ET sons :

```dart
class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SoundMixin {
  bool _isLoading = true;
  DatingUser? _user;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = await _backend.getUserProfile(widget.userId);

      setState(() {
        _user = user;
        _isLoading = false;
      });

      playSuccess(); // Son de succès

    } catch (e) {
      setState(() => _isLoading = false);
      playError(); // Son d'erreur
    }
  }

  void _handleLike() {
    playSwipeRight(); // Son
    _likeUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profil')),
      body: _isLoading
          ? ProfileShimmer() // Shimmer pendant chargement
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Photo avec shimmer
                  NetworkImageWithShimmer(
                    imageUrl: _user!.photoUrls[0],
                    width: double.infinity,
                    height: 400,
                  ),

                  // Infos
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(_user!.name),
                        Text(_user!.bio),

                        // Bouton avec son
                        SoundButton(
                          soundType: 'success',
                          onPressed: _handleLike,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.favorite),
                            label: Text('Liker'),
                            onPressed: null, // Géré par SoundButton
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
```

---

## 📱 Bonnes Pratiques

### Pour les Shimmers
1. ✅ Utilisez toujours un shimmer pendant les chargements de données
2. ✅ Adaptez la forme du shimmer au contenu final
3. ✅ Gardez les dimensions cohérentes
4. ✅ Utilisez les widgets prédéfinis quand possible
5. ❌ N'abusez pas des shimmers pour des actions instantanées

### Pour les Sons
1. ✅ Utilisez des sons subtils et courts
2. ✅ Respectez le choix de l'utilisateur (activé/désactivé)
3. ✅ Associez chaque action importante à un son
4. ✅ Testez le volume par défaut (0.5 = 50%)
5. ❌ N'ajoutez pas de son sur CHAQUE interaction
6. ❌ Évitez les sons trop longs ou répétitifs

### Performances
- Les shimmers utilisent des animations légères
- Les sons sont chargés à la demande
- Les préférences sont en cache
- Pas d'impact significatif sur les performances

---

## 🔧 Dépannage

### Les shimmers ne s'affichent pas
```dart
// Vérifiez que le widget parent a des dimensions
Container(
  width: 200,  // ← Important
  height: 100, // ← Important
  child: ShimmerWidget(...),
)
```

### Les sons ne jouent pas
```dart
// 1. Vérifiez l'initialisation
await SoundService().init();

// 2. Vérifiez que les sons sont activés
print(SoundService().soundsEnabled);

// 3. Vérifiez le volume
print(SoundService().volume);

// 4. Testez directement
await SoundService().playTap();
```

### Conflits audio (Web)
Les navigateurs peuvent bloquer l'autoplay audio. Solution :
1. Le premier son ne joue qu'après interaction utilisateur
2. Les sons suivants fonctionneront normalement
3. C'est une limitation du navigateur, pas du code

---

## 📚 Résumé

### Shimmer Effects
- ✅ 8 widgets prédéfinis
- ✅ Personnalisables (couleurs, durée)
- ✅ Adaptatif clair/sombre
- ✅ Facile à intégrer

### Effets Sonores
- ✅ 11 sons différents
- ✅ Contrôle activation/volume
- ✅ Persistance des préférences
- ✅ Page de paramètres incluse
- ✅ 3 façons d'utiliser (direct, mixin, widget)

**Résultat** : Une expérience utilisateur moderne, engageante et professionnelle ! 🎉
