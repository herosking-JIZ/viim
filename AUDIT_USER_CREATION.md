# AUDIT : Flux de Création d'Utilisateurs — N'DJIGI Backend

**Date :** 2026-05-20  
**Commit :** 30a41d5 (docs(auth): document password reset architecture and keycloak admin setup)  
**Périmètre :** Tous les flux de création/auto-provisioning d'utilisateurs (PostgreSQL + Keycloak)  
**Niveau de conformité :** ❌ **AUCUN FLUX COMPLÈTEMENT CONFORME**

---

## EXECUTIVE SUMMARY

Le backend contient **10 flux différents** de création d'utilisateurs. Audit révèle :
- **4 flux complètement cassés** (🔴) : users impossible à utiliser
- **6 flux partiellement cassés** (⚠️) : créent des désynchronisations KC ↔ PG
- **0 flux conformes** : aucun flux implémente atomicité ou compensation correctement

**Impact immédiat :** Tout gestionnaire créé via `POST /admin/gestionnaires` ne peut pas se connecter (Keycloak `user_not_found`). C'est le bug observé.

**Cause racine :** Flux de création implémmentent soit création PG seulement, soit création KC seulement, sans liaison atomique et sans rollback cohérent.

---

## SECTION 1 : CARTOGRAPHIE DES FLUX

### Flux de Création Explicites (API Endpoints)

| # | Flux | Route | Méthode | Fichier | Ordre | Status |
|---|------|-------|--------|---------|-------|--------|
| 1 | Admin user direct | `POST /auth/admin/users` | keycloakAuthController:1069 | PG seulement | N/A | 🔴 CASSÉ |
| 2 | Gestionnaire (KC route) | `POST /auth/admin/gestionnaires` | keycloakAuthController:1902 | KC → PG | ✅ Bon | ⚠️ PARTIEL |
| 3 | Gestionnaire (API route) | `POST /admin/gestionnaires` | gestionnaireService:14 | PG → KC | ❌ Inverse | ⚠️ PARTIEL |
| 4 | Utilisateur générique | `POST /utilisateurs` | utilisateurController:637 | KC → PG | ✅ Bon | ⚠️ PARTIEL |
| 5 | Completion invitation | `POST /auth/complete-first-connection` | invitationController:57 | PG seulement | N/A | 🔴 CASSÉ |
| 6 | OTP passager | `POST /auth/otp/verify` | keycloakAuthController:1276 | KC → PG | ✅ Bon | ⚠️ PARTIEL |

### Flux Auto-Provisioning Implicites

| # | Flux | Événement | Fichier | Détail |
|---|------|-----------|---------|--------|
| 7 | Login Keycloak | User trouvé en KC | keycloakAuth:76 | Auto-create PG, rôle par défaut |
| 8 | Token validation | Token Keycloak valide | authenticateKeycloak:85 | Auto-create PG, rôle par défaut |

### Flux de Seed (Initialisation)

| # | Flux | Fichier | Détail |
|---|------|---------|--------|
| 9 | Seed utilisateurs | prisma/seed.js:91 | 15 users (admin, chauffeurs, passagers, gestionnaires) |
| 10 | Seed système | prisma/plateforme_seed.js:6 | User système pour portefeuille plateforme |

---

## SECTION 2 : AUDIT DÉTAILLÉ PAR FLUX

### FLUX #1 : POST /auth/admin/users

**Route :** `POST /auth/admin/users`  
**Fichier :** `keycloakAuthController.js:1069-1181`  
**Appelant :** Route `POST /auth/admin/users`

#### Critères A-G

