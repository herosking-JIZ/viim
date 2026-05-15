# Plan de migration et d'implémentation de l'authentification

> Réfère-toi à `AUTH_ARCHITECTURE.md` pour la spécification cible.
> Ce document est le **fil rouge** d'implémentation. Coche les tâches au fur et à mesure.

---

## Vue d'ensemble des phases

| Phase | Titre | Estimation | Bloque la suivante ? |
|---|---|---|---|
| 0 | Préparation infra (Redis, scripts Keycloak) | 1-2h | Oui |
| 1 | Auth Email+MDP Keycloak (admin/gestionnaire) | 4-6h | Oui |
| 2 | 2FA SMS pour admin/gestionnaire | 3-5h | Non |
| 3 | RBAC backend + frontend | 2-3h | Non |
| 4 | Sécurité : blacklist, rate limit, refresh auto + **suppression JWT custom** | 3-4h | Oui |
| 5 | OTP SMS pour passager/chauffeur/propriétaire | 5-7h | Non |
| 6 | TOTP 2FA pour passager/chauffeur/propriétaire | 2-3h | Non |
| 7 | Reset password + création gestionnaire par admin | 2-3h | Non |
| 8 | Tests E2E + documentation finale | 4-6h | Non |

**Total estimé** : 26 à 39 heures de travail solo bien piloté.

---

## ☐ Phase 0 — Préparation infrastructure

**Objectif** : tout ce qui doit être en place avant de toucher au code d'auth.

### Tâches

- [ ] Ajouter Redis au `docker-compose.yml`
- [ ] Installer côté backend : `ioredis`, `express-rate-limit`, `rate-limit-redis`, `jwks-rsa`, `libphonenumber-js`
- [ ] Créer `backend/src/config/redis.js` (singleton Redis client)
- [ ] Créer `backend/src/config/keycloak.js` (config + clients KCAdminClient)
- [ ] Créer le script `scripts/keycloak/setup-realm.sh` (kcadm.sh) qui configure :
  - Realm `ndjigi`
  - Clients `ndjigi-backend`, `ndjigi-web`, `ndjigi-mobile`
  - Realm roles `ndjigi-admin`, `ndjigi-gestionnaire`, `ndjigi-passager`, `ndjigi-chauffeur`, `ndjigi-proprietaire`
  - Token lifespans (5min access, 30min refresh standard)
- [ ] Lancer le script et vérifier dans l'admin Keycloak que tout est OK
- [ ] Récupérer le **client secret** du client `ndjigi-backend`, le mettre dans `backend/.env` (variable `KEYCLOAK_CLIENT_SECRET`)
- [ ] Exporter le realm en JSON dans `keycloak-exports/ndjigi-realm.json` pour pouvoir le ré-importer après un `down -v`

### Validation

- [ ] `docker compose down -v && docker compose up -d` puis exécution du script → realm reconstruit identique
- [ ] `curl http://localhost:8080/realms/ndjigi/.well-known/openid-configuration` renvoie la config OIDC

### Sortie de phase

Une stack Docker fonctionnelle avec Redis, un realm Keycloak configuré par script reproductible, et un fichier `.env` à jour.

---

## ☐ Phase 1 — Auth Email+MDP Keycloak (admin/gestionnaire)

**Objectif** : login admin/gestionnaire via Keycloak, sans 2FA pour l'instant. JWT custom toujours présent en parallèle (on le supprimera en Phase 4).

### Tâches backend

- [ ] Créer `backend/src/middlewares/keycloakAuth.js`
  - Extrait Bearer token
  - Valide via JWKS (cache 1h)
  - Auto-provisioning : si `keycloak_id` absent en BDD, crée la ligne `utilisateur` à partir des claims du token
  - Attache `req.user = { id, keycloak_id, email, phone, roles, ... }`
- [ ] Créer `backend/src/controllers/authController.js` avec :
  - `login(email, password)` → appelle Keycloak Direct Access Grant
  - `refresh(refresh_token)` → appelle Keycloak refresh
  - `logout(access_token, refresh_token)` → invalide la session Keycloak
- [ ] Créer `backend/src/routes/authRoutes.js` exposant `/auth/login`, `/auth/refresh`, `/auth/logout`
- [ ] Mettre à jour `app.js` pour utiliser `keycloakAuth` sur les routes protégées (en parallèle du middleware JWT existant)
- [ ] Migration Prisma : ajouter `keycloak_id` (unique), `phone` (unique nullable), `active_role` à `Utilisateur`
- [ ] Créer le modèle `AuthLog`

