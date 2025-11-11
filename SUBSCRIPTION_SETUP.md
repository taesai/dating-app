# 🎯 Configuration Système de Souscription

## 📋 Étape 1 : Ajouter les Attributs dans Appwrite

### Collection `users` (68e8a94100036164036c)

Allez dans votre console Appwrite → Database → Collection `users` → Attributes

Ajoutez les 3 nouveaux attributs suivants :

#### 1. `subscriptionPlan` (String)
- **Type**: String
- **Taille**: 20
- **Required**: ✅ Oui
- **Default**: `free`
- **Array**: ❌ Non

#### 2. `subscriptionExpiresAt` (DateTime)
- **Type**: DateTime
- **Required**: ❌ Non
- **Default**: (vide)
- **Array**: ❌ Non

#### 3. `subscriptionStartedAt` (DateTime)
- **Type**: DateTime
- **Required**: ❌ Non
- **Default**: (vide)
- **Array**: ❌ Non

---

## 🚀 Étape 2 : Exécuter le Script d'Attribution

### Option A : Via le fichier HTML

1. Ouvrez le fichier `scripts/assign_subscription_plans.html` dans votre navigateur

2. Vérifiez la configuration Appwrite :
   - Project ID: `68e7d31c0038917ac217`
   - Database ID: `68e8a9320008c0036625`
   - Users Collection ID: `68e8a94100036164036c`
   - Endpoint: `http://localhost/v1`

3. Cliquez sur **"🚀 Assigner Plans Aléatoires"**

4. Le script va :
   - Récupérer tous les utilisateurs
   - Assigner aléatoirement un plan (60% FREE, 30% SILVER, 10% GOLD)
   - Définir les dates d'expiration (30 jours pour SILVER/GOLD)
   - Afficher les statistiques

### Option B : Manuellement via Appwrite Console

Pour chaque utilisateur :
1. Allez dans Console → Database → users
2. Cliquez sur un document utilisateur
3. Modifiez :
   - `subscriptionPlan`: `free`, `silver` ou `gold`
   - `subscriptionStartedAt`: Date du jour (format ISO)
   - `subscriptionExpiresAt`: Date + 30 jours (format ISO)

---

## 📊 Plans de Souscription

### 🆓 FREE (Plan Gratuit)
| Fonctionnalité | Limite |
|----------------|--------|
| Swipes/jour | 20 |
| Likes/jour | 10 |
| Super Likes | 0 |
| Durée vidéo | 3 secondes |
| Nombre de vidéos | 1 |
| Voir qui vous like | ❌ |
| Filtres avancés | ❌ |
| Pas de pub | ❌ |
| Boosts/mois | 0 |

### 🥈 SILVER
| Fonctionnalité | Limite |
|----------------|--------|
| Swipes/jour | 100 |
| Likes/jour | 50 |
| Super Likes/jour | 3 |
| Durée vidéo | 10 secondes |
| Nombre de vidéos | 3 |
| Voir qui vous like | ✅ |
| Filtres avancés | ✅ |
| Pas de pub | ❌ |
| Boosts/mois | 1 |

### 🥇 GOLD
| Fonctionnalité | Limite |
|----------------|--------|
| Swipes/jour | Illimité |
| Likes/jour | Illimité |
| Super Likes/jour | Illimité |
| Durée vidéo | 20 secondes |
| Nombre de vidéos | 10 |
| Voir qui vous like | ✅ |
| Filtres avancés | ✅ |
| Pas de pub | ✅ |
| Boosts/mois | 5 |

---

## 🔧 Fichiers Créés/Modifiés

### Nouveaux Modèles
- ✅ `lib/core/models/subscription_plan.dart` - Définition des plans et limitations
- ✅ `lib/core/models/usage_limits.dart` - Suivi utilisation quotidienne

### Modèles Modifiés
- ✅ `lib/core/models/dating_user.dart` - Ajout champs souscription

### Scripts
- ✅ `scripts/assign_subscription_plans.html` - Attribution automatique des plans

---

## 📝 Utilisation dans le Code

```dart
// Obtenir le plan actuel de l'utilisateur
String currentPlan = user.effectivePlan; // 'free', 'silver', 'gold'

// Obtenir les limitations
PlanLimits limits = user.planLimits;

// Vérifier les limites
int maxSwipes = limits.maxSwipesPerDay ?? 999999; // null = illimité
bool canSeeWhoLiked = limits.canSeeWhoLikedYou;
bool hasAds = !limits.hasNoAds;

// Vérifier si le plan est actif
bool isActive = user.subscription.isActive;

// Afficher les informations
print('Plan: ${limits.planName}');
print('Swipes: ${limits.formatSwipesLimit()}');
print('Likes: ${limits.formatLikesLimit()}');
```

---

## 🎯 Prochaines Étapes

1. ✅ Créer collection `usage_limits` dans Appwrite pour tracker l'utilisation
2. ⏳ Créer `SubscriptionService` pour gérer la logique métier
3. ⏳ Ajouter UI pour afficher le plan et proposer l'upgrade
4. ⏳ Implémenter les limitations dans l'app (swipes, likes, etc.)
5. ⏳ Ajouter bannières publicitaires pour FREE uniquement

---

## ⚠️ Notes Importantes

- Les plans SILVER et GOLD expirent après 30 jours
- Les plans expirés reviennent automatiquement à FREE
- Le script d'attribution est **non destructif** (peut être relancé)
- Les dates sont en format ISO 8601 (UTC)

---

**Date**: 2025-10-16
**Version**: 1.0
**Statut**: ✅ Prêt pour déploiement
