# 🚀 Déploiement GitHub + Netlify - Guide Complet

## Étape 1: Préparer le repository GitHub (5 min)

### 1.1 Initialiser Git localement

```bash
cd D:/APPS/Flutter/WEB/dating_app

# Initialiser Git (si pas déjà fait)
git init

# Vérifier les fichiers
git status

# Ajouter tous les fichiers
git add .

# Premier commit
git commit -m "Initial commit - Dating app ready for deployment"
```

### 1.2 Créer le repository sur GitHub

1. Allez sur https://github.com
2. Cliquez sur le **+** en haut à droite > **New repository**
3. Remplissez:
   - **Repository name**: `dating-app` (ou autre nom)
   - **Description**: "Flutter dating app with Appwrite backend"
   - **Visibility**: 
     - ✅ **Private** (recommandé - votre code reste privé)
     - ⚠️ Public (tout le monde peut voir le code)
   - ❌ Ne cochez RIEN d'autre (pas de README, .gitignore, etc.)
4. Cliquez **Create repository**

### 1.3 Connecter et pousser vers GitHub

GitHub vous affiche des commandes. Utilisez celles-ci:

```bash
# Ajouter le remote (REMPLACEZ par VOTRE URL)
git remote add origin https://github.com/VOTRE-USERNAME/dating-app.git

# Renommer la branche en 'main'
git branch -M main

# Pousser vers GitHub
git push -u origin main
```

✅ **Votre code est maintenant sur GitHub!**

---

## Étape 2: Déployer sur Netlify (10 min)

### 2.1 Créer un compte Netlify

1. Allez sur https://app.netlify.com/signup
2. Choisissez **"Sign up with GitHub"** (plus simple)
3. Autorisez Netlify à accéder à vos repos

### 2.2 Importer votre projet

1. Sur le dashboard Netlify, cliquez **"Add new site"**
2. Choisissez **"Import an existing project"**
3. Sélectionnez **GitHub**
4. Cherchez et sélectionnez votre repo **dating-app**

### 2.3 Configuration du build

Netlify détecte automatiquement le `netlify.toml`, mais vérifiez:

- **Branch to deploy**: `main`
- **Build command**: `flutter build web --release --web-renderer html`
- **Publish directory**: `build/web`
- **Build environment variables**: (laisser vide pour l'instant)

Cliquez **"Deploy site"**

### 2.4 Attendre le build

- Netlify installe Flutter
- Build votre app (~3-5 minutes la première fois)
- Déploie automatiquement

✅ **Vous obtenez une URL**: `https://[random-name].netlify.app`

### 2.5 Personnaliser le nom (optionnel)

1. Site settings > Site details > **Change site name**
2. Choisissez: `dating-app-demo` → `https://dating-app-demo.netlify.app`
3. (Doit être unique sur Netlify)

---

## Étape 3: Configurer Appwrite CORS (CRUCIAL!)

Sans ça, votre app ne fonctionnera PAS en production!

### 3.1 Ajouter le domaine Netlify dans Appwrite

1. Allez sur https://cloud.appwrite.io/console
2. Sélectionnez votre projet
3. **Settings** (menu gauche) > **Platforms**
4. Cliquez **"Add Platform"**
5. Choisissez **"Web"**
6. Remplissez:
   - **Name**: `Production - Netlify`
   - **Hostname**: `dating-app-demo.netlify.app`
     - ⚠️ SANS `https://`
     - ⚠️ SANS `/` à la fin
     - Juste le hostname!
7. Cliquez **"Create"**

✅ **CORS configuré!**

---

## Étape 4: Tester votre site en production

### 4.1 Ouvrir le site

Allez sur votre URL Netlify: `https://votre-app.netlify.app`

### 4.2 Tests essentiels

- [ ] La page charge (pas d'écran blanc)
- [ ] Login fonctionne
- [ ] Inscription fonctionne
- [ ] Upload de vidéo fonctionne
- [ ] Swipe fonctionne
- [ ] Chat fonctionne
- [ ] Pas d'erreurs CORS dans la console (F12)

### 4.3 Console de debug (F12)

Vérifiez:
- **Console**: Pas d'erreurs rouges critiques
- **Network**: Les requêtes Appwrite passent (200 OK)
- Filtrez par "appwrite" pour voir les appels

---

## Étape 5: Déploiements futurs (automatique!)

Désormais, pour mettre à jour votre site:

```bash
# Faire vos modifications dans le code
# ...

# Commit
git add .
git commit -m "Fix: correction du bug X"

# Push
git push

# ✅ Netlify déploie automatiquement en ~3 min!
```

Vous recevez un email à chaque déploiement (succès/échec).

---

## 🎁 Fonctionnalités bonus Netlify

### Deploy Previews

Chaque Pull Request GitHub = URL de preview automatique!

```bash
git checkout -b feature-nouvelle-fonctionnalite
# ... modifications ...
git push origin feature-nouvelle-fonctionnalite
# Créez une PR sur GitHub
# → Netlify crée une URL de test: https://deploy-preview-1--votre-app.netlify.app
```

### Rollback instantané

1. Deploys > Sélectionnez un ancien deploy
2. **Publish deploy**
3. Retour arrière immédiat!

### Variables d'environnement

Site settings > Environment variables

---

## ⚠️ Troubleshooting

### "Page not found" sur refresh

✅ Déjà corrigé dans `netlify.toml` avec la règle de redirect!

### Erreur CORS

❌ **Symptôme**: `Access-Control-Allow-Origin` dans console

✅ **Solution**: 
- Vérifiez que le hostname est bien dans Appwrite Platforms
- Pas de `https://`, pas de `/`
- Exact match requis

### Build échoue

1. Vérifiez les logs du build dans Netlify
2. Vérification courante:
   - Version Flutter dans `netlify.toml`
   - Dépendances manquantes
   - Erreurs de compilation

### Site blanc après deploy

1. F12 > Console
2. Vérifiez les erreurs
3. Souvent: problème Appwrite config ou CORS

---

## 📊 Monitoring

### Analytics Netlify (gratuit)

Site settings > Analytics > Enable

Voyez:
- Visiteurs
- Pages vues
- Bande passante utilisée

### Notifications

Site settings > Build & deploy > Deploy notifications

Configurez:
- Email sur succès/échec
- Slack/Discord webhooks
- Etc.

---

## 🔒 Sécurité

### Variables sensibles

⚠️ **NE JAMAIS** commiter:
- API keys secrètes
- Tokens privés
- Mots de passe

✅ Les IDs publics Appwrite (projectId, etc.) PEUVENT être commitées

### HTTPS

✅ Automatique sur Netlify (Let's Encrypt)

---

## 💰 Limites gratuites Netlify

- **Bande passante**: 100 GB/mois
- **Build minutes**: 300 min/mois
- **Sites**: Illimités
- **Membres équipe**: 1 (vous)

Largement suffisant pour commencer! Vous pourrez upgrade plus tard si besoin.

---

## 🎯 Checklist finale

Avant de dire "C'est en prod!":

- [ ] Site accessible sur l'URL Netlify
- [ ] Aucune erreur dans la console (F12)
- [ ] Login/Signup fonctionnent
- [ ] Upload vidéo fonctionne
- [ ] Swipe fonctionne
- [ ] Match fonctionne
- [ ] Chat fonctionne
- [ ] Images/vidéos s'affichent
- [ ] Responsive (mobile, tablette, desktop)
- [ ] Domaine ajouté dans Appwrite Platforms
- [ ] Git pushes déclenchent auto-deploy

✅ **Félicitations, vous êtes en production!** 🎉

