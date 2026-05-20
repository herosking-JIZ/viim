# 🧪 TESTS VÉRIFICATION - Création d'Utilisateurs

---

## ✅ Test 1: Flux utilisateurController.create() (STANDARD)

**Objectif**: Vérifier que la création standard synchronise correctement avec Keycloak

### Étapes

```bash
# 1. Créer un utilisateur admin
curl -X POST http://localhost:3001/api/utilisateurs \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test.admin@example.com",
    "nom": "Test",
    "prenom": "Admin",
    "numero_telephone": "+226123456789",
    "role": "admin"
  }'

# Response: 201
# {
#   "success": true,
#   "data": {
#     "id_utilisateur": "uuid-1",
#     "keycloak_id": "uuid-kc",
#     "email": "test.admin@example.com",
#     "role": "admin"
#   }
# }
```

### Vérifications

**1. Base de données locale**:
```sql
-- Connexion: psql $DATABASE_URL
SELECT id_utilisateur, email, nom, prenom, numero_telephone, 
       keycloak_id, auth_provider, statut_compte
FROM utilisateur
WHERE email = 'test.admin@example.com';

-- Doit retourner:
-- ✅ keycloak_id ≠ NULL
-- ✅ auth_provider = 'keycloak'
-- ✅ nom = 'Test'
-- ✅ prenom = 'Admin'
-- ✅ numero_telephone = '+226123456789'
-- ✅ statut_compte = 'actif'
```

**2. Vérifier le rôle local**:
```sql
SELECT ur.role, ur.actif
FROM utilisateur u
JOIN utilisateur_role ur ON u.id_utilisateur = ur.id_utilisateur
WHERE u.email = 'test.admin@example.com' AND ur.actif = true;

-- Doit retourner:
-- ✅ role = 'admin'
-- ✅ actif = true
```

**3. Vérifier portefeuille**:
```sql
SELECT id_portefeuille, solde, statut
FROM portefeuille
WHERE id_utilisateur = 'uuid-1';

-- Doit retourner:
-- ✅ id_portefeuille ≠ NULL
-- ✅ solde >= 0
-- ✅ statut = 'actif'
```

**4. Keycloak Admin API**:
```bash
# Récupérer le token admin
TOKEN_KC=$(curl -X POST \
  http://localhost:8080/realms/ndjigi/protocol/openid-connect/token \
  -d "client_id=$KEYCLOAK_ADMIN_CLIENT_ID" \
  -d "client_secret=$KEYCLOAK_ADMIN_CLIENT_SECRET" \
  -d "grant_type=client_credentials" \
  | jq -r '.access_token')

# Chercher l'utilisateur
curl -X GET \
  "http://localhost:8080/admin/realms/ndjigi/users?email=test.admin@example.com&exact=true" \
  -H "Authorization: Bearer $TOKEN_KC" | jq '.[0]'

# Doit retourner:
# ✅ id = uuid-kc (matches keycloak_id in DB)
# ✅ email = 'test.admin@example.com'
# ✅ firstName = 'Admin'
# ✅ lastName = 'Test'
# ✅ enabled = true
# ✅ attributes.phone = '+226123456789'

# Vérifier le rôle
curl -X GET \
  "http://localhost:8080/admin/realms/ndjigi/users/$KEYCLOAK_ID/role-mappings/realm" \
  -H "Authorization: Bearer $TOKEN_KC" | jq '.[].name'

# Doit retourner:
# ✅ 'ndjigi-admin'
```

**5. Test de login**:
```bash
# Essayer de se connecter
curl -X POST http://localhost:3001/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test.admin@example.com",
    "password": "tempPassword"  // from email invite
  }'

# Doit retourner:
# ✅ 200 OK (ou 2FA si SMS)
# ✅ access_token présent
# ✅ roles inclus dans JWT
```

### ✅ Résultat attendu
**PASS** si toutes les vérifications OK

---

## ✅ Test 2: Flux otpVerify() (MOBILE OTP)

**Objectif**: Vérifier que la création via OTP synchronise correctement

### Étapes

