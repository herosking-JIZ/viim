# 🚨 RAPPORT D'ANOMALIES - SYSTÈME D'AUTHENTIFICATION N'DJIGI

**Date:** 2026-05-18  
**Sévérité:** CRITIQUE ⚠️  
**Statut:** Non corrigé (Analyse uniquement)

---

## RÉSUMÉ EXÉCUTIF

Le système d'authentification N'DJIGI présente **5 anomalies critiques** qui permettent à des utilisateurs non autorisés d'accéder à des fonctionnalités réservées. **Un passager peut se connecter avec un rôle de gestionnaire**, ce qui constitue une violation grave de sécurité.

---

## ANOMALIES DÉTECTÉES

### 🔴 ANOMALIE #1: Auto-Provisioning Incorrect (CRITIQUE)

**Localisation:** `backend/src/controllers/keycloakAuthController.js:88-95`

**Problème:**
Tous les utilisateurs créés automatiquement reçoivent le rôle "passager" sans vérification.

```javascript
utilisateur_role: {
  create: {
    role: 'passager',  // ❌ TOUS les utilisateurs = passager
    actif: true
  }
}
```

**Conséquence:**
- Un nouvel utilisateur avec rôle `ndjigi-admin` dans Keycloak reçoit `passager` en BDD locale
- La BDD locale devient désynchronisée avec Keycloak
- Les permissions sont basées sur des rôles incorrects

**Cas d'usage affecté:**
```
User: noe@gmail.com
├─ Keycloak role: ndjigi-admin ✅
├─ DB local role: passager ❌
└─ Résultat: Admin accède avec rôle passager
```

**Flux incorrect détecté:**
1. Utilisateur se connecte via Keycloak
2. Keycloak valide: `ndjigi-admin`
3. Backend crée user en DB avec: `passager`
4. Frontend reçoit: `passager`
5. Utilisateur accède à l'interface passager (INCORRECT)

---

### 🔴 ANOMALIE #2: Rôles Keycloak Non Synchronisés en Base de Données (CRITIQUE)

**Localisation:** `backend/src/controllers/keycloakAuthController.js:106-107`

**Problème:**
Les rôles retournés au frontend sont ceux de la BDD locale (passager), pas ceux de Keycloak (ndjiji-admin).

```javascript
// Keycloak dit: ndjigi-admin
// BDD locale dit: passager
// Frontend reçoit: passager ❌
const roles = keycloakRoles.length > 0 ? keycloakRoles : (user.utilisateur_role || []).map((ur) => ur.role);
```

