# 🚀 Instructions de Déploiement Flutter Web

## Préparation

### 1. Vérifier la configuration Appwrite Cloud

Assurez-vous que dans `lib/core/config/appwrite_config.dart`:
```dart
static const bool USE_CLOUD = true; // ✅ DOIT être true pour production
```

### 2. Build de production

Exécutez le script de build:
```bash
build_and_deploy.bat
```

OU manuellement:
```bash
flutter clean
flutter pub get
flutter build web --release --web-renderer html
```

Le build sera dans le dossier `build/web/`

---

## Option 1: Netlify (Recommandé - Le plus simple)

### Méthode A: Drag & Drop (La plus rapide)

1. Allez sur https://app.netlify.com
2. Créez un compte gratuit si nécessaire
3. Cliquez sur "Add new site" > "Deploy manually"
4. Glissez-déposez le dossier `build/web` entier
5. ✅ Votre site est en ligne en quelques secondes!

### Méthode B: Git Auto-Deploy (Recommandé pour les mises à jour)

1. Initialisez Git si ce n'est pas fait:
```bash
git init
git add .
git commit -m "Initial commit"
```

2. Créez un dépôt GitHub/GitLab

3. Poussez votre code:
```bash
git remote add origin https://github.com/votre-username/dating-app.git
git push -u origin master
```

4. Sur Netlify:
   - "Add new site" > "Import an existing project"
   - Connectez votre dépôt GitHub
   - Build settings (déjà dans netlify.toml):
     - Build command: `flutter build web --release --web-renderer html`
     - Publish directory: `build/web`
   - Deploy!

5. ✅ Chaque push sur master = déploiement automatique!

### Configuration domaine personnalisé

1. Dans Netlify > Site settings > Domain management
2. Add custom domain
3. Suivez les instructions DNS

---

## Option 2: Vercel

1. Allez sur https://vercel.com
2. "Add New" > "Project"  
3. Importez depuis Git ou uploadez `build/web`
4. ✅ Déployé!

---

## Option 3: Firebase Hosting

1. Installez Firebase CLI:
```bash
npm install -g firebase-tools
```

2. Initialisez Firebase:
```bash
firebase login
firebase init hosting
```

3. Configuration:
   - Public directory: `build/web`
   - Single-page app: Yes
   - Overwrite index.html: No

4. Déployez:
```bash
firebase deploy
```

---

## Vérifications Post-Déploiement

### ✅ Checklist

- [ ] Le site charge correctement
- [ ] Login/Register fonctionnent
- [ ] Upload de vidéos fonctionne
- [ ] Swipe fonctionne
- [ ] Chat fonctionne
- [ ] Les images/vidéos s'affichent
- [ ] Pas d'erreurs dans la console (F12)

### ⚠️ Problèmes courants

**CORS errors avec Appwrite:**
- Allez dans Appwrite Console > votre projet > Settings
- Ajoutez votre domaine Netlify dans "Platforms" (Web)
- Exemple: `https://votre-app.netlify.app`

**Page blanche:**
- Vérifiez la console Chrome (F12)
- Vérifiez que `USE_CLOUD = true`
- Vérifiez les IDs Appwrite Cloud

**Videos ne s'affichent pas:**
- Vérifiez les permissions du bucket storage dans Appwrite
- File read: Anyone
- File write: Users

---

## URLs importantes

- **Appwrite Console**: https://cloud.appwrite.io/console
- **Netlify Dashboard**: https://app.netlify.com
- **Documentation Flutter Web**: https://docs.flutter.dev/deployment/web

---

## Support

Si problème, vérifiez:
1. Console navigateur (F12)
2. Logs Netlify (Deploy logs)
3. Configuration Appwrite (CORS, permissions)