```bash
# 1. Request OTP
curl -X POST http://localhost:3001/auth/otp/request \
  -H "Content-Type: application/json" \
  -d '{ "phone": "+226987654321" }' \
  -H "X-Forwarded-For: 192.168.1.1"  # Important pour rate-limit

# Response: 200
# { "success": true, "data": { "phone_masked": "+226****4321" } }

# 2. Vérifier OTP envoyé (logs ou Redis)
# Regarder les logs pour extraire le code OTP:
# Format: "OTP code sent to +226987654321: 123456"
OTP_CODE="123456"

# 3. Vérifier OTP
curl -X POST http://localhost:3001/auth/otp/verify \
  -H "Content-Type: application/json" \
  -d "{
    \"phone\": \"+226987654321\",
    \"otp_code\": \"$OTP_CODE\"
  }"

# Response: 200 (May require TOTP setup)
# {
#   "success": true,
#   "data": {
#     "requires_totp_setup": true,  // ou requires_totp: true
#     "login_token": "uuid-token",
#     "totp_secret": "secret"  // if setup required
#   }
# }
LOGIN_TOKEN="uuid-token"
TOTP_SECRET="secret"

# 4. Setup TOTP (si nécessaire)
# Générer code TOTP:
NODE_ENV=test node -e "
const speakeasy = require('speakeasy');
const secret = '$TOTP_SECRET';
const code = speakeasy.totp({ secret, encoding: 'base32' });
console.log(code);
" > /tmp/totp_code.txt
TOTP_CODE=$(cat /tmp/totp_code.txt)

curl -X POST http://localhost:3001/auth/totp/setup \
  -H "Content-Type: application/json" \
  -d "{
    \"login_token\": \"$LOGIN_TOKEN\",
    \"totp_code\": \"$TOTP_CODE\"
  }"

# Response: 200
# {
#   "success": true,
#   "data": {
#     "access_token": "...",
#     "refresh_token": "...",
#     "user": { ... }
#   }
# }
```

### Vérifications

**1. Utilisateur créé en BD locale**:
```sql
SELECT id_utilisateur, email, nom, prenom, numero_telephone, 
       keycloak_id, auth_provider, auth_method_otp
FROM utilisateur
WHERE numero_telephone = '+226987654321';

-- Doit retourner:
-- ✅ keycloak_id ≠ NULL
-- ✅ auth_provider = 'keycloak'
-- ✅ auth_method_otp = true
-- ✅ email NULL (OK, peut être null)
-- ✅ nom NULL (OK, peut être null)
-- ✅ prenom NULL (OK, peut être null)
-- ✅ numero_telephone = '+226987654321'
-- ✅ tech_password_encrypted ≠ NULL
```

**2. Rôle local**:
```sql
SELECT ur.role, ur.actif
FROM utilisateur u
JOIN utilisateur_role ur ON u.id_utilisateur = ur.id_utilisateur
WHERE u.numero_telephone = '+226987654321' AND ur.actif = true;

-- Doit retourner:
-- ✅ role = 'passager'
```

**3. Portefeuille**:
```sql
SELECT id_portefeuille, solde, statut
FROM portefeuille
WHERE id_utilisateur = (
  SELECT id_utilisateur FROM utilisateur 
  WHERE numero_telephone = '+226987654321'
);

-- ✅ portefeuille existe
```

**4. Keycloak - PROBLÈME ATTENDU**:
```bash
TOKEN_KC=$(curl -X POST http://localhost:8080/realms/ndjigi/protocol/openid-connect/token \
  -d "client_id=$KEYCLOAK_ADMIN_CLIENT_ID" \
  -d "client_secret=$KEYCLOAK_ADMIN_CLIENT_SECRET" \
  -d "grant_type=client_credentials" | jq -r '.access_token')

curl -X GET \
  "http://localhost:8080/admin/realms/ndjigi/users?username=%2B226987654321&exact=true" \
  -H "Authorization: Bearer $TOKEN_KC" | jq '.[0]'

# PROBLÈME DÉTECTÉ: firstName et lastName MANQUENT!
# ❌ firstName = NULL
# ❌ lastName = NULL
# ✅ username = '+226987654321'
# ✅ attributes.phone = '+226987654321'
```

### ⚠️ Résultat attendu
**PASS with WARNINGS** - Création réussit mais firstName/lastName manquent en Keycloak

---

## ✅ Test 3: Flux createUserByAdmin() (ADMIN CREATION - PROBLÈME ATTENDU)

**Objectif**: Vérifier que createUserByAdmin ne crée PAS en Keycloak (BUG DÉTECTÉ)

### Étapes