**Conséquence:**
- Le frontend ne reçoit jamais les vrais rôles administrateur
- Un admin reçoit les permissions d'un passager
- Violation du principe "Single Source of Truth" (Keycloak devrait être la source d'autorité)

**Logs observés:**
```
👤 User: 1771a9e8-acaf-444a-9dba-593724c77024, Roles: ndjigi-admin ✅ (Keycloak correct)
📋 All realm_access.roles: ['ndjigi-admin', 'offline_access', ...] ✅ (Keycloak correct)

Mais dans la réponse au frontend:
"roles": ["passager"] ❌ (Rôle local INCORRECT)
```

---

### 🔴 ANOMALIE #3: Pas de Redirection Basée sur le Rôle (HAUTE)

**Localisation:** `web/n-djigi/src/contexts/AuthContext.tsx` et routes

**Problème:**
Aucune logique ne redirige les utilisateurs vers leur interface appropriée selon leur rôle.

**Cas d'usage manquant:**
```
Admin (ndjigi-admin)         → /admin/dashboard
Gestionnaire (gestionnaire)  → /manager/dashboard
Passager (passager)          → /passenger/dashboard  (mobile uniquement)
Chauffeur (chauffeur)        → /driver/dashboard     (mobile uniquement)
Propriétaire (proprietaire)  → /owner/dashboard      (mobile uniquement)
```

**Conséquence:**
- Tous les utilisateurs accèdent à la même interface
- Un passager peut voir l'interface administrateur
- Pas de protection au niveau du frontend

---

### 🔴 ANOMALIE #4: Utilisateurs Sans Interface Peuvent Se Connecter (HAUTE)

**Localisation:** `backend/src/controllers/keycloakAuthController.js` (pas de vérification)

**Problème:**
Les utilisateurs avec les rôles suivants n'ont PAS d'interface web (mobile uniquement) mais peuvent se connecter:
- `passager`
- `chauffeur`
- `proprietaire`

**Conséquence:**
- Ces utilisateurs se connectent avec succès
- Pas d'interface pour eux → expérience confuse
- Pas de message d'erreur explicite

**Cas observé:**
```
guetawende@gmail.com
├─ Rôle: passager (mobile uniquement)
├─ Connecté: ✅ (mais sur interface web)
└─ Erreur: Aucune page disponible pour passager
```

---

### 🟠 ANOMALIE #5: Pas de Distinction IT vs Admin pour Création d'Utilisateurs (MOYENNE)

**Localisation:** Pas d'endpoint de création d'utilisateur

**Problème:**
Actuellement, les utilisateurs sont créés AUTOMATIQUEMENT lors du premier login via Keycloak.

**Logique métier requise (non implémentée):**
```
┌─ Creation de comptes
│  ├─ IT: Peut créer n'importe quel type (passager, chauffeur, etc.)
│  └─ Gestionnaire: Interdit
│
├─ Creation de gestionnaires
│  ├─ Admin: Peut créer + assigner parking
│  └─ Autres: Interdit
│
└─ Affectation de parking
   ├─ Admin: Peut assigner parking à gestionnaire
   └─ Autres: Interdit
```

**Conséquence:**
- Pas de contrôle sur qui crée les utilisateurs
- Auto-provisioning peut créer des utilisateurs involontaires
- Pas de piste d'audit pour la création

---

## IMPACT SÉCURITÉ

| Anomalie | Sévérité | Impact | Risque |
|----------|----------|--------|--------|
| #1: Auto-provisioning incorrect | CRITIQUE | Rôles mal assignés | Escalade de privilèges |
| #2: Rôles non synchronisés | CRITIQUE | Rôles incorrects en frontend | Accès non autorisé |
| #3: Pas de redirection par rôle | HAUTE | Pas d'isolation des interfaces | Exposition de données sensibles |
| #4: Utilisateurs sans interface | HAUTE | Confusion UX | Connexions inutiles |
| #5: Pas de contrôle création | MOYENNE | Création non contrôlée | Données corrompues |

---

## TABLEAU DE VÉRITÉ: QUI PEUT ACCÉDER À QUOI

### Actuellement (INCORRECT) ❌

```
┌─────────────────┬──────────────┬──────────────┬────────────┐
│ Rôle Keycloak   │ Rôle BDD     │ Interface    │ 2FA requis │
├─────────────────┼──────────────┼──────────────┼────────────┤
│ ndjigi-admin    │ passager ❌  │ Passager ❌  │ Oui ✅     │
│ gestionnaire    │ passager ❌  │ Passager ❌  │ Oui ✅     │
│ passager        │ passager ✅  │ Passager ✅  │ Non ✅     │
│ chauffeur       │ passager ❌  │ Passager ❌  │ Non ❌     │
│ proprietaire    │ passager ❌  │ Passager ❌  │ Non ❌     │
└─────────────────┴──────────────┴──────────────┴────────────┘
```

### Attendu (CORRECT) ✅

```
┌─────────────────┬──────────────┬──────────────┬────────────┐
│ Rôle Keycloak   │ Rôle BDD     │ Interface    │ 2FA requis │
├─────────────────┼──────────────┼──────────────┼────────────┤
│ ndjigi-admin    │ ndjigi-admin │ /admin       │ Oui ✅     │
│ gestionnaire    │ gestionnaire │ /manager     │ Oui ✅     │
│ passager        │ passager     │ BLOQUÉ ❌    │ N/A        │
│ chauffeur       │ chauffeur    │ BLOQUÉ ❌    │ N/A        │
│ proprietaire    │ proprietaire │ BLOQUÉ ❌    │ N/A        │
└─────────────────┴──────────────┴──────────────┴────────────┘
```

---

## FLUX ACTUEL PROBLÉMATIQUE

```
LOGIN: noe@gmail.com (Keycloak: ndjigi-admin)
    ↓
[Keycloak] ✅ Authentification OK
    ↓
[Backend] Crée user avec:
    ├─ keycloak_id: "1771a9e8..."
    ├─ email: "noe@gmail.com"
    └─ role: "passager" ❌ (INCORRECT)
    ↓
[Response] Retourne au frontend:
    ├─ access_token: "eyJh..."
    └─ user.roles: ["passager"] ❌ (INCORRECT)
    ↓
[Frontend] Stocke dans localStorage:
    └─ role: "passager" ❌ (INCORRECT)
    ↓
[Interface] Affiche: Passager Dashboard ❌
    └─ Admin voit l'interface passager!
```

---

## FLUX CORRECT ATTENDU

```
LOGIN: noe@gmail.com (Keycloak: ndjigi-admin)
    ↓
[Keycloak] ✅ Authentification OK, rôle: ndjigi-admin
    ↓
[Backend] SYNCHRONISE les rôles:
    ├─ Keycloak dit: ndjigi-admin
    └─ BDD local reçoit: ndjigi-admin ✅
    ↓
[Response] Retourne au frontend:
    ├─ access_token: "eyJh..."
    └─ user.roles: ["ndjigi-admin"] ✅
    ↓
[Frontend] Stocke dans localStorage:
    └─ role: "ndjigi-admin" ✅
    ↓
[Router] Redirige: /admin ✅
    └─ Admin Dashboard ✅
```

---

## VÉRIFICATIONS NÉCESSAIRES

### Code Backend
- [ ] Lignes 88-95: Auto-provisioning crée passager pour TOUS
- [ ] Lignes 106-107: Rôles locaux au lieu de Keycloak
- [ ] Pas de synchronisation des rôles après login
- [ ] Pas de blocage pour passager/chauffeur/proprietaire

### Code Frontend
- [ ] Aucune redirection basée sur les rôles
- [ ] Pas de protection des routes par rôle
- [ ] Pas de message d'erreur pour utilisateurs sans interface

### Architecture
- [ ] Keycloak n'est PAS la "source de vérité"
- [ ] BDD locale est désynchronisée
- [ ] Pas de endpoint pour créer utilisateurs avec rôles

---

## DONNÉES OBSERVÉES DANS LES LOGS

### Cas 1: Passager normal (CORRECT) ✅
```
Email: guetawende@gmail.com
Keycloak roles: []
BDD roles: passager
Frontend roles: passager
2FA: Non
→ Accepté (mais devrait être bloqué car mobile seulement)
```

### Cas 2: Admin (PROBLÉMATIQUE) ❌
```
Email: noe@gmail.com
Keycloak roles: ndjigi-admin
BDD roles: passager (AUTO-PROVISIONED)
Frontend roles: passager (INCORRECT!)
2FA: Oui (correct)
→ Admin voit interface passager! SÉCURITÉ COMPROMISE
```

---

## RECOMMANDATIONS PRIORITAIRES

1. **CRITIQUE** - Synchroniser les rôles Keycloak vers la BDD locale
2. **CRITIQUE** - Retourner les rôles Keycloak, pas les rôles locaux
3. **HAUTE** - Implémenter la redirection par rôle au frontend
4. **HAUTE** - Bloquer passager/chauffeur/proprietaire sur le web
5. **MOYENNE** - Créer un endpoint IT pour créer des utilisateurs

---

## FICHIERS AFFECTÉS

```
Backend:
├── src/controllers/keycloakAuthController.js ❌ (Rôles mal assignés)
├── src/services/keycloakService.js (Pas de sync)
└── src/routes/keycloakAuthRoutes.js (Pas de validation rôle)

Frontend:
├── src/contexts/AuthContext.tsx ❌ (Pas de logique rôle)
├── src/pages/Login.tsx (Pas de validation)
└── src/router/index.tsx (Pas de redirection rôle)

Database:
└── prisma/schema.prisma (utilisateur_role correct mais pas utilisé)
```

---

## EXEMPLE DE REQUÊTE POSTMAN POUR TESTER

Voir le fichier `POSTMAN_COLLECTION.json` pour la collection complète.

**Teste critique:**
```
POST http://localhost:8000/api/v1/auth/login
{
  "email": "noe@gmail.com",
  "password": "Heroskingjesus100#"
}

RESPONSE (ACTUEL - INCORRECT):
{
  "success": true,
  "data": {
    "user": {
      "roles": ["passager"]  ❌ SHOULD BE ["ndjigi-admin"]
    }
  }
}
```

---

**FIN DU RAPPORT**

*Document à envoyer au système Postman pour créer des tests d'authentification.*