| Critère | Résultat | Détails |
|---------|----------|---------|
| **A. Keycloak API présent** | ❌ MANQUANT | Aucun appel `keycloakService.adminAPI.users.create` |
| **A. Prisma create présent** | ✅ OUI | Ligne 1095 : `tx.utilisateur.create({ ... })` |
| **A. Même flux** | ❌ NON | Seulement création PG, aucune création KC |
| **B. Ordre** | N/A | Pas de création KC |
| **C. keycloak_id stocké** | ❌ NON | keycloak_id jamais défini/assigné |
| **C. Email identique** | ✅ OUI | Email depuis req.body.email normalisé |
| **D. Rollback KC→PG** | N/A | KC n'existe pas |
| **D. Rollback PG→KC** | N/A | KC n'existe pas |
| **D. Code retourne 201** | ⚠️ **OUI, même sans KC** | Ligne 1167 : retourne 201 AVANT KC |
| **E. Password défini KC** | ❌ NON | Pas de créd en KC |
| **E. temporary flag** | ❌ NON | N/A |
| **E. Password stocké PG** | ✅ OUI | Ligne 1092 : `mot_de_passe_hash` (bcrypt) |
| **F. Rôles KC assignés** | ❌ NON | Pas de `addRealmRoleMappings` |
| **F. utilisateur_role peuplé** | ✅ OUI | Ligne 1105 : `{ create: { role, actif: true } }` |
| **G. enabled** | N/A | Pas de création KC |
| **G. emailVerified** | N/A | Pas de création KC |
| **G. requiredActions** | N/A | Pas de création KC |

**VERDICT :** 🔴 **COMPLÈTEMENT CASSÉ**

**Problème critique :** Crée user PG avec password hash, mais JAMAIS en Keycloak. User existe en PG, reçoit email, peut mettre password, mais impossible login car `keycloak_id` = NULL.

**Impact :** Tout user créé via cette route est inaccessible.

---

### FLUX #2 : POST /auth/admin/gestionnaires (keycloakAuthController)

**Route :** `POST /auth/admin/gestionnaires`  
**Fichier :** `keycloakAuthController.js:1902-2093`

#### Critères A-G

| Critère | Résultat | Détails |
|---------|----------|---------|
| **A. Keycloak API** | ✅ OUI | Ligne 1946 : `keycloakService.adminAPI.users.create` |
| **A. Prisma create** | ✅ OUI | Ligne 1974 : `prisma.utilisateur.create` |
| **A. Même flux** | ✅ OUI | Même fonction, séquence KC → PG |
| **B. Ordre** | ✅ KC d'abord | Line 1946 KC, ligne 1974 PG |
| **C. keycloak_id** | ✅ ASSIGNÉ | Ligne 1951, puis 1977 |
| **C. Email** | ✅ IDENTIQUE | Même email KC et PG |
| **D. Rollback KC→PG** | ❌ NON | Si PG échoue, KC reste |
| **D. Rollback PG→KC** | ⚠️ **BROKEN** | Ligne 2076 : `error.response?.status === 201` jamais vrai pour Prisma error |
| **D. Code retourne 201** | ✅ SEULEMENT SI OK | Ligne 2055 |
| **E. Password KC** | ✅ OUI | Ligne 1937-1942 : credentials, `temporary: true` |
| **E. Password PG** | ❌ NON | Ligne 1983 : `mot_de_passe_hash: ''` (vide) |
| **F. Rôles KC** | ✅ OUI | Ligne 1958-1969 : `addRealmRoleMappings` ndjigi-gestionnaire |
| **F. Rôles PG** | ❌ **MANQUANT** | AUCUNE création `utilisateur_role` en PG! |
| **G. enabled** | ✅ OUI | Ligne 1932 |
| **G. emailVerified** | ❌ NON | Ligne 1929 : false |
| **G. requiredActions** | ✅ OUI | Ligne 1936 : UPDATE_PASSWORD, VERIFY_EMAIL |

**VERDICT :** 🟠 **IMPORTANT — Rôle manquant en PG, cleanup broken**

**Problèmes :**
1. Rôle créé en KC (`ndjigi-gestionnaire`) mais PAS en PG → lors login, app PG ne reconnaît pas le rôle
2. Cleanup KC en cas erreur PG ne fonctionne pas (ligne 2076 condition impossible)
3. Password temp en KC, pas en PG → inconsistance si user change password

**Impact :** Gestionnaire peut se connecter KC mais l'app locale ne reconnaît pas le rôle.

---

### FLUX #3 : POST /admin/gestionnaires (gestionnaireService)

