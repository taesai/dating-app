# 🚀 Guide de migration Appwrite Local → Cloud

## ✅ Configuration actuelle

- **Appwrite Cloud Endpoint** : https://cloud.appwrite.io/v1
- **Project ID** : 681829e4003b243e6681
- **Database ID** : 68db88f700374422bfc7 (dating_app_db)

---

## 📋 Étape 1 : Créer les collections dans Appwrite Cloud

### Collection 1️⃣ : **users**

**Créer la collection :**
1. Allez dans **Databases** → `dating_app_db` → **Create Collection**
2. **Collection ID** : `users` (ou laissez générer)
3. **Collection name** : `users`
4. Permissions : **Document Security** activé

**Attributs à créer** (cliquez sur **Create Attribute** pour chaque) :

| Key | Type | Size | Required | Array | Default |
|-----|------|------|----------|-------|---------|
| email | Email | 255 | ✅ | ❌ | - |
| name | String | 255 | ✅ | ❌ | - |
| age | Integer | - | ✅ | ❌ | - |
| gender | String | 50 | ✅ | ❌ | - |
| bio | String | 1000 | ❌ | ❌ | - |
| photoUrls | String | 255 | ❌ | ✅ | [] |
| latitude | Double | - | ❌ | ❌ | - |
| longitude | Double | - | ❌ | ❌ | - |
| lookingFor | String | 50 | ❌ | ✅ | [] |
| interests | String | 100 | ❌ | ✅ | [] |
| city | String | 100 | ❌ | ❌ | - |
| sexualOrientation | String | 100 | ❌ | ❌ | - |
| relationshipGoal | String | 100 | ❌ | ❌ | - |
| education | String | 100 | ❌ | ❌ | - |
| profession | String | 100 | ❌ | ❌ | - |
| height | Integer | - | ❌ | ❌ | - |
| smoker | Boolean | - | ❌ | ❌ | false |
| drinker | Boolean | - | ❌ | ❌ | false |
| hasChildren | Boolean | - | ❌ | ❌ | false |
| wantsChildren | Boolean | - | ❌ | ❌ | false |
| languages | String | 50 | ❌ | ✅ | [] |
| isActive | Boolean | - | ❌ | ❌ | true |
| lastSeen | DateTime | - | ❌ | ❌ | - |
| subscriptionPlan | String | 50 | ❌ | ❌ | FREE |
| subscriptionStartedAt | DateTime | - | ❌ | ❌ | - |
| subscriptionExpiresAt | DateTime | - | ❌ | ❌ | - |
| dailySwipesUsed | Integer | - | ❌ | ❌ | 0 |
| lastSwipeResetDate | DateTime | - | ❌ | ❌ | - |

**Index à créer** :
- email (unique)
- gender + lookingFor (pour les recherches)
- city (pour la recherche par ville)

---

### Collection 2️⃣ : **videos**

**Créer la collection :**
- **Collection ID** : `videos`
- **Collection name** : `videos`
- Permissions : **Document Security** activé

**Attributs** :

| Key | Type | Size | Required | Array | Default |
|-----|------|------|----------|-------|---------|
| userId | String | 255 | ✅ | ❌ | - |
| fileId | String | 255 | ✅ | ❌ | - |
| title | String | 500 | ✅ | ❌ | - |
| thumbnailUrl | String | 500 | ❌ | ❌ | - |
| likes | Integer | - | ❌ | ❌ | 0 |
| views | Integer | - | ❌ | ❌ | 0 |
| createdAt | DateTime | - | ✅ | ❌ | - |
| isApproved | Boolean | - | ❌ | ❌ | true |

**Index** :
- userId
- createdAt (descendant)
- isApproved

---

### Collection 3️⃣ : **matches**

**Créer la collection :**
- **Collection ID** : `matches`
- **Collection name** : `matches`
- Permissions : **Document Security** activé

**Attributs** :

| Key | Type | Size | Required | Array | Default |
|-----|------|------|----------|-------|---------|
| user1Id | String | 255 | ✅ | ❌ | - |
| user2Id | String | 255 | ✅ | ❌ | - |
| createdAt | DateTime | - | ✅ | ❌ | - |
| lastMessage | String | 1000 | ❌ | ❌ | - |
| lastMessageSenderId | String | 255 | ❌ | ❌ | - |
| lastMessageDate | DateTime | - | ❌ | ❌ | - |
| unreadCountUser1 | Integer | - | ❌ | ❌ | 0 |
| unreadCountUser2 | Integer | - | ❌ | ❌ | 0 |

**Index** :
- user1Id
- user2Id
- user1Id + user2Id (composite, unique)

---

### Collection 4️⃣ : **chat_messages**

**Créer la collection :**
- **Collection ID** : `chat_messages`
- **Collection name** : `chat_messages`
- Permissions : **Document Security** activé

**Attributs** :