```bash
# 1. Créer via /auth/admin/users
curl -X POST http://localhost:3001/auth/admin/users \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test.passager@example.com",
    "nom": "Passager",
    "prenom": "Test",
    "numero_telephone": "+226111222333",
    "mot_de_passe": "TempPassword123!",
    "role": "passager"
  }'

# Response: 201
# { "success": true, "data": { ... } }
```

### Vérifications

**1. Utilisateur créé en BD locale**:
```sql
SELECT id_utilisateur, email, keycloak_id, auth_provider
FROM utilisateur
WHERE email = 'test.passager@example.com';

-- PROBLÈME:
-- ❌ keycloak_id = NULL (pas créé!)
-- ✅ auth_provider = 'keycloak' (mais pas réel)
-- ✅ email présent
```

**2. Vérifier en Keycloak**:
```bash
TOKEN_KC=$(curl -X POST http://localhost:8080/realms/ndjigi/protocol/openid-connect/token \
  -d "client_id=$KEYCLOAK_ADMIN_CLIENT_ID" \
  -d "client_secret=$KEYCLOAK_ADMIN_CLIENT_SECRET" \
  -d "grant_type=client_credentials" | jq -r '.access_token')

curl -X GET \
  "http://localhost:8080/admin/realms/ndjigi/users?email=test.passager@example.com&exact=true" \
  -H "Authorization: Bearer $TOKEN_KC"

# PROBLÈME CONFIRMÉ:
# ❌ Aucun utilisateur trouvé en Keycloak!
# ❌ User n'existe que en BD locale
```

**3. Test de login**:
```bash
curl -X POST http://localhost:3001/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test.passager@example.com",
    "password": "TempPassword123!"
  }'

# ❌ ERREUR ATTENDUE:
# Soit 401 (si Keycloak check d'abord)
# Soit fallback au local auth (si implémenté)
# ⚠️ Inconsistency
```

### 🔴 Résultat attendu
**FAIL** - Utilisateur créé localement mais PAS en Keycloak (BUG CONFIRMÉ P1)

---

## ✅ Test 4: Flux createGestionnaire() (GESTIONNAIRE - DEUX IMPLÉMENTATIONS)

### 4A. Via keycloakAuthController.createGestionnaire()

**Endpoint**: `POST /auth/admin/gestionnaires`

```bash
# 1. Créer gestionnaire
curl -X POST http://localhost:3001/auth/admin/gestionnaires \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "gestionnaire1@example.com",
    "nom": "Gestionnaire",
    "prenom": "Test",
    "phone": "+226333444555",
    "parkings_assignes": ["parking-uuid-1", "parking-uuid-2"]
  }'

# Response: 201
# { "success": true, "data": { ... } }
```

**Vérifications**:

```sql
SELECT id_utilisateur, email, keycloak_id, auth_provider,
       utilisateur_role.role
FROM utilisateur
LEFT JOIN utilisateur_role ON utilisateur.id_utilisateur = utilisateur_role.id_utilisateur
WHERE email = 'gestionnaire1@example.com';

-- PROBLÈME DÉTECTÉ:
-- ✅ keycloak_id présent
-- ✅ email, nom, prenom présents
-- ❌ utilisateur_role = NULL (MANQUE le rôle local!)

SELECT id_portefeuille
FROM portefeuille
WHERE id_utilisateur = (
  SELECT id_utilisateur FROM utilisateur 
  WHERE email = 'gestionnaire1@example.com'
);

-- ❌ AUCUN RÉSULTAT (portefeuille MANQUE!)
```

### 4B. Via GestionnaireService (via GestionnaireController)

**Endpoint**: `POST /admin/gestionnaires`

```bash
# 1. Créer gestionnaire
curl -X POST http://localhost:3001/admin/gestionnaires \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "gestionnaire2@example.com",
    "nom": "Gestionnaire",
    "prenom": "Service",
    "numero_telephone": "+226555666777",
    "id_parking": "parking-uuid-1"
  }'

# Response: 201
```

**Vérifications**:

