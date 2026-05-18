# 📬 GUIDE D'IMPORT - COLLECTION POSTMAN N'DJIGI

## COMMENT IMPORTER LA COLLECTION

### Méthode 1: Import Direct dans Postman
1. Ouvrir **Postman**
2. Cliquer sur **Import** (en haut à gauche)
3. Sélectionner l'onglet **File**
4. Choisir le fichier `POSTMAN_COLLECTION.json`
5. Cliquer sur **Import**

### Méthode 2: Via Postman CLI
```bash
postman collection import ./POSTMAN_COLLECTION.json
```

---

## STRUCTURE DE LA COLLECTION

```
N'DJIGI Authentication Test Suite
├── 🔴 ANOMALIES CRITIQUES (3 tests)
│   ├── TEST #1: Admin reçoit rôle passager ❌
│   ├── TEST #2: Gestionnaire reçoit rôle passager ❌
│   └── TEST #3: Passager peut se connecter (mobile only) ❌
│
├── ✅ TESTS DE BASE (5 tests)
│   ├── Login Admin avec 2FA
│   ├── Verify SMS Code (2FA)
│   ├── Resend SMS Code
│   ├── Logout
│   └── Health Check
│
├── 🔍 TESTS DE SYNCHRONISATION (2 tests non implémentés)
│   ├── [EXPECTED] Vérifier rôles Keycloak synchronisés
│   └── [EXPECTED] Créer un utilisateur (IT seulement)
│
├── 🔐 TESTS DE SÉCURITÉ (2 tests)
│   ├── Test: Passager ne peut pas accéder /admin
│   └── Test: Token expiré
│
└── 📊 ANALYSE DE DONNÉES (1 endpoint manquant)
    └── Log utilisateurs actuels en BDD
```

---

## AVANT DE LANCER LES TESTS

### Prérequis
- ✅ Backend N'DJIGI en cours d'exécution (`http://localhost:8000`)
- ✅ Docker Compose avec tous les services (`keycloak`, `postgres`, `redis`)
- ✅ Keycloak configuré avec le realm `ndjigi`

### Vérifier la Santé du Backend
```bash
curl http://localhost:8000/health
```

Réponse attendue:
```json
{
  "success": true,
  "status": "ok",
  "timestamp": "2026-05-18T11:00:00.000Z"
}
```

---

## SCÉNARIO DE TEST #1: TESTER L'ANOMALIE CRITIQUE

### Objectif
Reproduire le bug: **Admin reçoit le rôle de passager**

### Étapes

#### Étape 1: Login
```
Requête: TEST #1: Admin reçoit rôle passager ❌
Email: noe@gmail.com
Password: Heroskingjesus100#
```

Réponse attendue:
```json
{
  "success": true,
  "message": "Code OTP envoyé par SMS.",
  "data": {
    "requires_2fa": true,
    "login_token": "cfe5fc82-a8c9-4914-ba9c-ed713bc6cd0f",
    "phone_masked": "temp-690fc7**"
  }
}
```

