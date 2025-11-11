# 📘 Configuration Appwrite Local pour Dating App

## ✅ Informations du Projet
- **Endpoint**: http://localhost/v1
- **Project ID**: 68e7d31c0038917ac217
- **Port**: 80

---

## 🗄️ Étape 1 : Créer la Base de Données

1. Dans la console Appwrite, allez dans **Databases**
2. Cliquez sur **Create database**
3. Configurez :
   - **Database ID**: `dating_app_db`
   - **Name**: `Dating App Database`

---

## 2. Créer les Collections

### Collection 1: Users (Utilisateurs)
**Configuration de base:**
- **Collection ID**: `users`
- **Name**: `Users`

**Attributs à créer:**
```
1. name (String)
   - Type: String
   - Size: 255
   - Required: Yes

2. email (String)
   - Type: String
   - Size: 255
   - Required: Yes

3. age (Integer)
   - Type: Integer
   - Required: Yes
   - Min: 18
   - Max: 100

4. gender (String)
   - Type: String
   - Size: 50
   - Required: Yes

5. bio (String)
   - Type: String
   - Size: 1000
   - Required: No

6. latitude (Float)
   - Type: Float
   - Required: Yes

7. longitude (Float)
   - Type: Float
   - Required: Yes

8. interests (String Array)
   - Type: String[]
   - Required: No
   - Array: Yes

9. photoUrls (String Array)
   - Type: String[]
   - Required: No
   - Array: Yes

10. createdAt (DateTime)
    - Type: DateTime
    - Required: Yes

11. isActive (Boolean)
    - Type: Boolean
    - Required: Yes
    - Default: true
```

**Indexes:**
```
1. Index sur 'isActive'
   - Key: idx_isActive
   - Type: key
   - Attributes: isActive
   - Orders: ASC

2. Index sur 'createdAt'
   - Key: idx_createdAt
   - Type: key
   - Attributes: createdAt
   - Orders: DESC
```

**Permissions:**
- **Read Access**: `role:any`
- **Create Access**: `role:any`
- **Update Access**: `role:any`
- **Delete Access**: `role:any`

---

### Collection 2: Videos
**Configuration de base:**
- **Collection ID**: `videos`
- **Name**: `Videos`

**Attributs à créer:**
```
1. userId (String)
   - Type: String
   - Size: 255
   - Required: Yes

2. fileId (String)
   - Type: String
   - Size: 255
   - Required: Yes

3. title (String)
   - Type: String
   - Size: 255
   - Required: Yes

4. description (String)
   - Type: String
   - Size: 1000
   - Required: No

5. views (Integer)
   - Type: Integer
   - Required: Yes
   - Default: 0

6. likes (Integer)
   - Type: Integer
   - Required: Yes
   - Default: 0

7. createdAt (DateTime)
   - Type: DateTime
   - Required: Yes
```

**Indexes:**
```
1. Index sur 'userId'
   - Key: idx_userId
   - Type: key
   - Attributes: userId
   - Orders: ASC

2. Index sur 'createdAt'
   - Key: idx_createdAt
   - Type: key
   - Attributes: createdAt
   - Orders: DESC
```

**Permissions:**
- **Read Access**: `role:any`
- **Create Access**: `role:any`
- **Update Access**: `role:any`
- **Delete Access**: `role:any`

---

### Collection 3: Matches
**Configuration de base:**
- **Collection ID**: `matches`
- **Name**: `Matches`

**Attributs à créer:**
```
1. user1Id (String)
   - Type: String
   - Size: 255
   - Required: Yes

2. user2Id (String)
   - Type: String
   - Size: 255
   - Required: Yes

3. createdAt (DateTime)
   - Type: DateTime
   - Required: Yes

4. isActive (Boolean)
   - Type: Boolean
   - Required: Yes
   - Default: true
```

**Indexes:**
```
1. Index sur 'user1Id'
   - Key: idx_user1Id
   - Type: key
   - Attributes: user1Id
   - Orders: ASC

2. Index sur 'user2Id'
   - Key: idx_user2Id
   - Type: key
   - Attributes: user2Id
   - Orders: ASC

3. Index sur 'isActive'
   - Key: idx_isActive
   - Type: key
   - Attributes: isActive
   - Orders: ASC

4. Index sur 'createdAt'
   - Key: idx_createdAt
   - Type: key
   - Attributes: createdAt
   - Orders: DESC
```

