# Plan de Test - Stratégie Mot de Passe Temporaire

**Date:** 2026-05-19  
**Scope:** Création gestionnaire avec mot de passe temporaire + changement obligatoire  
**Status:** À tester

---

## 📋 Scénarios de Test

### ✅ TEST 1: Admin crée gestionnaire → Réponse 200 + Email envoyé

**Étapes:**
1. Se connecter comme admin
2. Naviguer vers `/admin/gestionnaires` → Bouton "Créer"
3. Remplir le formulaire:
   - Prénom: Jean
   - Nom: Dupont
   - Email: jean.dupont@test.fr
   - Téléphone: +226 70000001
   - Parking: Sélectionner un parking
4. Compléter les documents (optionnels)
5. Soumettre le formulaire

**Attendre:**
- ✅ Réponse 200 du backend
- ✅ Message de succès: "Identifiants temporaires envoyés à jean.dupont@test.fr"
- ✅ Toast: "Gestionnaire créé"
- ✅ Email reçu avec password temporaire (format `Gestionnaire@XXXX`)
- ✅ Page de succès affichée

**Vérifier en DB:**
```sql
SELECT id_utilisateur, email, mot_de_passe_temporaire, statut_compte 
FROM utilisateur WHERE email='jean.dupont@test.fr';
```
- `mot_de_passe_temporaire` = true
- `statut_compte` = 'actif'
- `mot_de_passe_hash` ≠ NULL (hasté avec bcrypt)

---

### ✅ TEST 2: Gestionnaire reçoit email avec `Gestionnaire@XXXX` unique

**Vérifier:**
1. Email reçu contient:
   - ✅ Email du compte
   - ✅ Mot de passe temporaire en clair (format `Gestionnaire@XXXX`, ex: `Gestionnaire@7392`)
   - ✅ Avertissement: "Ce mot de passe ne fonctionnera qu'une seule fois"
   - ✅ Instructions pour première connexion
   - ✅ Lien vers `/login`
   - ✅ Parking assigné

2. Créer 2 gestionnaires et vérifier que les mots de passe sont **différents**
   - Email 1: `Gestionnaire@1234`
   - Email 2: `Gestionnaire@5678`
   - ❌ Ne PAS `Gestionnaire@1111` pour tous

**Vérifier en DB:**
```sql
SELECT email, mot_de_passe_hash FROM utilisateur 
WHERE email IN ('first@test.fr', 'second@test.fr');
```
- Les deux `mot_de_passe_hash` sont différents

---

### ✅ TEST 3: Gestionnaire se connecte avec credentials temporaires → Login OK + Redirection

