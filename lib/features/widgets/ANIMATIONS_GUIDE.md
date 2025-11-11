# Guide d'utilisation des animations améliorées

Ce guide explique comment utiliser les nouveaux widgets d'animation dans votre application de rencontre.

## 📦 Import

```dart
import 'package:dating_app/features/widgets/animations_export.dart';
```

## 🎨 Widgets disponibles

### 1. Animations de particules de cœurs (`heart_particles_animation.dart`)

#### HeartParticlesAnimation
Animation explosive de particules en forme de cœurs.

```dart
HeartParticlesAnimation(
  color: Colors.pink,
  onComplete: () {
    print('Animation terminée!');
  },
)
```

#### AnimatedLikeButton
Bouton de like avec explosion de particules au clic.

```dart
AnimatedLikeButton(
  onTap: () => print('Like!'),
  isLiked: false,
  likesCount: 42,
  size: 60,
)
```

### 2. Dialog de match spectaculaire (`match_animation_dialog.dart`)

Dialog moderne avec effet glassmorphism, cœurs flottants et animations fluides.

```dart
showDialog(
  context: context,
  builder: (context) => MatchAnimationDialog(
    user: matchedUser,
    onContinue: () => Navigator.pop(context),
    onMessage: () {
      Navigator.pop(context);
      // Naviguer vers le chat
    },
  ),
);
```

**Fonctionnalités :**
- Effet glassmorphism avec blur
- Cœurs flottants en arrière-plan
- Animation de glow pulsant sur l'icône
- Boutons avec micro-interactions

### 3. Transitions de page (`page_transitions.dart`)

#### FadeSlidePageRoute
Transition avec fade et slide.

```dart
Navigator.push(
  context,
  FadeSlidePageRoute(page: ProfilePage()),
);
```

#### ScalePageRoute
Transition avec scale et fade.

```dart
Navigator.push(
  context,
  ScalePageRoute(page: SettingsPage()),
);
```

#### GlassmorphismPageRoute
Transition moderne avec effet de blur.

```dart
Navigator.push(
  context,
  GlassmorphismPageRoute(page: DetailPage()),
);
```

#### BottomSheetPageRoute
Transition style bottom sheet.

```dart
Navigator.push(
  context,
  BottomSheetPageRoute(page: FilterPage()),
);
```

### 4. Boutons de swipe améliorés (`enhanced_swipe_buttons.dart`)

#### EnhancedSwipeButtons
Ensemble de boutons avec animations et micro-interactions.

```dart
EnhancedSwipeButtons(
  onDislike: () => print('Dislike'),
  onSuperLike: () => print('Super Like'),
  onLike: () => print('Like'),
  isLikeDisabled: false,
)
```

**Animations incluses :**
- Scale animation au tap
- Pulse animation continue
- Ripple effect
- Shine effect
- Shadow dynamique

#### CompactActionButton
Bouton d'action compact pour les fonctionnalités secondaires.

```dart
CompactActionButton(
  icon: Icons.block,
  label: 'Bloquer',
  color: Colors.red,
  onTap: () => print('Bloqué'),
)
```

### 5. Feedback visuel de swipe (`swipe_feedback_overlay.dart`)

#### SwipeFeedbackOverlay
Overlay qui s'affiche pendant le swipe pour donner un retour visuel.

```dart
SwipeFeedbackOverlay(
  swipeProgress: 0.7, // 0.0 à 1.0
  direction: SwipeDirection.right,
)
```

#### SwipeableCardWithFeedback
Carte swipeable avec feedback intégré.

```dart
SwipeableCardWithFeedback(
  threshold: 100,
  onSwipeLeft: () => print('Nope'),
  onSwipeRight: () => print('Like'),
  onSwipeUp: () => print('Super Like'),
  child: UserProfileCard(user: user),
)
```

**Fonctionnalités :**
- Gradient de couleur selon la direction
- Particules animées
- Rotation de la carte
- Label animé (LIKE/NOPE/SUPER LIKE)
- Reset automatique avec animation élastique

### 6. Shimmer Loading (`shimmer_loading.dart`)

#### ShimmerLoading
Widget générique de shimmer loading.

```dart
ShimmerLoading(
  isLoading: true,
  child: Container(
    width: 200,
    height: 100,
    color: Colors.grey,
  ),
)
```

#### Widgets pré-configurés :

```dart
// Skeleton de carte de profil
ProfileCardSkeleton()

// Liste de skeletons
ProfileCardListSkeleton(count: 5)

// Grille de skeletons
LikesGridSkeleton(count: 6)

// Liste de chats skeleton
ChatListSkeleton(count: 5)

// Texte skeleton
TextSkeleton(width: 150, height: 20)

// Avatar skeleton
CircleSkeleton(size: 60)
```

## 🎯 Exemples d'intégration

### Remplacer le dialog de match dans swipe_page.dart

```dart
// Ancien code
void _showMatchDialog(DatingUser user) {
  showDialog(
    context: context,
    builder: (context) => Dialog(/* ... */),
  );
}

// Nouveau code
void _showMatchDialog(DatingUser user) {
  showDialog(
    context: context,
    builder: (context) => MatchAnimationDialog(
      user: user,
      onContinue: () => Navigator.pop(context),
      onMessage: () {
        Navigator.pop(context);
        // Navigation vers le chat
      },
    ),
  );
}
```

### Améliorer les transitions de navigation

```dart
// Au lieu de
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ProfilePage()),
);

// Utiliser
Navigator.push(
  context,
  GlassmorphismPageRoute(page: ProfilePage()),
);
```

### Ajouter le shimmer loading

```dart
// Dans vos pages avec chargement
Widget build(BuildContext context) {
  if (_isLoading) {
    return ProfileCardListSkeleton(count: 3);
  }

  return ListView.builder(/* vos cartes */);
}
```

## 🎨 Personnalisation

Tous les widgets supportent la personnalisation des couleurs, durées et comportements :

```dart
// Personnaliser les couleurs
HeartParticlesAnimation(
  color: Colors.purple, // Votre couleur
)

// Personnaliser la durée
FadeSlidePageRoute(
  page: MyPage(),
  duration: Duration(milliseconds: 600),
)

// Personnaliser les tailles
AnimatedLikeButton(
  size: 80, // Taille personnalisée
)
```

## 📱 Performance Web

Tous ces widgets sont optimisés pour le web :
- Utilisation de `AnimationController` avec `vsync`
- Gestion correcte du `dispose()`
- Animations GPU-accelerated quand possible
- Pas d'animations lourdes en continu

## 🔧 Tips

1. **Évitez trop d'animations simultanées** : Limitez le nombre d'animations actives en même temps
2. **Utilisez `mounted` avant `setState`** : Toujours vérifier que le widget est monté
3. **Disposez les contrôleurs** : Tous les `AnimationController` sont correctement disposés
4. **Testez sur différents navigateurs** : Certaines animations peuvent varier légèrement

## 🚀 Prochaines étapes

Pour aller plus loin, vous pouvez :
- Créer des animations de confetti pour les événements spéciaux
- Ajouter des animations de typing indicator dans le chat
- Implémenter des micro-interactions sur d'autres boutons
- Créer des transitions personnalisées pour vos besoins spécifiques