**Permissions:**
- **Read Access**: `role:any`
- **Create Access**: `role:any`
- **Update Access**: `role:any`
- **Delete Access**: `role:any`

---

### Collection 4: Likes
**Configuration de base:**
- **Collection ID**: `likes`
- **Name**: `Likes`

**Attributs à créer:**
```
1. fromUserId (String)
   - Type: String
   - Size: 255
   - Required: Yes

2. toUserId (String)
   - Type: String
   - Size: 255
   - Required: Yes

3. createdAt (DateTime)
   - Type: DateTime
   - Required: Yes
```

**Indexes:**
```
1. Index sur 'fromUserId'
   - Key: idx_fromUserId
   - Type: key
   - Attributes: fromUserId
   - Orders: ASC

2. Index sur 'toUserId'
   - Key: idx_toUserId
   - Type: key
   - Attributes: toUserId
   - Orders: ASC

3. Index composé pour vérifier les matches
   - Key: idx_from_to
   - Type: key
   - Attributes: fromUserId, toUserId
   - Orders: ASC, ASC
```

**Permissions:**
- **Read Access**: `role:any`
- **Create Access**: `role:any`
- **Update Access**: `role:any`
- **Delete Access**: `role:any`

---

## 3. Créer le Bucket (Un seul bucket pour tout)

**Configuration:**
- **Bucket ID**: `dating_app_media`
- **Name**: `Dating App Media`
- **Maximum File Size**: 50MB (50000000 bytes)
- **Allowed File Extensions**: `jpg,jpeg,png,gif,webp,mp4,mov,avi`
- **Compression**: `gzip`
- **Encryption**: `Enabled`
- **Antivirus**: `Enabled`

**Permissions:**
- **Read Access**: `role:any`
- **Create Access**: `role:any`
- **Update Access**: `role:any`
- **Delete Access**: `role:any`

---

## 4. Mise à jour du Code

Après avoir créé le bucket unique, vous devez mettre à jour `appwrite_service.dart` :

```dart
// Remplacer les lignes 25-27 par :
static const String mediasBucketId = 'dating_app_media';
```

Et modifier toutes les références :
- `videosBucketId` → `mediasBucketId`
- `profilePhotosBucketId` → `mediasBucketId`

---

## 5. Vérification

Une fois la configuration terminée, vérifiez :

✅ Database `dating_app_db` créée
✅ Collection `users` avec 11 attributs
✅ Collection `videos` avec 7 attributs
✅ Collection `matches` avec 4 attributs
✅ Collection `likes` avec 3 attributs
✅ Bucket `dating_app_media` créé
✅ Tous les indexes configurés
✅ Toutes les permissions définies sur `role:any`

---

## Notes Importantes

1. **Compte gratuit**: Avec un compte gratuit, vous êtes limité à un seul bucket. C'est pourquoi nous utilisons `dating_app_media` pour stocker à la fois les photos de profil et les vidéos.

2. **Permissions**: Les permissions sont actuellement définies sur `role:any` pour le développement. Pour la production, vous devriez les restreindre.

3. **Géolocalisation**: La fonction `getNearbyUsers` est simplifiée. Pour une vraie application en production, vous devriez implémenter une fonction serveur avec géohashing.

4. **Security**: N'oubliez pas de configurer les règles de sécurité appropriées avant de passer en production.

---

## 6. Nouvelles Collections (Reports, Blocks, Chat)

### Collection 5: Reports (Signalements)
**Configuration de base:**
- **Collection ID**: `reports`
- **Name**: `Reports`

**Attributs à créer:**
```
1. reporterId (String)
   - Type: String
   - Size: 255
   - Required: Yes

2. reportedUserId (String)
   - Type: String
   - Size: 255
   - Required: Yes

3. reportType (String)
   - Type: String
   - Size: 50
   - Required: Yes

4. description (String)
   - Type: String
   - Size: 2000
   - Required: Yes

5. createdAt (DateTime)
   - Type: DateTime
   - Required: Yes

6. status (String)
   - Type: String
   - Size: 50
   - Required: Yes
   - Default: pending
```

**Indexes:**
```
1. Index sur 'reporterId'
   - Key: idx_reporterId
   - Type: key
   - Attributes: reporterId
   - Orders: ASC

2. Index sur 'reportedUserId'
   - Key: idx_reportedUserId
   - Type: key
   - Attributes: reportedUserId
   - Orders: ASC

3. Index sur 'status'
   - Key: idx_status
   - Type: key
   - Attributes: status
   - Orders: ASC
```

