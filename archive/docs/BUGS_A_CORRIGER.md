# 🐛 Liste des bugs à corriger après déploiement

## 1. Badges de likes non visibles dans la navigation
**Symptôme**: Les badges de compteur de likes n'apparaissent pas dans la barre de navigation

**Cause probable**: 
- `_likesViewed = true` fait afficher 0 même avec des likes
- OU Realtime ne fonctionne pas correctement

**À vérifier**:
- [ ] Y a-t-il vraiment des likes dans la page Likes ?
- [ ] Les logs montrent-ils des likes reçus ?
- [ ] Realtime fonctionne-t-il (logs dans console) ?

**Solution à tester**:
- Forcer un rafraîchissement périodique des compteurs
- Vérifier les subscriptions Realtime

---

## 2. Thème de couleurs partagé entre utilisateurs (Web)
**Symptôme**: Le thème d'un utilisateur s'applique aux autres quand on change de compte

**Cause**: `localStorage` partagé en web sur le même navigateur

**Solutions possibles**:
1. **Solution immédiate**: Documenter que chaque utilisateur doit utiliser un navigateur différent ou mode privé
2. **Solution technique**: Stocker les préférences dans Appwrite (base de données) au lieu du localStorage
3. **Solution temporaire**: Préfixer TOUTES les clés localStorage avec userId

---

## 3. Décompte de swipes partagé entre utilisateurs (Web)
**Symptôme**: Les limites de swipes d'un utilisateur affectent l'autre

**Cause**: Même que #2 - localStorage partagé

**Note**: Le code utilise déjà `userId` dans les clés, donc ça DEVRAIT fonctionner

**À vérifier**:
- [ ] Les logs montrent-ils le bon userId ?
- [ ] Les clés localStorage sont-elles bien préfixées ?

---

## 4. Autres bugs à documenter

Ajoutez ici les bugs que vous découvrez pendant les tests:

### Bug #4: [Description]
**Symptôme**: 

**Étapes pour reproduire**:
1. 
2. 
3. 

**Comportement attendu**:

**Comportement actuel**:

---

### Bug #5: [Description]
**Symptôme**: 

**Étapes pour reproduire**:
1. 
2. 
3. 

**Comportement attendu**:

**Comportement actuel**:

---

## Priorités de correction

### 🔴 Critique (bloquer l'utilisation)
- [ ] 

### 🟠 Important (gênant mais contournable)
- [ ] Badges de likes
- [ ] Thème partagé (contournable avec navigateurs différents)

### 🟡 Mineur (amélioration UX)
- [ ] 

---

## Notes pour la session de correction

**Ordre suggéré**:
1. D'abord déployer en production
2. Tester sur le site déployé (peut révéler de nouveaux bugs)
3. Corriger les bugs critiques en priorité
4. Redéployer
5. Corriger les bugs importants
6. Améliorer l'UX

