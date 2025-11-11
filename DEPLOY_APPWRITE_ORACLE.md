# Déployer Appwrite sur Oracle Cloud (Gratuit)

## 🎯 Pourquoi Oracle Cloud ?
- **100% Gratuit à vie** (Always Free Tier)
- **24GB RAM** disponible (VMs ARM)
- **200GB stockage**
- Pas de carte bancaire obligatoire
- Excellent pour production

## 📋 Prérequis
- Compte Oracle Cloud (gratuit)
- Connexion SSH

## 🚀 Étapes de déploiement

### 1. Créer un compte Oracle Cloud
1. Allez sur https://www.oracle.com/cloud/free/
2. Créez un compte gratuit
3. Vérifiez votre email

### 2. Créer une VM
1. Dans le dashboard, cliquez sur "Create a VM instance"
2. **Sélectionnez l'image** : Ubuntu 22.04
3. **Choisissez le shape** :
   - **VM.Standard.A1.Flex** (ARM - Recommandé)
   - 4 OCPU + 24GB RAM (gratuit!)
   - OU VM.Standard.E2.1.Micro (AMD - 1GB RAM)
4. **Réseau** : Créer un nouveau VCN ou utiliser celui par défaut
5. **Clé SSH** :
   - Générez une paire de clés
   - Téléchargez la clé privée (.key)
6. Cliquez sur **Create**

### 3. Configurer le Firewall

#### Dans Oracle Cloud Console :
1. Allez dans **Networking** > **Virtual Cloud Networks**
2. Cliquez sur votre VCN
3. Cliquez sur **Security Lists** > **Default Security List**
4. Cliquez sur **Add Ingress Rules**
5. Ajoutez ces règles :

```
Source CIDR: 0.0.0.0/0
IP Protocol: TCP
Destination Port: 80
Description: HTTP
```

```
Source CIDR: 0.0.0.0/0
IP Protocol: TCP
Destination Port: 443
Description: HTTPS
```

#### Dans la VM (via SSH) :
```bash
# Se connecter à la VM
ssh -i /path/to/your-key.key ubuntu@YOUR_VM_IP

# Configurer le firewall Ubuntu
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
sudo netfilter-persistent save
```

### 4. Installer Docker et Docker Compose

```bash
# Mettre à jour le système
sudo apt update && sudo apt upgrade -y

# Installer Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Ajouter votre utilisateur au groupe docker
sudo usermod -aG docker $USER

# Se reconnecter pour appliquer les changements
exit
# SSH à nouveau

# Vérifier l'installation
docker --version

# Installer Docker Compose
sudo apt install docker-compose -y
```

### 5. Installer Appwrite

```bash
# Créer un dossier pour Appwrite
mkdir appwrite
cd appwrite

# Télécharger et installer Appwrite
docker run -it --rm \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume "$(pwd)"/appwrite:/usr/src/code/appwrite:rw \
  --entrypoint="install" \
  appwrite/appwrite:1.5.7
```

### 6. Configuration Interactive

Répondez aux questions :
```
? Choose your server HTTP port: (default: 80) 80
? Choose your server HTTPS port: (default: 443) 443
? Choose a secret API key (_APP_KEY): [Généré automatiquement]
? Enter your Appwrite hostname (localhost): YOUR_VM_IP
? Enter a DNS A record hostname to serve as a CNAME: (Optional) leave empty
```

### 7. Démarrer Appwrite

```bash
# Démarrer tous les services
docker-compose up -d

# Vérifier que tout fonctionne
docker ps

# Voir les logs
docker-compose logs -f appwrite
```

### 8. Accéder à Appwrite

1. Ouvrez votre navigateur
2. Allez sur `http://YOUR_VM_IP`
3. Créez votre premier compte admin
4. Vous êtes prêt ! 🎉

## 🔧 Configuration de votre App Flutter

Modifiez `appwrite_service.dart` :

```dart
// Avant (Local)
static const String endpoint = 'http://localhost/v1';

// Après (Oracle Cloud)
static const String endpoint = 'http://YOUR_VM_IP/v1';
// OU avec domaine
static const String endpoint = 'https://your-domain.com/v1';
```

## 🌐 Ajouter un nom de domaine (Optionnel)