**Permissions:**
- **Read Access**: `role:team` (admins only)
- **Create Access**: `role:member`
- **Update Access**: `role:team` (admins only)
- **Delete Access**: `role:team` (admins only)

---

### Collection 6: Blocked Users
**Configuration de base:**
- **Collection ID**: `blocked_users`
- **Name**: `Blocked Users`

**Attributs à créer:**
```
1. blockerId (String)
   - Type: String
   - Size: 255
   - Required: Yes

2. blockedUserId (String)
   - Type: String
   - Size: 255
   - Required: Yes

3. reason (String)
   - Type: String
   - Size: 500
   - Required: No

4. createdAt (DateTime)
   - Type: DateTime
   - Required: Yes
```

**Indexes:**
```
1. Index sur 'blockerId'
   - Key: idx_blockerId
   - Type: key
   - Attributes: blockerId
   - Orders: ASC

2. Index sur 'blockedUserId'
   - Key: idx_blockedUserId
   - Type: key
   - Attributes: blockedUserId
   - Orders: ASC

3. Index composé unique (éviter doublons)
   - Key: idx_blocker_blocked
   - Type: unique
   - Attributes: blockerId, blockedUserId
   - Orders: ASC, ASC
```

**Permissions:**
- **Read Access**: `role:member`
- **Create Access**: `role:member`
- **Update Access**: None
- **Delete Access**: `role:member`

---

### Collection 7: Chat Messages
**Configuration de base:**
- **Collection ID**: `chat_messages`
- **Name**: `Chat Messages`

**Attributs à créer:**
```
1. matchId (String)
   - Type: String
   - Size: 255
   - Required: Yes

2. senderId (String)
   - Type: String
   - Size: 255
   - Required: Yes

3. receiverId (String)
   - Type: String
   - Size: 255
   - Required: Yes

4. message (String)
   - Type: String
   - Size: 5000
   - Required: Yes

5. createdAt (DateTime)
   - Type: DateTime
   - Required: Yes

6. isRead (Boolean)
   - Type: Boolean
   - Required: Yes
   - Default: false

7. mediaUrl (String)
   - Type: String
   - Size: 500
   - Required: No
```

**Indexes:**
```
1. Index sur 'matchId'
   - Key: idx_matchId
   - Type: key
   - Attributes: matchId
   - Orders: ASC

2. Index sur 'receiverId'
   - Key: idx_receiverId
   - Type: key
   - Attributes: receiverId
   - Orders: ASC

3. Index sur 'createdAt'
   - Key: idx_createdAt
   - Type: key
   - Attributes: createdAt
   - Orders: DESC

4. Index composé pour optimiser les requêtes
   - Key: idx_match_created
   - Type: key
   - Attributes: matchId, createdAt
   - Orders: ASC, DESC
```

**Permissions:**
- **Read Access**: `role:member`
- **Create Access**: `role:member`
- **Update Access**: `role:member` (pour marquer comme lu)
- **Delete Access**: `role:member`

---

## 7. Mise à jour du Code (Collections supplémentaires)

Après avoir créé les nouvelles collections, mettez à jour `appwrite_service.dart` avec les vrais IDs :

```dart
// Lignes 26-28, remplacer par les vrais IDs de collection:
static const String reportsCollectionId = 'VOTRE_ID_REPORTS';
static const String blockedUsersCollectionId = 'VOTRE_ID_BLOCKED_USERS';
static const String chatMessagesCollectionId = 'VOTRE_ID_CHAT_MESSAGES';
```

---

## 8. Vérification finale

Une fois toutes les collections créées, vérifiez :

✅ Collection `reports` avec 6 attributs
✅ Collection `blocked_users` avec 4 attributs
✅ Collection `chat_messages` avec 7 attributs
✅ Tous les indexes configurés
✅ Toutes les permissions définies correctement
✅ Realtime activé pour les messages du chat

---

## 9. Configuration Realtime (Important pour le Chat)

Pour activer les notifications en temps réel :

1. Dans Appwrite Console > Project Settings > Realtime
2. Vérifier que Realtime est activé
3. Les clients Flutter s'abonneront automatiquement via :
   ```dart
   databases.[DATABASE_ID].collections.[CHAT_MESSAGES_ID].documents
   ```