| Key | Type | Size | Required | Array | Default |
|-----|------|------|----------|-------|---------|
| matchId | String | 255 | ✅ | ❌ | - |
| senderId | String | 255 | ✅ | ❌ | - |
| message | String | 5000 | ✅ | ❌ | - |
| timestamp | DateTime | - | ✅ | ❌ | - |
| isRead | Boolean | - | ❌ | ❌ | false |

**Index** :
- matchId + timestamp
- senderId

---

### Collection 5️⃣ : **videoLikes** (likes de vidéos)

**Créer la collection :**
- **Collection ID** : `videoLikes`
- **Collection name** : `videoLikes`
- Permissions : **Document Security** activé

**Attributs** :

| Key | Type | Size | Required | Array | Default |
|-----|------|------|----------|-------|---------|
| userId | String | 255 | ✅ | ❌ | - |
| videoId | String | 255 | ✅ | ❌ | - |
| createdAt | DateTime | - | ✅ | ❌ | - |

**Index** :
- userId + videoId (unique)
- videoId

---

### Collection 6️⃣ : **photos**

**Créer la collection :**
- **Collection ID** : `photos`
- **Collection name** : `photos`
- Permissions : **Document Security** activé

**Attributs** :

| Key | Type | Size | Required | Array | Default |
|-----|------|------|----------|-------|---------|
| userID | String | 255 | ✅ | ❌ | - |
| fileId | String | 255 | ✅ | ❌ | - |
| createdAt | DateTime | - | ✅ | ❌ | - |
| isApproved | Boolean | - | ❌ | ❌ | false |
| isPhotoProfile | Boolean | - | ❌ | ❌ | false |
| displayOrder | Integer | - | ❌ | ❌ | 0 |

**Index** :
- userID
- isApproved

---

### Collection 7️⃣ : **reports**

**Créer la collection :**
- **Collection ID** : `reports`
- **Collection name** : `reports`
- Permissions : **Document Security** activé

**Attributs** :

| Key | Type | Size | Required | Array | Default |
|-----|------|------|----------|-------|---------|
| reporterId | String | 255 | ✅ | ❌ | - |
| reportedUserId | String | 255 | ✅ | ❌ | - |
| reason | String | 500 | ✅ | ❌ | - |
| description | String | 2000 | ❌ | ❌ | - |
| status | String | 50 | ❌ | ❌ | pending |
| createdAt | DateTime | - | ✅ | ❌ | - |

**Index** :
- reportedUserId
- status

---

### Collection 8️⃣ : **blockedUsers**

**Créer la collection :**
- **Collection ID** : `blockedUsers`
- **Collection name** : `blockedUsers`
- Permissions : **Document Security** activé

**Attributs** :

| Key | Type | Size | Required | Array | Default |
|-----|------|------|----------|-------|---------|
| blockerId | String | 255 | ✅ | ❌ | - |
| blockedUserId | String | 255 | ✅ | ❌ | - |
| createdAt | DateTime | - | ✅ | ❌ | - |

**Index** :
- blockerId + blockedUserId (unique)

---

### Collection 9️⃣ : **likes** (likes de profils)

**Créer la collection :**
- **Collection ID** : `likes`
- **Collection name** : `likes`
- Permissions : **Document Security** activé

**Attributs** :

| Key | Type | Size | Required | Array | Default |
|-----|------|------|----------|-------|---------|
| userId | String | 255 | ✅ | ❌ | - |
| likedUserId | String | 255 | ✅ | ❌ | - |
| createdAt | DateTime | - | ✅ | ❌ | - |

**Index** :
- userId + likedUserId (unique)
- likedUserId

---

## 📦 Étape 2 : Créer les buckets de stockage

### Bucket 1️⃣ : **medias**

1. Allez dans **Storage** → **Create Bucket**
2. **Bucket ID** : `medias` (ou laissez générer)
3. **Bucket name** : `medias`
4. **Maximum file size** : 50000000 (50 MB)
5. **Allowed file extensions** : `jpg,jpeg,png,gif,mp4,mov,avi,webm`
6. **Permissions** : Any → Create, Read, Update, Delete
7. **Compression** : activé (recommandé)
8. **Encryption** : activé
9. **Antivirus** : activé (si disponible)

---

## ⚙️ Étape 3 : Configurer les permissions

Pour chaque collection, configurez les permissions par défaut :

**Permissions recommandées** :
- **Create** : Users (Any authenticated user can create)
- **Read** : Users (Any authenticated user can read)
- **Update** : Users (User can update their own documents)
- **Delete** : Users (User can delete their own documents)

---

## 🎯 Prochaines étapes

Une fois toutes les collections créées :

1. ✅ Vérifiez que toutes les 9 collections existent
2. ✅ Vérifiez que le bucket `medias` existe
3. ✅ Exportez vos données locales (via Appwrite Console Local)
4. ✅ Importez dans Appwrite Cloud
5. ✅ Mettez à jour `appwrite_service.dart` pour pointer vers le Cloud
6. ✅ Déployez votre app Flutter Web

---

**⏱️ Temps estimé** : 30-45 minutes pour créer toutes les collections manuellement

Bon courage ! 🚀