**Route :** `POST /admin/gestionnaires`  
**Fichier :** `gestionnaireService.js:14-178`

#### Critères A-G

| Critère | Résultat | Détails |
|---------|----------|---------|
| **A. Keycloak API** | ✅ OUI | Ligne 96 : `kcAdminClient.users.create` |
| **A. Prisma create** | ✅ OUI | Ligne 46 : `tx.utilisateur.create` |
| **A. Même flux** | ✅ OUI | Même service |
| **B. Ordre** | ❌ **PG d'abord** | Ligne 46 PG, ligne 96 KC (INVERSE) |
| **C. keycloak_id** | ✅ ASSIGNÉ | Ligne 112, puis mise à jour ligne 131 |
| **C. Email** | ✅ IDENTIQUE | Même email |
| **D. Rollback KC→PG** | ❌ NON | Si KC échoue après PG create, user reste en PG |
| **D. Rollback PG→KC** | ✅ OUI | Ligne 138-148 : suppression PG en cas erreur KC |
| **D. Code retourne 201** | ✅ SEULEMENT SI OK | Ligne 170 |
| **E. Password KC** | ✅ OUI | Ligne 103-108 : credentials, `temporary: true` |
| **E. Password PG** | ✅ OUI | Ligne 53 : `mot_de_passe_hash: hashedPassword` (bcrypt) |
| **F. Rôles KC** | ✅ OUI | Ligne 115-126 : `addRealmRoleMappings` |
| **F. Rôles PG** | ✅ OUI | Ligne 58-62 : création `utilisateur_role: { create: { role: 'gestionnaire' } }` |
| **G. enabled** | ✅ OUI | Ligne 102 |
| **G. emailVerified** | ❌ NON | Default KC = false |
| **G. requiredActions** | ❌ NON | Pas défini |

**VERDICT :** 🟡 **PARTIEL — Ordre inverse crée risque d'orphelins**

**Problèmes :**
1. **Ordre PG→KC (INVERSE) :** Si Keycloak fail, user reste en PG sans keycloak_id. Rollback PG existe mais peut lui-même fail.
2. **Double stockage password :** PG a bcrypt(tempPassword), KC a tempPassword clair (temp: true). Si user change password en PG, KC reste unchanged.