### Tâches frontend (web React admin)

- [ ] Installer `keycloak-js` (déjà fait)
- [ ] Créer `src/services/authService.ts` qui pointe vers les endpoints backend
- [ ] Refactor `AuthContext.tsx` : retirer la logique JWT custom, garder uniquement Keycloak
- [ ] Page `/login` : formulaire email + MDP + checkbox "Remember me"
- [ ] Stockage refresh token : `localStorage` si Remember Me, sinon `sessionStorage`
- [ ] Redirection après login : `/dashboard` (ou la dernière page visitée)

### Configuration Keycloak (script ou manuel)

- [ ] Créer un user admin de test dans Keycloak (`admin.test@ndjigi.local`, password temporaire)
- [ ] Lui assigner le rôle `ndjigi-admin`
- [ ] Activer "Direct access grants" sur le client `ndjigi-backend` ET `ndjigi-web`

### Validation

- [ ] Login avec `admin.test@ndjigi.local` depuis le frontend web → tokens reçus
- [ ] Appel API protégé avec le token → 200 OK, `req.user` contient l'admin
- [ ] Auto-provisioning : ligne `utilisateur` créée en BDD avec `keycloak_id`
- [ ] Refresh token fonctionne (après expiration de 5min)
- [ ] Logout invalide la session côté Keycloak

### Sortie de phase

Un admin peut se connecter au front web, naviguer, ses tokens sont rafraîchis automatiquement, il peut se déconnecter. Le JWT custom existe encore mais n'est plus utilisé par le nouveau flow.

---

## ☐ Phase 2 — 2FA SMS pour admin/gestionnaire

**Objectif** : à chaque login admin/gestionnaire, après email+MDP, demander un code SMS.

### Approche technique

Keycloak ne supporte pas nativement le 2FA par SMS. Deux options :

**Option recommandée** : gérer le 2FA SMS **côté backend**, pas dans Keycloak.

```
1. POST /auth/login (email, password)
   → Backend appelle Keycloak Direct Access Grant
   → Keycloak renvoie les tokens
   → MAIS le backend NE LES RENVOIE PAS au frontend tout de suite
   → Backend génère un OTP SMS, stocke en Redis: key="login:<random>", value={kc_tokens, code}, TTL=5min
   → Backend envoie le SMS (ou log en dev)
   → Backend retourne au frontend: { requires_2fa: true, login_token: <random> }

2. POST /auth/verify-sms (login_token, sms_code)
   → Backend lit Redis, vérifie le code
   → Si OK: retourne les tokens Keycloak stockés
   → Sinon: incrémente compteur, max 3 tentatives, puis invalide la session Keycloak
```

### Tâches

- [ ] Créer `backend/src/services/smsService.js` (en dev: log dans la console, en prod: Orange SMS API)
- [ ] Modifier `authController.login` pour ne pas retourner directement les tokens si rôle admin/gestionnaire
- [ ] Créer endpoint `POST /auth/verify-sms`
- [ ] Côté frontend : après login OK, rediriger vers `/verify-sms`, formulaire 6 chiffres
- [ ] Ajouter compteur de tentatives et bouton "Renvoyer le code" (cooldown 60s)
- [ ] Logger dans `auth_logs` les événements `sms_sent`, `sms_verified`, `sms_failed`

### Validation

- [ ] Login admin → réception SMS (log console en dev)
- [ ] Saisie code correct → tokens reçus
- [ ] Saisie code incorrect 3x → blocage temporaire (15 min)
- [ ] Bouton "Renvoyer" fonctionne après 60s

### Sortie de phase

L'auth admin/gestionnaire est complète en 2 facteurs.

---

## ☐ Phase 3 — RBAC backend + frontend

### Tâches backend

- [ ] Créer `backend/src/middlewares/authorize.js`
  ```js
  module.exports = (...allowedRoles) => (req, res, next) => {
    const userRoles = req.user?.roles || []
    if (!allowedRoles.some(r => userRoles.includes(r))) {
      return res.status(403).json({ message: 'Accès refusé', required: allowedRoles })
    }
    next()
  }
  ```
- [ ] Lister toutes les routes existantes et leur appliquer `authorize(...)` selon le rôle requis
- [ ] Créer `backend/src/config/permissions.json` (mapping rôle → permissions) si besoin de granularité fine

### Tâches frontend