**VÉRIFICATION:**
- ✅ `requires_2fa: true` (correct, c'est un admin)
- ✅ Status 200

#### Étape 2: Récupérer le code OTP
Le code est affiché dans les logs du backend:
```
ndjigi-backend | ============================================================
ndjigi-backend |   📱 OTP SMS [DEV MODE]
ndjigi-backend |   Phone : temp-690fc731
ndjigi-backend |   Code  : 611699  ← COPIER CE CODE
```

#### Étape 3: Vérifier le SMS
```
Requête: Verify SMS Code (2FA)
Login Token: <COPIER DEPUIS STEP 1>
SMS Code: 611699
```

Réponse attendue:
```json
{
  "success": true,
  "message": "SMS vérifié.",
  "data": {
    "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUI...",
    "refresh_token": "eyJhbGciOiJIUzUxMiIsInR5cCIgOiAiSldUI...",
    "user": {
      "id_utilisateur": "...",
      "email": "noe@gmail.com",
      "nom": "...",
      "prenom": "...",
      "roles": ["passager"]  ❌ ANOMALIE: DEVRAIT ÊTRE ["ndjigi-admin"]
    }
  }
}
```

**VÉRIFICATION DE L'ANOMALIE:**
- ❌ `user.roles[0] = "passager"` (INCORRECT! Devrait être "ndjigi-admin")
- ❌ C'est l'**ANOMALIE #2**

---

## SCÉNARIO DE TEST #2: TESTER LE BLOCAGE DE PASSAGER

### Objectif
Vérifier que les passagers NE PEUVENT PAS se connecter (car pas d'interface web)

### Étapes

#### Étape 1: Login Passager
```
Requête: TEST #3: Passager peut se connecter (mobile only) ❌
Email: guetawende@gmail.com
Password: Heroskingjesus100#
```

Réponse actuelle (INCORRECT):
```json
{
  "success": true,
  "message": "Connexion réussie.",
  "data": {
    "requires_2fa": false,
    "access_token": "eyJhbGciOiJSUzI1NiI...",
    "refresh_token": "eyJhbGciOiJIUzUxMiI...",
    "user": {
      "email": "guetawende@gmail.com",
      "roles": ["passager"]
    }
  }
}
```

**PROBLÈME IDENTIFIÉ:**
- ✅ Status 200 (passager peut se connecter)
- ❌ **ANOMALIE #4**: Passager n'a pas d'interface web mais peut se connecter!

**Réponse attendue (non implémentée):**
```json
{
  "success": false,
  "message": "Web access not available for this role. Use mobile app.",
  "data": null,
  "errors": null
}
```

---

## VARIABLES POSTMAN À CONFIGURER

Après chaque login réussi, mettre à jour les variables:

1. **Sélectionner** l'onglet **Environment** ou **Variables**
2. **Ajouter/Modifier:**
   - `access_token`: Copier depuis la réponse `data.access_token`
   - `refresh_token`: Copier depuis la réponse `data.refresh_token`
   - `login_token`: Copier depuis la réponse 2FA `data.login_token`

### Exemple
```
Variables globales:
├── base_url: http://localhost:8000
├── access_token: eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJpUTZ...
├── refresh_token: eyJhbGciOiJIUzUxMiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI0MDk...
└── login_token: cfe5fc82-a8c9-4914-ba9c-ed713bc6cd0f
```

---

## COMPTES DE TEST DISPONIBLES

| Email | Mot de passe | Rôle Keycloak | 2FA | État |
|-------|-------------|---------------|-----|------|
| admin.test@ndjigi.local | Admin@2026! | ndjigi-admin | Oui | ✅ Actif |
| admin@ndjigi.test | Admin@12345 | ndjigi-admin | Oui | ✅ Actif |
| noe@gmail.com | Heroskingjesus100# | ndjigi-admin | Oui | ✅ Actif |
| guetawende@gmail.com | Heroskingjesus100# | passager | Non | ✅ Actif |
| cprzachk@gmail.com | (test) | - | - | ❌ Erreur "setup requis" |

---

## TESTER LES ANOMALIES - CHECKLIST

### Anomalie #1: Auto-provisioning Incorrect
```
□ Login avec admin.test@ndjigi.local
□ Vérifier dans Keycloak: ndjigi-admin
□ Vérifier dans réponse backend: roles = ["passager"] ❌
□ Confirmer: rôles mal synchronisés
```

### Anomalie #2: Rôles Non Synchronisés
```
□ Login avec noe@gmail.com
□ Dans les logs backend: "Roles: ndjigi-admin" ✅
□ Dans la réponse API: roles = ["passager"] ❌
□ Confirmer: Keycloak dit ndjigi-admin, API retourne passager
```

### Anomalie #3: Pas de Redirection par Rôle
```
□ Login avec admin (avec 2FA)
□ Frontend reçoit roles = ["passager"]
□ Vérifier: Pas de redirection vers /admin
□ Confirmer: Frontend affiche page passager (pas d'interface!)
```

### Anomalie #4: Passager Peut Se Connecter
```
□ Login avec guetawende@gmail.com
□ Status: 200 ✅
□ Confirmer: Passager reçoit access_token (INCORRECT)
□ Attendu: Erreur 403 "Web access not available"
```

### Anomalie #5: Pas de Contrôle Création
```
□ Vérifier: Pas d'endpoint POST /api/v1/users
□ Confirmer: Utilisateurs créés automatiquement via Keycloak login
□ Attendu: Endpoint IT-only pour créer utilisateurs
```

---

## COMMANDES UTILES

### Voir les logs en temps réel
```bash
docker compose logs -f backend
```

### Récupérer le code OTP du dernier login
```bash
docker compose logs backend | grep "OTP SMS" -A 3 | tail -5
```

### Vérifier la synchronisation des rôles
```bash
docker compose exec postgres psql -U ndjigi_user -d ndjigi_db -c \
  "SELECT email, keycloak_id FROM utilisateur LIMIT 5;"
```

---

## RÉSUMÉ DES ANOMALIES À TESTER

| # | Anomalie | Sévérité | Test Postman | Résultat Attendu |
|---|----------|----------|--------------|------------------|
| 1 | Auto-provisioning incorrect | CRITIQUE | TEST #1 | roles = ['passager'] ❌ |
| 2 | Rôles non synchronisés | CRITIQUE | TEST #1 | API retourne passager au lieu de ndjigi-admin |
| 3 | Pas de redirection | HAUTE | Frontend manual | Aucune redirection /admin |
| 4 | Passager peut se connecter | HAUTE | TEST #3 | Status 200 (devrait être 403) |
| 5 | Pas de contrôle création | MOYENNE | N/A | POST /api/v1/users n'existe pas |

---

## NEXT STEPS

1. **Importer cette collection dans Postman**
2. **Exécuter les tests dans l'ordre**
3. **Comparer les résultats avec les anomalies documentées**
4. **Valider que chaque anomalie est reproducible**
5. **Envoyer ce rapport aux développeurs pour correction**

---

**Fichiers associés:**
- `ANOMALIES_AUTHENTIFICATION.md` - Rapport détaillé des anomalies
- `POSTMAN_COLLECTION.json` - Collection de tests (ce fichier)
- `GUIDE_POSTMAN_IMPORT.md` - Guide d'utilisation (ce fichier)