**Étapes:**
1. Ouvrir `/login`
2. Entrer:
   - Email: `jean.dupont@test.fr`
   - Password: `Gestionnaire@7392` (depuis l'email)
3. Cliquer "Connexion"

**Attendre:**
- ✅ Réponse 200 du login
- ✅ Response contient `mot_de_passe_temporaire: true`
- ✅ Tokens reçus (access_token, refresh_token)
- ✅ **Redirection automatique vers `/auth/change-password`** (PAS vers dashboard)
- ✅ Page "Changer le mot de passe" affichée

**Logs backend:**
```
[AUTH] Login successful: jean.dupont@test.fr
[PASSWORD] User has temporary password - must change before accessing other resources
```

---

### ✅ TEST 4: Gestionnaire essaie d'accéder à dashboard directement → Bloqué 403

**Étapes:**
1. (Depuis TEST 3, connecté avec password temporaire)
2. Essayer d'accéder à `/dashboard` directement (URL bar)

**Attendre:**
- ✅ Erreur 403 Forbidden
- ✅ Code d'erreur: `PASSWORD_CHANGE_REQUIRED`
- ✅ Message: "Vous devez changer votre mot de passe avant d'accéder à cette ressource"
- ✅ Redirection automatique vers `/auth/change-password`

---

### ✅ TEST 5: Gestionnaire change son mot de passe → Succès + Redirection Dashboard

**Étapes:**
1. Être sur `/auth/change-password`
2. Remplir:
   - Mot de passe actuel: `Gestionnaire@7392`
   - Nouveau mot de passe: `SecureP@ssw0rd123`
   - Confirmer: `SecureP@ssw0rd123`
3. Cliquer "Mettre à jour"

**Attendre:**
- ✅ Validation passe:
  - Min 12 caractères ✅
  - Majuscule (S) ✅
  - Minuscule (ecure) ✅
  - Chiffre (0, 123) ✅
  - Spécial (@) ✅
- ✅ Réponse 200 du backend
- ✅ Message: "Mot de passe changé avec succès"
- ✅ Toast: "Mot de passe modifié"
- ✅ **Redirection vers dashboard** (ou page d'accueil appropriée)

**Vérifier en DB:**
```sql
SELECT email, mot_de_passe_temporaire FROM utilisateur 
WHERE email='jean.dupont@test.fr';
```
- `mot_de_passe_temporaire` = false
- `mot_de_passe_hash` est le nouveau hash (différent d'avant)

---

### ✅ TEST 6: Gestionnaire se reconnecte avec nouveau mot de passe → Accès normal

**Étapes:**
1. Déconnecte (logout)
2. Aller à `/login`
3. Entrer:
   - Email: `jean.dupont@test.fr`
   - Password: `SecureP@ssw0rd123` (le nouveau)
4. Cliquer "Connexion"

**Attendre:**
- ✅ Login réussi
- ✅ Response contient `mot_de_passe_temporaire: false`
- ✅ **Pas de redirection vers /auth/change-password**
- ✅ Redirection vers dashboard
- ✅ Accès complet à tous les endpoints

---

### ✅ TEST 7: Validation mot de passe strict au changement

**Étapes:**
1. Essayer de changer le password avec des entrées invalides:

**Test 7a - Moins de 12 caractères:**
- Nouveau: `Short@123`
- **Attendre:** ❌ Erreur "12 caractères minimum"

**Test 7b - Pas de majuscule:**
- Nouveau: `newpassword@123`
- **Attendre:** ❌ Erreur "majuscule requise"

**Test 7c - Pas de minuscule:**
- Nouveau: `NEWPASSWORD@123`
- **Attendre:** ❌ Erreur "minuscule requise"

**Test 7d - Pas de chiffre:**
- Nouveau: `NewPassword@!`
- **Attendre:** ❌ Erreur "chiffre requis"

**Test 7e - Pas de caractère spécial:**
- Nouveau: `NewPassword123`
- **Attendre:** ❌ Erreur "caractère spécial (@$!%*?&) requis"

**Test 7f - Ancien mot de passe incorrect:**
- Ancien: `WrongPassword`
- Nouveau: `NewSecure@123`
- **Attendre:** ❌ Erreur 401 "Mot de passe actuel incorrect"

---

### ✅ TEST 8: Deux gestionnaires créés → Mots de passe différents

**Étapes:**
1. Créer gestionnaire 1:
   - Email: `manager1@test.fr`
   - Récupérer mot de passe: `Gestionnaire@1111`

2. Créer gestionnaire 2:
   - Email: `manager2@test.fr`
   - Récupérer mot de passe: `Gestionnaire@2222`

3. Vérifier en DB:
   ```sql
   SELECT email, mot_de_passe_hash FROM utilisateur 
   WHERE email IN ('manager1@test.fr', 'manager2@test.fr');
   ```

**Attendre:**
- ✅ Email 1 reçoit `Gestionnaire@1111`
- ✅ Email 2 reçoit `Gestionnaire@2222`
- ✅ Les deux password hashes sont différents en DB
- ✅ Les deux gestionnaires peuvent se connecter indépendamment

---

### ✅ TEST 9: Après changement, accès à /auth/change-password bloqué

**Étapes:**
1. Être connecté avec password permanent (`mot_de_passe_temporaire: false`)
2. Essayer d'accéder à `/auth/change-password` directement

**Attendre:**
- ✅ Page affichée (endpoint existe et est accessible)
- OU ❌ Redirection vers `/profil/mot-de-passe` (si c'est la route alternative)
- ℹ️ Clarifier: est-ce une route "change password général" accessible après?

---

## 🔍 Vérifications Transversales

### Logs Backend
```
✅ Docker logs doivent montrer:
- [GESTIONNAIRE_CREATED] admin={adminId} gestionnaire={gestionnaireId}
- [PASSWORD_CHANGED] user={gestionnaireId}
- ❌ [PASSWORD] {tempPassword} — NE DOIT JAMAIS LOGGER le password en clair
```

### Base de Données
```
✅ Pas de colonnes d'invitation restantes:
SELECT COUNT(*) FROM utilisateur 
WHERE invitation_token IS NOT NULL;
→ Résultat: 0

✅ Nouveau champ presence:
SELECT COUNT(*) FROM utilisateur 
WHERE mot_de_passe_temporaire IS NOT NULL;
→ Résultat: >0 (au moins nos gestionnaires)
```

### Sécurité
- ✅ Password temporaire JAMAIS retourné dans la réponse HTTP
- ✅ Password temporaire UNIQUEMENT en email (en clair, une seule fois)
- ✅ Password new n'accepte PAS les formats faibles
- ✅ Ancien password vérifié avant changement (bcrypt.compare)
- ✅ Middleware bloque accès tant que `mot_de_passe_temporaire: true`

---

## 📊 Résumé des Résultats

| Test | Statut | Notes |
|------|--------|-------|
| 1. Création gestionnaire | ⏳ | À exécuter |
| 2. Email unique | ⏳ | À exécuter |
| 3. Login → Redirection | ⏳ | À exécuter |
| 4. Dashboard bloqué 403 | ⏳ | À exécuter |
| 5. Changement password | ⏳ | À exécuter |
| 6. Reconnexion normal | ⏳ | À exécuter |
| 7. Validation stricte | ⏳ | À exécuter |
| 8. Mots de passe uniques | ⏳ | À exécuter |
| 9. Post-changement | ⏳ | À exécuter |

---

**À faire avant de considérer comme COMPLET:**
- [ ] Tous les 9 tests exécutés
- [ ] Aucun test en ❌
- [ ] Logs backend vérifiés
- [ ] DB vérifiée
- [ ] Performance acceptable (< 2s par requête)
- [ ] Pas d'erreurs non gérées dans console