- [ ] Créer `src/components/ProtectedRoute.tsx`
  ```tsx
  <ProtectedRoute requiredRoles={['ndjigi-admin']}>
    <AdminDashboard />
  </ProtectedRoute>
  ```
- [ ] Hook `useAuth().can(permission)` pour cacher/afficher des boutons selon les permissions
- [ ] Page `/403` pour les accès refusés

### Validation

- [ ] Un gestionnaire tente d'accéder à `/admin/users` → 403 backend + page 403 frontend
- [ ] Un admin accède à toutes les pages
- [ ] Les boutons d'action sont cachés selon le rôle (ex: bouton "Supprimer parking" caché pour gestionnaire)

---

## ☐ Phase 4 — Sécurité + suppression du JWT custom

⚠️ **Phase de nettoyage. À faire seulement quand les phases 1, 2, 3 sont validées.**

### Tâches sécurité

- [ ] Créer `backend/src/middlewares/checkBlacklist.js` (vérifie le JTI dans Redis)
- [ ] Modifier le logout : ajoute JTI à `blacklist:<jti>` avec TTL = `exp - now()`
- [ ] Ajouter `express-rate-limit` + `rate-limit-redis` sur toutes les routes `/auth/*`
- [ ] Frontend : intercepteur axios qui :
  - Sur 401, tente un `/auth/refresh`
  - Si refresh OK, rejoue la requête originale
  - Si refresh KO, redirige vers `/login`

### Tâches suppression JWT custom

- [ ] Supprimer `backend/src/utils/jwt.js` (ou équivalent)
- [ ] Supprimer `backend/src/middlewares/auth.js` (ancien JWT)
- [ ] Supprimer la branche JWT dans `dualAuth` (renommer `dualAuth` → `keycloakAuth`)
- [ ] Supprimer les routes `/auth/register` (legacy), `/auth/login` (legacy JWT)
- [ ] Migration Prisma : drop `mot_de_passe_hash`, `tentatives_echec`, `bloque_jusqu_a`, `derniere_connexion`, etc.
- [ ] Supprimer `JWT_SECRET`, `JWT_REFRESH_SECRET`, `JWT_EXPIRES_IN`, `JWT_REFRESH_EXPIRES_IN` du `.env` et du `docker-compose.yml`
- [ ] Côté frontend : retirer toute trace de "authMethod === 'jwt'"
- [ ] Mettre à jour `AuthContext` pour supprimer la persistance localStorage de l'ancien format

### Validation

- [ ] Tous les anciens tests JWT custom suppriment ou échouent → OK, on les remplace
- [ ] Aucune référence à JWT_SECRET dans le code (`grep -r "JWT_SECRET" backend/`)
- [ ] Tout fonctionne encore avec Keycloak uniquement

### Sortie de phase

Le code d'auth est **100% Keycloak**. Plus de dette technique JWT custom. Redis + blacklist + rate limit + refresh auto opérationnels.

---

## ☐ Phase 5 — OTP SMS pour passager/chauffeur/propriétaire

### Tâches backend

- [ ] Endpoint `POST /auth/otp/request` :
  - Normalise le numéro (libphonenumber-js, +226 only)
  - Rate limit : 1/min/numéro, max 5/jour/numéro
  - Génère OTP 6 chiffres (`crypto.randomInt`)
  - Stocke en Redis avec TTL 5min
  - Appelle `smsService.send(phone, code)`
- [ ] Endpoint `POST /auth/otp/verify` :
  - Vérifie OTP en Redis (max 3 tentatives)
  - Si user n'existe pas dans Keycloak : le crée via Admin API avec rôle `ndjigi-passager`
  - Sync en BDD locale
  - Émet les tokens via Direct Access Grant en utilisant un **user technique** ou via un mécanisme de Token Exchange
- [ ] Endpoint `POST /auth/otp/resend` (cooldown 60s)

### Détail crucial : comment émettre des tokens Keycloak sans mot de passe ?

L'utilisateur OTP n'a **pas de mot de passe**. Deux approches :

**Approche A : Token Exchange (recommandée)**
- Activer "Token Exchange" sur le client `ndjigi-backend` dans Keycloak
- Le backend, authentifié comme service account, demande un token "au nom de" l'user
- ⚠️ Token Exchange est en preview dans Keycloak, vérifier la stabilité

**Approche B : Mot de passe technique aléatoire**
- À la création de l'user dans Keycloak, on lui assigne un mot de passe aléatoire (jamais exposé)
- Le backend connaît ce password (stocké chiffré en Redis) ou le régénère à chaque OTP
- Direct Access Grant classique avec ce password