### Avec Cloudflare (Gratuit) :
1. Ajoutez votre domaine à Cloudflare
2. Créez un enregistrement A :
   - Type: A
   - Name: @ ou appwrite
   - Content: YOUR_VM_IP
   - Proxy: ON (pour SSL gratuit)

3. Mettez à jour Appwrite :
```bash
cd appwrite
nano .env

# Changez _APP_DOMAIN_TARGET
_APP_DOMAIN_TARGET=your-domain.com

# Redémarrez
docker-compose down
docker-compose up -d
```

## 🔒 Activer HTTPS (Avec Domaine)

### Utiliser Let's Encrypt :
```bash
# Installer Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtenir un certificat
sudo certbot --nginx -d your-domain.com

# Auto-renouvellement
sudo certbot renew --dry-run
```

### OU Utiliser Cloudflare SSL :
- Activez "Full (strict)" SSL dans Cloudflare
- Cloudflare gère automatiquement le certificat
- Aucune configuration supplémentaire nécessaire

## 📊 Monitoring

### Vérifier l'utilisation des ressources :
```bash
# CPU et RAM
htop

# Espace disque
df -h

# Logs Appwrite
docker-compose logs -f

# État des conteneurs
docker stats
```

### Nettoyer les images inutilisées :
```bash
docker system prune -a
```

## 🔄 Mise à jour d'Appwrite

```bash
cd appwrite

# Sauvegarder les données
docker-compose exec appwrite backup

# Mettre à jour
docker-compose pull
docker-compose up -d

# Vérifier
docker-compose ps
```

## 💾 Backup Automatique

Créez un script de backup :
```bash
nano ~/backup-appwrite.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/home/ubuntu/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup des volumes Docker
docker run --rm \
  --volumes-from appwrite \
  -v $BACKUP_DIR:/backup \
  ubuntu tar czf /backup/appwrite_$DATE.tar.gz /storage

# Garder seulement les 7 derniers backups
find $BACKUP_DIR -name "appwrite_*.tar.gz" -mtime +7 -delete
```

```bash
# Rendre exécutable
chmod +x ~/backup-appwrite.sh

# Ajouter au cron (tous les jours à 2h)
crontab -e
# Ajouter :
0 2 * * * /home/ubuntu/backup-appwrite.sh
```

## 🚨 Dépannage

### Les services ne démarrent pas :
```bash
# Vérifier les logs
docker-compose logs

# Redémarrer
docker-compose restart
```

### Pas d'accès depuis l'extérieur :
```bash
# Vérifier le firewall
sudo iptables -L -n

# Vérifier qu'Appwrite écoute
sudo netstat -tulpn | grep 80
```

### Manque d'espace disque :
```bash
# Nettoyer Docker
docker system prune -a --volumes

# Voir l'utilisation
du -sh /var/lib/docker
```

## 💡 Optimisations

### 1. Limiter la RAM de MariaDB :
```bash
cd appwrite
nano docker-compose.yml

# Dans le service mariadb, ajoutez :
environment:
  - MYSQL_INNODB_BUFFER_POOL_SIZE=512M
```

### 2. Activer la compression :
```bash
# Dans .env
_APP_OPTIONS_COMPRESSION=gzip
```

### 3. Utiliser Redis pour le cache :
Redis est déjà inclus dans Appwrite, rien à faire !

## 📚 Ressources

- [Documentation Appwrite](https://appwrite.io/docs)
- [Oracle Cloud Free Tier](https://www.oracle.com/cloud/free/)
- [Appwrite GitHub](https://github.com/appwrite/appwrite)
- [Community Discord](https://appwrite.io/discord)

## ✅ Checklist Finale

- [ ] VM créée et accessible
- [ ] Firewall configuré (Oracle + Ubuntu)
- [ ] Docker et Docker Compose installés
- [ ] Appwrite installé et démarré
- [ ] Console accessible via navigateur
- [ ] Compte admin créé
- [ ] Projet créé dans Appwrite
- [ ] Database et collections créées
- [ ] App Flutter connectée
- [ ] Backup configuré
- [ ] (Optionnel) Domaine configuré
- [ ] (Optionnel) HTTPS activé

## 🎉 Félicitations !

Votre Appwrite est maintenant hébergé gratuitement sur Oracle Cloud et prêt pour la production !

---

**Coût total** : **0€ / mois** ✨
