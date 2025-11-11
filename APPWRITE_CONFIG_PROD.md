# ⚙️ Configuration Appwrite pour Production

## 1. Ajouter le domaine de production

Une fois votre site déployé sur Netlify (ex: `https://dating-app-xyz.netlify.app`), configurez Appwrite:

### Dans Appwrite Console (https://cloud.appwrite.io/console)

1. Allez dans votre projet
2. Settings > Platforms
3. "Add Platform" > "Web"
4. Entrez:
   - **Name**: Production Web
   - **Hostname**: `dating-app-xyz.netlify.app` (SANS https://)
   - Cochez "Enable"
5. Save

## 2. Vérifier les permissions Storage

### Bucket "medias" (videos/photos)

1. Storage > medias bucket > Settings > Permissions
2. Assurez-vous:
   - **File Read**: `Any` (ou `role:member`)
   - **File Create**: `Users`
   - **File Update**: `Users`  
   - **File Delete**: `Users`

## 3. Vérifier les permissions Collections

### Pour chaque collection (users, videos, likes, matches, etc.):

1. Database > Votre DB > Collection > Settings > Permissions
2. Configuration recommandée:
   - **Read**: `Any` (pour découvrir les profils)
   - **Create**: `Users`
   - **Update**: `Users` + rule pour owner
   - **Delete**: `Users` + rule pour owner

## 4. Domaines personnalisés

Si vous utilisez votre propre domaine (ex: `dating-app.com`):

1. Configurez le domaine dans Netlify
2. Ajoutez AUSSI ce domaine dans Appwrite Platforms
3. Les deux domaines (Netlify + custom) doivent être dans Appwrite

## 5. Variables d'environnement (si nécessaire)

Si vous voulez des configs différentes dev/prod, créez un fichier `.env`:

```
FLUTTER_APP_APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
FLUTTER_APP_APPWRITE_PROJECT_ID=681829e4003b243e6681
```

**Note**: Flutter Web ne supporte pas vraiment les .env, donc gardez la config hardcodée dans appwrite_config.dart

## 6. Test Post-Déploiement

1. Ouvrez votre site de production
2. F12 Console
3. Vérifiez:
   - Pas d'erreurs CORS
   - Les requêtes Appwrite passent (200 OK)
   - Login fonctionne
   - Upload fonctionne

## ⚠️ IMPORTANT: Sécurité

- Ne commitez JAMAIS les API keys dans Git
- Utilisez les permissions Appwrite pour la sécurité
- Les IDs de projet peuvent être publics (c'est normal)
- Les clés secrètes doivent rester côté serveur uniquement