**Décision** : commencer par l'Approche B (plus simple, plus stable). Migrer vers Token Exchange si besoin.

### Tâches Flutter

- [ ] Écran saisie numéro de téléphone (avec préfixe +226 forcé)
- [ ] Écran saisie OTP (6 cases, auto-focus, resend après 60s)
- [ ] Stockage refresh token via `flutter_secure_storage`
- [ ] Interceptor Dio pour refresh automatique

### Validation

- [ ] Inscription d'un nouveau passager : numéro → OTP → tokens reçus → ligne créée dans Keycloak + BDD
- [ ] Connexion d'un passager existant : numéro → OTP → tokens reçus
- [ ] Rate limit fonctionne (6e SMS dans la journée bloqué)

---

## ☐ Phase 6 — TOTP 2FA pour passager/chauffeur/propriétaire

### Tâches backend

- [ ] Après vérification OTP, si l'user n'a pas de TOTP configuré :
  - Générer un secret TOTP via Keycloak Admin API
  - Retourner `{ requires_totp_setup: true, totp_secret, qr_code_url }`
- [ ] Endpoint `POST /auth/totp/setup` (valide la config initiale)
- [ ] Endpoint `POST /auth/totp/verify` (utilisé aux connexions suivantes)

### Tâches Flutter

- [ ] Écran setup TOTP : affichage QR code (généré côté backend ou via package Flutter `qr_flutter`)
- [ ] Écran saisie TOTP : 6 chiffres
- [ ] Stockage : indiquer "TOTP configuré" dans le state

### Validation

- [ ] Premier login d'un nouveau passager : OTP SMS → setup TOTP → connecté
- [ ] Login suivant : OTP SMS → saisie TOTP → connecté
- [ ] Code TOTP incorrect 3x → invalidation session

---

## ☐ Phase 7 — Reset password + création gestionnaire par admin

### Reset password (admin/gestionnaire)

- [ ] Endpoint `POST /auth/forgot-password` (déclenche Keycloak email de reset)
- [ ] Page frontend `/forgot-password` (saisie email)
- [ ] Page frontend `/reset-password?token=xxx` (saisie nouveau MDP)
- [ ] Endpoint `POST /auth/reset-password` (valide le token Keycloak, update MDP)

### Création gestionnaire par admin

- [ ] Endpoint `POST /api/v1/admin/gestionnaires` (admin only)
  - Body : `{ email, nom, prenom, phone, parkings_assignes: [...] }`
  - Crée l'user dans Keycloak avec un MDP temporaire envoyé par email
  - Assigne le rôle `ndjigi-gestionnaire`
  - Force le user à changer son MDP au premier login
- [ ] Page frontend `/admin/gestionnaires` (CRUD)

### Validation

- [ ] Un admin crée un gestionnaire → email reçu avec MDP temporaire → gestionnaire se connecte → forcé à changer MDP → SMS 2FA → accède à son dashboard
- [ ] Un gestionnaire utilise "mot de passe oublié" → email avec lien → reset → reconnecte

---

## ☐ Phase 8 — Tests E2E + documentation finale

- [ ] Tests d'intégration backend (Jest + supertest) couvrant tous les endpoints `/auth/*`
- [ ] Tests E2E web (Playwright) : login admin, login gestionnaire, accès refusé, logout
- [ ] Tests E2E Flutter (`integration_test`) : flow OTP complet
- [ ] OpenAPI/Swagger sur `/api/v1/docs`
- [ ] Diagrammes de séquence à jour dans `/docs/auth-flows.md`
- [ ] README final `/docs/AUTH.md` avec :
  - Comment lancer le projet
  - Comment créer un admin de test
  - Comment activer/désactiver la 2FA en dev
  - Comment monitorer Redis pendant le dev

---

## Critères de "Done" globaux

- [ ] Aucune référence à JWT custom dans le code
- [ ] Tous les rôles ont un flow d'auth fonctionnel
- [ ] 2FA active pour tous (SMS pour admin/gest, TOTP pour les autres)
- [ ] Tokens rafraîchis automatiquement côté client
- [ ] Logout = blacklist effective
- [ ] Rate limit en place sur les endpoints auth
- [ ] Realm Keycloak versionné en JSON + script de setup reproductible
- [ ] auth_logs tracé pour tous les événements importants
- [ ] Documentation à jour