```sql
SELECT id_utilisateur, email, keycloak_id, auth_provider
FROM utilisateur
WHERE email = 'gestionnaire2@example.com';

-- ✅ CORRECT:
-- ✅ keycloak_id présent
-- ✅ auth_provider = 'keycloak'

SELECT ur.role, ur.actif
FROM utilisateur u
JOIN utilisateur_role ur ON u.id_utilisateur = ur.id_utilisateur
WHERE u.email = 'gestionnaire2@example.com' AND ur.actif = true;

-- ✅ role = 'gestionnaire'

SELECT id_portefeuille
FROM portefeuille
WHERE id_utilisateur = (
  SELECT id_utilisateur FROM utilisateur 
  WHERE email = 'gestionnaire2@example.com'
);

-- ✅ portefeuille existe
```

### 🟠 Résultats attendus
- **4A via /auth/admin/gestionnaires**: FAIL - manque rôle et portefeuille (BUG P2)
- **4B via /admin/gestionnaires**: PASS - implémentation correcte

---

## 📊 Résumé des Résultats

| Flux | Endpoint | Keycloak ✅ | BD Local ✅ | Rôle ✅ | Portefeuille ✅ | Login ✅ |
|------|----------|------------|-----------|------|----------------|---------|
| **1. utilisateurController.create** | POST /api/utilisateurs | ✅ | ✅ | ✅ | ✅ | ✅ |
| **2. otpVerify** | POST /auth/otp/verify | ⚠️ (no name) | ✅ | ✅ | ✅ | ✅ |
| **3. createUserByAdmin** | POST /auth/admin/users | ❌ | ✅ | ✅ | ✅ | ❌ |
| **4A. createGestionnaire #1** | POST /auth/admin/gestionnaires | ✅ | ✅ | ❌ | ❌ | ❌ |
| **4B. GestionnaireService** | POST /admin/gestionnaires | ✅ | ✅ | ✅ | ✅ | ✅ |
| **5. Auto-provisioning** | POST /auth/login | N/A | ⚠️ (temp) | ✅ | ❌ | ⚠️ |

---

## 🔧 Commandes Utiles

### Nettoyer les utilisateurs de test

```bash
# BD locale
DELETE FROM utilisateur WHERE email LIKE 'test.%@example.com';
DELETE FROM utilisateur WHERE numero_telephone LIKE '+226%;

# Keycloak (trouver et supprimer)
TOKEN_KC=$(curl -X POST http://localhost:8080/realms/ndjigi/protocol/openid-connect/token \
  -d "client_id=$KEYCLOAK_ADMIN_CLIENT_ID" \
  -d "client_secret=$KEYCLOAK_ADMIN_CLIENT_SECRET" \
  -d "grant_type=client_credentials" | jq -r '.access_token')

# Supprimer utilisateur
curl -X DELETE \
  "http://localhost:8080/admin/realms/ndjigi/users/$KEYCLOAK_USER_ID" \
  -H "Authorization: Bearer $TOKEN_KC"
```

### Vérifier Keycloak

```bash
# Token admin
curl -X POST http://localhost:8080/realms/ndjigi/protocol/openid-connect/token \
  -d "client_id=$KEYCLOAK_ADMIN_CLIENT_ID" \
  -d "client_secret=$KEYCLOAK_ADMIN_CLIENT_SECRET" \
  -d "grant_type=client_credentials" | jq

# Lister utilisateurs
curl -X GET "http://localhost:8080/admin/realms/ndjigi/users?max=100" \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# Chercher par email
curl -X GET "http://localhost:8080/admin/realms/ndjigi/users?email=test@example.com&exact=true" \
  -H "Authorization: Bearer $TOKEN" | jq
```

### Vérifier BD locale

```bash
# Connexion directe
psql $DATABASE_URL

# Compter utilisateurs
SELECT COUNT(*) FROM utilisateur;

# Voir orphelins (keycloak_id = NULL)
SELECT email, keycloak_id FROM utilisateur WHERE keycloak_id IS NULL;

# Voir sans rôle
SELECT u.email, COUNT(ur.role) as role_count
FROM utilisateur u
LEFT JOIN utilisateur_role ur ON u.id_utilisateur = ur.id_utilisateur
GROUP BY u.id_utilisateur
HAVING COUNT(ur.role) = 0;

# Voir sans portefeuille
SELECT u.email, COUNT(p.id_portefeuille) as wallet_count
FROM utilisateur u
LEFT JOIN portefeuille p ON u.id_utilisateur = p.id_utilisateur
GROUP BY u.id_utilisateur
HAVING COUNT(p.id_portefeuille) = 0;
```