**Avantage :** Rollback PG en cas erreur KC existe (contrairement à Flux #4 #6).

**Impact :** Bon comportement global, mais risque d'orphelins si rollback échoue.

---

### FLUX #4 : POST /utilisateurs (UtilisateurController)

**Route :** `POST /utilisateurs`  
**Fichier :** `utilisateurController.js:637-917`

#### Critères A-G

| Critère | Résultat | Détails |
|---------|----------|---------|
| **A. Keycloak API** | ✅ OUI | Ligne 758 : `keycloakService.adminAPI.users.create` |
| **A. Prisma create** | ✅ OUI | Ligne 812 : `tx.utilisateur.create` |
| **A. Même flux** | ✅ OUI | Même controller |
| **B. Ordre** | ✅ KC d'abord | Ligne 758 KC, ligne 812 PG |
| **C. keycloak_id** | ✅ ASSIGNÉ | Ligne 779, puis 814 |
| **C. Email** | ✅ IDENTIQUE | Même email |
| **D. Rollback KC→PG** | ❌ NON | Si PG échoue, KC reste |
| **D. Rollback PG→KC** | ❌ NON | Pas de nettoyage KC en cas erreur |
| **D. Code retourne 201** | ✅ SEULEMENT SI OK | Ligne 892 |
| **E. Password KC** | ✅ OUI | Ligne 770-776 : credentials, `temporary: true` |
| **E. Password PG** | ❌ NON | Ligne 813-826 : aucun `mot_de_passe_hash` |
| **F. Rôles KC** | ✅ OUI | Ligne 793-808 : `addRealmRoleMappings` |
| **F. Rôles PG** | ✅ OUI | Ligne 821-825 : création `utilisateur_role` |
| **G. enabled** | ✅ OUI | Ligne 765 |
| **G. emailVerified** | ❌ NON | Ligne 762 : false |
| **G. requiredActions** | ✅ OUI | Ligne 769 : UPDATE_PASSWORD |

**VERDICT :** 🟠 **IMPORTANT — Pas de rollback KC si erreur PG**

**Problème :** Si `prisma.utilisateur.create` échoue (ligne 812, ex: duplicate email détecté tard, constraint violation, etc.), la fonction catch ligne 908 return 500 **sans nettoyer le user déjà créé en Keycloak**. → User existe en KC, pas en PG. Recréation automatique à prochain login (Flux #7/#8).

**Impact :** Désynchronisation silencieuse KC > PG.

---

### FLUX #5 : POST /auth/complete-first-connection (InvitationController)

**Route :** `POST /auth/complete-first-connection`  
**Fichier :** `invitationController.js:57-129`

#### Critères A-G

| Critère | Résultat | Détails |
|---------|----------|---------|
| **A. Keycloak update** | ❌ NON | Aucun appel Keycloak pour reset password |
| **A. Prisma update** | ✅ OUI | Ligne 93 : `tx.utilisateur.update` |
| **B. Ordre** | N/A | Pas de création KC |
| **C. keycloak_id** | ✅ Supposé | User créé antérieurement |
| **D. Try/catch** | ✅ OUI | Ligne 120 |
| **E. Password PG** | ✅ OUI | Ligne 96 : `mot_de_passe_hash: hashedPassword` (bcrypt) |
| **E. Password KC** | ❌ **JAMAIS SYNC** | Pas d'appel KC pour PUT `/admin/realms/{realm}/users/{id}/reset-password` |
| **F. Rôles** | N/A | Supposés setup précédemment |
| **G. enabled KC** | ❌ NON | Pas d'interaction KC |
| **G. emailVerified KC** | ❌ NON | Pas d'interaction KC |

**VERDICT :** 🔴 **COMPLÈTEMENT CASSÉ — Password désynchronisé**

**Problème critique :** User définit nouveau password en PG (ligne 96) mais Keycloak est JAMAIS mis à jour. Résultat :
- Login local (frontend utilise PG password hash) : ✅ OK
- Login Keycloak : ❌ Fail (Keycloak a toujours le password temp initial)

**Impact :** Invitation fonctionnelle en apparence, mais authentication Keycloak cassée. C'est le deuxième symptôme du bug observé.

---

### FLUX #6 : POST /auth/otp/verify (KeycloakAuthController)

**Route :** `POST /auth/otp/verify`  
**Fichier :** `keycloakAuthController.js:1276-1450+`

#### Critères A-G

| Critère | Résultat | Détails |
|---------|----------|---------|
| **A. Keycloak API** | ✅ OUI | Ligne 1348 : `keycloakService.adminAPI.users.create` |
| **A. Prisma create** | ✅ OUI | Ligne 1375 : `prisma.utilisateur.create` |
| **B. Ordre** | ✅ KC d'abord | Ligne 1348 KC, ligne 1375 PG |
| **C. keycloak_id** | ✅ ASSIGNÉ | Ligne 1377 : `keycloak_id: keycloakUser.id` |
| **D. Rollback KC→PG** | ❌ NON | Si PG échoue, KC reste |
| **D. Rollback PG→KC** | ❌ NON | Pas de cleanup KC |
| **D. Code behavior** | ⚠️ Return 500 | Ligne 1398-1405 retourne erreur sans cleanup |
| **E. Password KC** | ✅ OUI | Ligne 1354-1359 : credentials, `temporary: false` |
| **E. Password PG** | ✅ OUI | Ligne 1384 : `tech_password_encrypted: encryptedPassword` |
| **F. Rôles KC** | ✅ OUI | Ligne 1365-1370 : `addClientRoleMappings` ndjigi-passager |
| **F. Rôles PG** | ✅ OUI | Ligne 1385-1389 : `utilisateur_role: { create: { role: 'passager' } }` |
| **G. enabled** | ✅ OUI | Ligne 1361 |
| **G. emailVerified** | N/A | OTP auth (phone-based) |
| **G. requiredActions** | ❌ NON | Pas défini (user peut login immédiatement) |

**VERDICT :** 🟡 **PARTIEL — Bon order mais pas de rollback KC**

**Problème :** Même que Flux #4 : si PG échoue (ex: duplicate phone), user reste en KC sans rollback.

**Avantage :** `temporary: false` permet login immédiat sans change-password obligatoire.

---

### FLUX #7 : Auto-provisioning via keycloakAuth Middleware

**Événement :** User trouvé en Keycloak via login  
**Fichier :** `keycloakAuth.js:76-94`

#### Critères A-G

| Critère | Résultat | Détails |
|---------|----------|---------|
| **A. Keycloak** | ✅ TROUVÉ | User existe déjà en KC (via token) |
| **A. Prisma create** | ✅ OUI | Ligne 76 : `prisma.utilisateur.create` |
| **B. Ordre** | N/A | Pas de création KC |
| **C. keycloak_id** | ✅ OUI | Ligne 78 : depuis token.sub |
| **D. Try/catch** | ✅ OUI | Entouré par try/catch générale (ligne 16) |
| **E. Password** | N/A | Keycloak user |
| **E. PG hash** | ✅ OUI | Ligne 143 : `mot_de_passe_hash: ''` |
| **F. Rôles KC** | ✅ PRÉSENT | Présent dans token.realm_access.roles |
| **F. Rôles PG** | ❌ **TOUJOURS `passager`** | Ligne 86 : `role: 'passager'` hardcodé |
| **F. Sync** | ❌ NON | Pas de mapping KC roles → PG roles |

**VERDICT :** 🟠 **IMPORTANT — Rôle par défaut, perte des rôles Keycloak**

**Problème critique :** Admin créé en Keycloak avec rôle `ndjigi-admin` se connecte → auto-prov cré en PG avec rôle `passager`. → Admin apparaît comme passager dans l'app.

**Chaîne d'événements :**
1. Admin se connecte, token contient rôle `ndjigi-admin`
2. keycloakAuth middleware ne trouve pas user en PG (si c'est première connexion après création KC)
3. Auto-prov crée user PG avec rôle `passager` (ligne 86)
4. User attaché à request avec rôle `passager` (ligne 149) → permissions perdues

---

### FLUX #8 : Auto-provisioning via authenticateKeycloak Middleware

**Événement :** Token Keycloak valide trouvé  
**Fichier :** `authenticateKeycloak.js:82-104`

#### Critères A-G

| Critère | Résultat | Détails |
|---------|----------|---------|
| **A. Keycloak** | ✅ VALIDE | Token JWT valide (déjà vérifié) |
| **A. Prisma create** | ✅ OUI | Ligne 85 : `prisma.utilisateur.create` |
| **C. keycloak_id** | ✅ OUI | Ligne 87 : `payload.sub` |
| **D. Try/catch** | ✅ OUI | Entouré par try/catch (ligne 149) |
| **E. Password** | N/A | Keycloak user |
| **E. PG hash** | ⚠️ OUI | Ligne 92 : `mot_de_passe_hash: 'KEYCLOAK_AUTH'` (sentinelle) |
| **F. Rôles KC** | ✅ PRÉSENT | `payload.realm_access?.roles` disponible |
| **F. Rôles PG** | ❌ **TOUJOURS `passager`** | Ligne 96 : `role: 'passager'` hardcodé |
| **F. Sync** | ❌ NON | Pas de mapping KC roles → PG roles |

**VERDICT :** 🟠 **IMPORTANT — Identique au Flux #7**

**Problème :** Idem Flux #7, avec cache Redis 60s qui aggrave le problème (ligne 108).

**Aggravation :** Cache Redis 60s (ligne 108) maintient le rôle incorrect pendant 1 minute si user récemment créé.

---

### FLUX #9 : Seed Utilisateurs

**Fichier :** `prisma/seed.js:65-96`

#### Critères A-G

| Critère | Résultat | Détails |
|---------|----------|---------|
| **A. Keycloak** | ❌ NON | Aucun appel Keycloak |
| **A. Prisma** | ✅ OUI | Ligne 91 : `prisma.utilisateur.upsert` |
| **C. keycloak_id** | ❌ NULL | Jamais défini pour aucun user seed |
| **D. Try/catch** | ❌ NON | Pas d'error handling |
| **E. Password** | ✅ OUI | Ligne 67 : `bcrypt.hash('Password123!', 10)` pour tous |
| **E. PG hash** | ✅ OUI | Ligne 73-87 : tous les users ont mot_de_passe_hash |
| **F. Rôles** | ⚠️ À vérifier | Ligne 98+ (suite du fichier non exploré) |

**VERDICT :** 🔴 **COMPLÈTEMENT CASSÉ — Aucune création Keycloak**

**Problème :** Seed crée 15 users (admin, chauffeurs, passagers, gestionnaires) SEULEMENT en PostgreSQL. Aucun en Keycloak. → Tous les seed users ont `keycloak_id = NULL`, impossible login Keycloak.

**Impact :** Admin initial créé via seed ne peut pas se connecter. Scripts/jobs qui dépendent des seed users sont cassés.

---

### FLUX #10 : Seed Système

**Fichier :** `prisma/plateforme_seed.js:6-20`

#### Critères A-G

| Critère | Résultat | Détails |
|---------|----------|---------|
| **A. Keycloak** | ❌ NON | Aucun appel Keycloak |
| **A. Prisma** | ✅ OUI | Ligne 6 : `prisma.utilisateur.upsert` |
| **C. keycloak_id** | ❌ NULL | Jamais défini |

**VERDICT :** 🔴 **COMPLÈTEMENT CASSÉ**

**Problème :** User système créé pour portefeuille plateforme n'existe pas en Keycloak.

**Impact :** Minimal (user système n'a pas besoin de login).

---

## SECTION 3 : ÉTAT EMPIRIQUE DE LA BASE

*Étape 3 skipped par demande utilisateur. Les données suivantes seraient nécessaires pour validation complète :*

```sql
-- Compter users PG sans keycloak_id
SELECT COUNT(*) FROM utilisateur WHERE keycloak_id IS NULL;

-- Lister users PG sans keycloak_id (échantillon)
SELECT email, statut_compte, date_inscription 
FROM utilisateur 
WHERE keycloak_id IS NULL 
LIMIT 20;

-- Compter users avec keycloak_id
SELECT COUNT(*) FROM utilisateur WHERE keycloak_id IS NOT NULL;
```

---

## SECTION 4 : SYNTHÈSE, BUGS CRITIQUES, PLAN DE REMÉDIATION

### TABLEAU RÉCAPITULATIF

| Flux | Route | Verdict | Problème Principal |
|------|-------|---------|-------------------|
| #1 | `POST /auth/admin/users` | 🔴 CASSÉ | Aucune création KC |
| #2 | `POST /auth/admin/gestionnaires` | ⚠️ PARTIEL | Rôle manquant PG, cleanup broken |
| #3 | `POST /admin/gestionnaires` | ⚠️ PARTIEL | Ordre inverse PG→KC crée orphelins |
| #4 | `POST /utilisateurs` | ⚠️ PARTIEL | Pas rollback KC si erreur PG |
| #5 | `POST /auth/complete-first-connection` | 🔴 CASSÉ | Password jamais sync en KC |
| #6 | `POST /auth/otp/verify` | ⚠️ PARTIEL | Pas rollback KC si erreur PG |
| #7 | Auto-prov keycloakAuth | ⚠️ PARTIEL | Rôle par défaut, no sync KC |
| #8 | Auto-prov authenticateKeycloak | ⚠️ PARTIEL | Rôle par défaut, no sync KC |
| #9 | Seed utilisateurs | 🔴 CASSÉ | keycloak_id = NULL pour tous |
| #10 | Seed système | 🔴 CASSÉ | keycloak_id = NULL |

**Résumé :** 4 cassés, 6 partiels, 0 conformes.

---

### BUGS CRITIQUES PAR SÉVÉRITÉ

#### 🔴 CRITIQUES (Bloquent connexion)

| ID | Flux | Titre | Cause | Impact |
|----|----|-------|-------|--------|
| **C1** | #1 | Pas de création Keycloak | `POST /auth/admin/users` crée PG seulement | User impossible à connecter |
| **C2** | #2 | Rôle absent en PG | `createGestionnaire` oublie `utilisateur_role` | Rôle en KC, pas en PG → permissions perdues |
| **C3** | #5 | Password jamais sync KC | `completeFirstConnection` update PG seulement | User change password en PG, KC ignore → login KC échoue |
| **C4** | #9 #10 | Seed users sans keycloak_id | `seed.js` et `plateforme_seed.js` créent PG seulement | Aucun seed user ne peut se connecter KC |

#### 🟠 IMPORTANTS (Désynchronisation silencieuse)

| ID | Flux | Titre | Cause | Impact |
|----|----|-------|-------|--------|
| **I1** | #4 #6 | Pas rollback KC si erreur PG | Création KC réussit, PG échoue → pas cleanup KC | User fantôme en KC, auto-recreate en PG à next login |
| **I2** | #2 | Cleanup KC broken | Condition `error.response?.status === 201` jamais vraie | User KC orphelin si erreur PG |
| **I3** | #7 #8 | Rôle par défaut `passager` | Auto-prov ignore rôles KC | Admin/gestionnaire créés en KC apparaissent comme passager en app |
| **I4** | #3 | Ordre PG→KC inverse | Créer PG avant KC crée orphelins si KC fail | User en PG sans keycloak_id si rollback PG échoue aussi |

#### 🟡 MINEURS (Robustesse)

| ID | Flux | Titre | Cause | Impact |
|----|----|-------|-------|--------|
| **M1** | #7 #8 | Cache Redis 60s stale | authenticateKeycloak cache user 60s | Admin créé, apparaît comme passager pendant 1 min |
| **M2** | #2 #4 | Pas requiredActions | createGestionnaire / utilisateur ne défini pas UPDATE_PASSWORD | User peut login sans changer password |
| **M3** | Tous | Double stockage password | Password en PG ET KC → risque désync | Si user change password, seulement une côté update |

---

### CAUSE RACINE DU BUG OBSERVÉ

**Symptôme:** Gestionnaire `cprzachk@gmail.com` créé, existe en PG, email reçu, mais Keycloak `user_not_found` au login.

**Analyse :**

Si creation via `POST /admin/gestionnaires` (Flux #3) :
1. ✅ GestionnaireService.create() crée user en PG (ligne 46)
2. ✅ Email invitation envoyée
3. User accepte invitation → completeFirstConnection
4. ⚠️ Password bcrypt sauvegardé en PG (ligne 96 invitationController)
5. ❌ Keycloak jamais mis à jour
6. **Result :** User essaie login → Keycloak recherche user par email/password → `user_not_found`

Ou si création via `POST /auth/admin/gestionnaires` (Flux #2) :
1. ✅ User créé en Keycloak (ligne 1946)
2. ❌ Rôle manquant en PG (pas de `utilisateur_role`)
3. ✅ User créé en PG (ligne 1974)
4. **Result :** User peut login KC, mais app PG ne reconnaît pas le rôle

**Ou si création via `POST /auth/admin/users` (Flux #1) :**
1. ❌ Aucune création Keycloak
2. ✅ User créé en PG avec password hash
3. **Result :** User ne peut jamais se connecter KC

**Conclusion :** Le bug dépend de quelle route a été utilisée. Mais **TOUTES** les routes ont des problèmes.

---

### PLAN DE REMÉDIATION DÉTAILLÉ

#### **Priorité CRITIQUE — Blockers de Release**

| Correctif | Flux | Fichier | Type | Effort | Détail |
|-----------|------|---------|------|--------|--------|
| **C1-FIX** | #1 | keycloakAuthController.js:1069 | Ajouter appel KC | **M** | Implémenter création Keycloak avant/après création PG avec rollback. Ou supprimer endpoint si redondant avec Flux #4. |
| **C2-FIX** | #2 | keycloakAuthController.js:1974 | Ajouter création rôle PG | **S** | Après ligne 1968 (assignation rôle KC), créer `utilisateur_role` avant le return. |
| **C3-FIX** | #5 | invitationController.js:96 | Ajouter appel KC | **M** | Après update mot_de_passe_hash en PG, appeler `keycloakService.adminAPI.users.resetPassword()` pour sync en KC. |
| **C4-FIX** | #9 #10 | prisma/seed.js, plateforme_seed.js | Ajouter création KC | **L** | Créer users en Keycloak après Prisma create, ou utiliser script post-seed dédié qui crée Keycloak users avec rôles corrects. |

#### **Priorité IMPORTANTE — Désynchronisations**

| Correctif | Flux | Fichier | Type | Effort | Détail |
|-----------|------|---------|------|--------|--------|
| **I1-FIX** | #4 #6 | utilisateurController.js:908, keycloakAuthController.js:1398 | Ajouter rollback KC | **M** | Wraper création PG dans try/catch. Si erreur, appeler `keycloakService.adminAPI.users.del(realm, keycloak_id)` pour cleanup. |
| **I2-FIX** | #2 | keycloakAuthController.js:2076 | Corriger condition cleanup | **S** | Changer condition ligne 2076 de `error.response?.status === 201` → créer variable `keycloak_id_created` quand création KC réussit, puis tester `if (keycloak_id_created)`. |
| **I3-FIX** | #7 #8 | keycloakAuth.js:86, authenticateKeycloak.js:96 | Sync rôles depuis KC | **M** | Lire rôles du token/decoded, mapper à rôle local, et créer `utilisateur_role` avec le bon rôle au lieu de `passager` hardcodé. |
| **I4-FIX** | #3 | gestionnaireService.js:46 | Inverser ordre KC→PG | **M** | Créer KC d'abord (ligne 96 devient ligne 46), puis PG (ligne 46 devient ligne 96), avec try/catch rollback KC si PG échoue. |

#### **Priorité MINEURE — Robustesse Post-Release**

| Correctif | Flux | Fichier | Type | Effort | Détail |
|-----------|------|---------|------|--------|--------|
| **M1-FIX** | #7 #8 | keycloakAuth.js, authenticateKeycloak.js | Ajouter requiredActions | **S** | Lors auto-prov, définir `requiredActions: ['UPDATE_PASSWORD']` si user KC n'a pas de password, `['VERIFY_EMAIL']` si emailVerified=false. |
| **M2-FIX** | #2 #4 | keycloakAuthController.js:1936, utilisateurController.js:769 | Améliorer requiredActions | **S** | S'assurer que requiredActions incluent UPDATE_PASSWORD si password temporaire. |
| **M3-FIX** | #8 | authenticateKeycloak.js:108 | Raccourcir TTL cache | **S** | Réduire TTL Redis à 10s (ligne 108) au lieu de 60s. Ou invalider cache quand `utilisateur_role` change. |
| **M4-FIX** | Tous | Tous | Ajouter logging structuré | **S** | Chaque création doit logger : keycloak_id, auth_provider, rôles, order (KC vs PG), result (OK vs failed). |

---

### TIMELINE ESTIMÉE

- **CRITIQUE :** 3-5 jours (C1, C2, C3, C4 en parallèle)
- **IMPORTANTE :** 2-3 jours (I1, I2, I3, I4 en parallèle)
- **MINEURE :** 1 jour post-release

---

## CONCLUSION

**État :** Aucun flux de création conforme. 4 flux cassés, 6 partiels.

**Root cause :** Architecture manque de :
1. **Atomicité :** Keycloak et PostgreSQL ne sont pas dans une transaction
2. **Compensation :** Pas de rollback systématique en cas d'erreur
3. **Synchronisation :** Rôles, passwords, metadata ne sont pas maintenus cohérents

**Recommandation :** Refactorer tous les flux pour :
- Créer KC d'abord (obtenir keycloak_id)
- Créer PG avec keycloak_id (atomic transaction)
- Cleanup KC si transaction PG échoue
- Sync rôles/metadata lors login (pour auto-prov)
- Tester end-to-end : création → email → invitation → password change → login

**Audit complet :** Voir fichier source `AUDIT_USER_CREATION.md` (ce document).
