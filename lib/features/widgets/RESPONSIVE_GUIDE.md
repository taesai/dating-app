# Guide Responsive Design - Animations

Ce guide explique comment les widgets d'animation s'adaptent automatiquement à toutes les dimensions d'écran.

## 📐 Breakpoints

L'application utilise les breakpoints standards suivants (définis dans `responsive_helper.dart`) :

| Device    | Largeur                    | Breakpoint        |
|-----------|----------------------------|-------------------|
| **Mobile**  | < 600px                  | `mobileBreakpoint` |
| **Tablet**  | 600px - 1200px           | `tabletBreakpoint` |
| **Desktop** | >= 1200px                | `desktopBreakpoint` |

## 🎯 Widgets adaptés au responsive

### 1. MatchAnimationDialog

Le dialog de match s'adapte automatiquement :

#### Dimensions
- **Mobile** : 90% de la largeur d'écran
- **Tablet** : 500px de largeur
- **Desktop** : 600px de largeur

#### Tailles de texte
```dart
// Titre "C'est un Match !"
Mobile  : 32px
Tablet  : 42px
Desktop : 52px

// Message
Mobile  : 16px
Tablet  : 18px
Desktop : 20px
```

#### Icône de cœur
```dart
Mobile  : 80px
Tablet  : 100px
Desktop : 120px
```

#### Padding
```dart
Mobile  : 16px
Tablet  : 24px
Desktop : 32px
```

**Code :**
```dart
showDialog(
  context: context,
  builder: (context) => MatchAnimationDialog(
    user: user,
    onContinue: () => Navigator.pop(context),
    onMessage: () => Navigator.pop(context),
  ),
);
// S'adapte automatiquement à la taille de l'écran !
```

### 2. EnhancedSwipeButtons

Les boutons de swipe s'adaptent à la taille d'écran :

#### Taille du bouton Dislike
```dart
Mobile  : 55px
Tablet  : 65px
Desktop : 70px
```

#### Taille du bouton Super Like
```dart
Mobile  : 50px
Tablet  : 60px
Desktop : 65px
```

#### Taille du bouton Like (principal)
```dart
Mobile  : 65px
Tablet  : 75px
Desktop : 85px
```

#### Espacement entre boutons
```dart
Mobile  : 16px
Desktop : 24px
```

**Code :**
```dart
EnhancedSwipeButtons(
  onDislike: () => print('Dislike'),
  onSuperLike: () => print('Super Like'),
  onLike: () => print('Like'),
)
// Les tailles s'ajustent automatiquement !
```

### 3. ShimmerLoading

Les skeletons de chargement utilisent des grilles responsives :

```dart
// Nombre de colonnes
Mobile  : 2 colonnes
Tablet  : 3 colonnes
Desktop : 4 colonnes
```

**Code :**
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: ResponsiveHelper.getGridColumns(context),
    // ...
  ),
  // ...
)
```

### 4. Page Transitions

Les transitions restent fluides sur toutes les tailles :

```dart
// Durée adaptative (optionnel)
Navigator.push(
  context,
  GlassmorphismPageRoute(
    page: ProfilePage(),
    duration: ResponsiveHelper.getAnimationDuration(
      context,
      mobile: Duration(milliseconds: 300),
      tablet: Duration(milliseconds: 400),
      desktop: Duration(milliseconds: 500),
    ),
  ),
);
```

## 🛠️ Méthodes du ResponsiveHelper

### Vérifier le type d'appareil

```dart
if (ResponsiveHelper.isMobile(context)) {
  // Code spécifique mobile
}

if (ResponsiveHelper.isTablet(context)) {
  // Code spécifique tablet
}

if (ResponsiveHelper.isDesktop(context)) {
  // Code spécifique desktop
}
```

### Obtenir une valeur selon l'appareil

```dart
final value = ResponsiveHelper.valueByDevice<double>(
  context: context,
  mobile: 16.0,
  tablet: 24.0,
  desktop: 32.0,
);
```

### Méthodes spécialisées

```dart
// Taille de police
final fontSize = ResponsiveHelper.getFontSize(
  context,
  mobile: 14.0,
  tablet: 16.0,
  desktop: 18.0,
);

// Taille d'icône
final iconSize = ResponsiveHelper.getIconSize(
  context,
  mobile: 24.0,
  tablet: 28.0,
  desktop: 32.0,
);

// Taille de bouton
final buttonSize = ResponsiveHelper.getButtonSize(
  context,
  mobile: 50.0,
  tablet: 60.0,
  desktop: 70.0,
);

// Largeur de dialog
final dialogWidth = ResponsiveHelper.getDialogWidth(context);

// Hauteur de carte
final cardHeight = ResponsiveHelper.getCardHeight(context);

// Padding adaptatif
final padding = ResponsiveHelper.getAdaptivePadding(context);

