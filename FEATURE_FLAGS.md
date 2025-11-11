# 🚩 Feature Flags

Ce fichier explique comment gérer les fonctionnalités activables/désactivables de l'application.

## 📍 Fichier de configuration

[lib/core/config/feature_flags.dart](lib/core/config/feature_flags.dart)

---

## 🔧 Flags disponibles

### `enableRealtime` (défaut: `false`)

Active ou désactive les fonctionnalités temps réel via Appwrite Realtime.

**Utilisation:**
- ✅ **false** - Mode développement (évite les blocages `guarantee_channel.dart`)
- ✅ **true** - Mode production (notifications instantanées)

**Impact:**
- **Videos** : Nouvelles vidéos apparaissent immédiatement (Realtime ON) ou manuellement (Realtime OFF)
- **Chat** : Messages reçus instantanément (Realtime ON) ou toutes les 3-5 secondes (polling)
- **Matches** : Notifications de match immédiates (Realtime ON) ou au prochain rafraîchissement

**Quand activer:**
```dart
// Développement (évite les blocages)
static const bool enableRealtime = false;

// Production (expérience optimale)
static const bool enableRealtime = true;
```

---

### `pollingInterval` (défaut: `3`)

Intervalle en secondes pour le polling quand Realtime est désactivé.

**Valeurs recommandées:**
- `3` secondes - Bonne réactivité (développement)
- `5` secondes - Équilibre performance/réactivité
- `10` secondes - Économie de bande passante

---

### `verboseLogs` (défaut: `true`)

Active ou désactive les logs détaillés dans la console.

**Utilisation:**
```dart
// Développement
static const bool verboseLogs = true;

// Production
static const bool verboseLogs = false;
```

---

## 🎯 Configuration recommandée

### Environnement de développement

```dart
class FeatureFlags {
  static const bool enableRealtime = false;  // ⚠️ Évite les blocages
  static const int pollingInterval = 3;
  static const bool verboseLogs = true;
}
```

### Environnement de production

```dart
class FeatureFlags {
  static const bool enableRealtime = true;   // ✅ Expérience optimale
  static const int pollingInterval = 5;      // Backup si Realtime échoue
  static const bool verboseLogs = false;
}
```

---

## 🐛 Résolution des problèmes

### Problème : Blocages avec `guarantee_channel.dart`

**Solution:**
```dart
static const bool enableRealtime = false;
```

### Problème : Messages de chat trop lents

**Solution:**
```dart
static const int pollingInterval = 2; // Plus rapide
```

### Problème : Trop de requêtes au serveur

**Solution:**
```dart
static const int pollingInterval = 10; // Plus lent
```

---

## 📝 Notes importantes

1. **Hot Reload**: Après modification des feature flags, faites un **hot restart** (pas juste hot reload)
2. **Realtime en production**: Assurez-vous que Realtime est activé dans Appwrite Console
3. **Polling**: Le polling fonctionne toujours, même avec Realtime activé (backup)

---

## 🔄 Passage en production

Avant de déployer en production :

1. ✅ Créer toutes les collections Appwrite
2. ✅ Vérifier que Realtime fonctionne (pas d'erreurs 404)
3. ✅ Mettre `enableRealtime = true`
4. ✅ Mettre `verboseLogs = false`
5. ✅ Tester sur un device réel