// Nombre de colonnes pour grille
final columns = ResponsiveHelper.getGridColumns(context);
```

## 📱 Layout Responsive

### Utiliser ResponsiveBuilder

```dart
ResponsiveBuilder(
  mobile: MobileLayout(),
  tablet: TabletLayout(),
  desktop: DesktopLayout(),
)
```

### Exemple complet

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveBuilder(
        mobile: ListView(children: [...]),
        tablet: GridView(children: [...]),
        desktop: Row(
          children: [
            NavigationRail(...),
            Expanded(child: GridView(...)),
          ],
        ),
      ),
    );
  }
}
```

## 🎨 Personnalisation responsive

### Adapter vos propres widgets

```dart
class MyAnimatedWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: ResponsiveHelper.getAnimationDuration(context),
      width: ResponsiveHelper.valueByDevice(
        context: context,
        mobile: 200,
        tablet: 300,
        desktop: 400,
      ),
      height: ResponsiveHelper.getCardHeight(context),
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Text(
        'Mon texte',
        style: TextStyle(
          fontSize: ResponsiveHelper.getFontSize(
            context,
            mobile: 16,
            tablet: 20,
            desktop: 24,
          ),
        ),
      ),
    );
  }
}
```

## ✅ Checklist Responsive

Lors de la création d'un nouveau widget animé :

- [ ] Utiliser `ResponsiveHelper.getButtonSize()` pour les boutons
- [ ] Utiliser `ResponsiveHelper.getFontSize()` pour les textes
- [ ] Utiliser `ResponsiveHelper.getIconSize()` pour les icônes
- [ ] Utiliser `ResponsiveHelper.getAdaptivePadding()` pour les paddings
- [ ] Utiliser `ResponsiveHelper.getDialogWidth()` pour les dialogs
- [ ] Tester sur mobile (< 600px)
- [ ] Tester sur tablet (600-1200px)
- [ ] Tester sur desktop (>= 1200px)

## 🧪 Testing Responsive

### Dans Chrome DevTools

1. Ouvrir DevTools (F12)
2. Cliquer sur l'icône de responsive (ou Ctrl+Shift+M)
3. Tester différentes tailles :
   - Mobile : 375x667 (iPhone SE)
   - Tablet : 768x1024 (iPad)
   - Desktop : 1920x1080

### Exemples de tailles courantes

```dart
// Mobile
Width: 360px, 375px, 390px, 414px
Height: 640px, 667px, 844px, 896px

// Tablet
Width: 768px, 810px, 820px
Height: 1024px, 1080px

// Desktop
Width: 1280px, 1366px, 1920px
Height: 720px, 768px, 1080px
```

## 💡 Best Practices

### ✅ À FAIRE

```dart
// Utiliser les méthodes du ResponsiveHelper
final size = ResponsiveHelper.getButtonSize(context);

// Vérifier le type d'appareil avant des actions spécifiques
if (ResponsiveHelper.isMobile(context)) {
  showModalBottomSheet(...);
} else {
  showDialog(...);
}

// Adapter les animations selon l'appareil
duration: ResponsiveHelper.getAnimationDuration(context);
```

### ❌ À ÉVITER

```dart
// Ne pas utiliser des tailles fixes
size: 50.0  // ❌ Ne s'adapte pas

// Ne pas ignorer le contexte
if (MediaQuery.of(context).size.width < 600)  // ❌ Réinventer la roue

// Ne pas oublier les tablets
mobile: Widget1(),
desktop: Widget2(),
// ❌ Pas de variante tablet !
```

## 📊 Exemples d'adaptation

### Animation de particules

```dart
// Nombre de particules selon l'appareil
final particleCount = ResponsiveHelper.valueByDevice(
  context: context,
  mobile: 10,
  tablet: 15,
  desktop: 20,
);
```

### Vitesse d'animation

```dart
// Animation plus rapide sur mobile
final duration = ResponsiveHelper.getAnimationDuration(
  context,
  mobile: Duration(milliseconds: 300),
  tablet: Duration(milliseconds: 400),
  desktop: Duration(milliseconds: 500),
);
```

### Grilles de cartes

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: ResponsiveHelper.getGridColumns(context),
    childAspectRatio: ResponsiveHelper.isMobile(context) ? 0.75 : 0.8,
    crossAxisSpacing: ResponsiveHelper.isMobile(context) ? 12 : 16,
    mainAxisSpacing: ResponsiveHelper.isMobile(context) ? 12 : 16,
  ),
  // ...
)
```

## 🚀 Résultat

Tous les widgets d'animation sont maintenant **entièrement responsives** :

✅ S'adaptent à mobile, tablet, et desktop
✅ Tailles de boutons proportionnelles
✅ Textes lisibles sur toutes les tailles
✅ Spacing adaptatif
✅ Animations fluides partout
✅ Performance optimale

---

**L'app fonctionne parfaitement sur toutes les dimensions ! 🎉**
