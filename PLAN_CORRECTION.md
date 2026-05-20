# 🛠️ PLAN DE CORRECTION - Création d'Utilisateurs

**Priorité**: CRITIQUE  
**Estimation**: 2-3 jours  
**Risque**: Moyen (breaking changes dans 2 endpoints)

---

## 🎯 Objectifs

1. ✅ Synchroniser **100%** des créations d'utilisateurs avec Keycloak
2. ✅ Garantir que CHAQUE utilisateur a: **rôle local** + **portefeuille**
3. ✅ Supprimer les **doublets** et **incohérences**
4. ✅ Ajouter **validation** et **cleanup** en cas d'erreur

---

## 📋 TASKS

### TASK 1: Corriger createUserByAdmin() - ⚠️ CRITIQUE P1

**Fichier**: `backend/src/controllers/keycloakAuthController.js` (ligne 668)  
**Impact**: `/auth/admin/users`  
**Risque**: MOYEN (breaking si utilisateurs dépendent du fallback local)

#### Changements

**AVANT**:
```javascript
async createUserByAdmin(req, res) {
  // ...
  const mot_de_passe_hash = await bcrypt.hash(mot_de_passe, 12);
  
  const newUser = await prisma.$transaction(async (tx) => {
    const user = await tx.utilisateur.create({
      data: {
        email,
        nom,
        prenom,
        numero_telephone,
        mot_de_passe_hash,  // ❌ Hash local seulement
        auth_provider: 'keycloak',  // ❌ Mensonge!
        utilisateur_role: { create: { role, actif: true } }
      }
    });
    // ... entités associées ...
    return user;
  });
  // ...
}
```

**APRÈS**:
```javascript
async createUserByAdmin(req, res) {
  // ... validations existantes ...
  
  const tempPassword = crypto.randomBytes(6).toString('hex').substring(0, 12);
  
  // 🔑 NEW: Mapper rôle local → rôle Keycloak
  const roleMapping = {
    'admin': 'ndjigi-admin',
    'gestionnaire': 'ndjigi-gestionnaire',
    'passager': 'ndjigi-passager',
    'chauffeur': 'ndjigi-chauffeur',
    'proprietaire': 'ndjigi-proprietaire'
  };
  const kcRoleName = roleMapping[role] || role;

  // 🔑 NEW: Créer en Keycloak AVANT BD locale
  let keycloak_id;
  try {
    const kcUser = await keycloakService.adminAPI.users.create({
      realm: process.env.KEYCLOAK_REALM,
      body: {
        email: email,
        emailVerified: false,
        firstName: prenom,
        lastName: nom,
        enabled: true,
        attributes: {
          phone: numero_telephone
        },
        requiredActions: ['UPDATE_PASSWORD'],
        credentials: [
          {
            type: 'password',
            value: tempPassword,
            temporary: true
          }
        ]
      }
    });
    keycloak_id = kcUser.id;
    console.log(`✅ Keycloak user created: ${keycloak_id}`);
  } catch (kcCreateError) {
    console.error('❌ Keycloak user creation failed:', kcCreateError.message);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la création du compte dans Keycloak.',
      data: null,
      errors: kcCreateError.message
    });
  }

  // 🔑 NEW: Assigner rôle Keycloak
  try {
    const kcRole = await keycloakService.adminAPI.roles.findOneByName({
      realm: process.env.KEYCLOAK_REALM,
      name: kcRoleName
    });

    if (kcRole) {
      await keycloakService.adminAPI.users.addRealmRoleMappings({
        realm: process.env.KEYCLOAK_REALM,
        id: keycloak_id,
        roles: [kcRole]
      });
      console.log(`✅ Keycloak role assigned: ${kcRoleName}`);
    }
  } catch (kcRoleError) {
    console.warn(`⚠️ Could not assign Keycloak role:`, kcRoleError.message);
    // Don't fail - role can be assigned later
  }

  // ✅ EXISTING: Créer en BD locale (avec keycloak_id maintenant)
  const newUser = await prisma.$transaction(async (tx) => {
    const user = await tx.utilisateur.create({
      data: {
        keycloak_id,  // 🔑 NEW: sync avec Keycloak
        email,
        nom,
        prenom,
        numero_telephone,
        auth_provider: 'keycloak',
        statut_compte: 'actif',
        utilisateur_role: {
          create: { role, actif: true }
        }
      },
      include: {
        utilisateur_role: { where: { actif: true } }
      }
    });

    // ✅ EXISTING: Créer entités associées
    if (role === 'passager') {
      await tx.passager.create({ data: { id_passager: user.id_utilisateur } });
    }
    if (role === 'chauffeur') {
      await tx.chauffeur.create({
        data: {
          id_chauffeur: user.id_utilisateur,
          type_service: 'vtc',
          statut_validation: 'en_attente'
        }
      });
    }
    if (role === 'proprietaire') {
      await tx.proprietaire.create({ data: { id_proprietaire: user.id_utilisateur } });
    }
    if (role === 'gestionnaire' && parking_id) {
      await tx.gestionnaire_parking.create({
        data: {
          id_gestionnaire: user.id_utilisateur,
          id_parking: parking_id,
          date_prise_poste: new Date()
        }
      });
    }

    // ✅ EXISTING: Créer portefeuille
    await tx.portefeuille.create({
      data: { id_utilisateur: user.id_utilisateur }
    });

    return user;
  });

  // ✅ EXISTING: Envoyer email et log
  // ...
}
```

#### Checklist
- [ ] Code écrit et testé localement
- [ ] Tests unitaires passent
- [ ] Vérifier: Keycloak user créé ET BD locale sync
- [ ] Vérifier: Email d'invitation envoyé
- [ ] Vérifier: Login après création fonctionne

---

### TASK 2: Corriger createGestionnaire() (P2) - ⚠️ CRITIQUE

**Fichier**: `backend/src/controllers/keycloakAuthController.js` (ligne 1561)  
**Endpoint**: `POST /auth/admin/gestionnaires`  
**Changements**: Ajouter `utilisateur_role` + `portefeuille`

#### Code à ajouter

```javascript
// Après création en Keycloak (ligne 1628), AVANT création locale:

// 1️⃣ Créer en BD locale avec rôle
const dbUser = await prisma.utilisateur.create({
  data: {
    id_utilisateur: require('uuid').v4(),
    keycloak_id,
    email,
    nom,
    prenom,
    numero_telephone: phone,
    // ✅ NEW: Add role association
    utilisateur_role: {
      create: {
        role: 'gestionnaire',
        actif: true
      }
    },
    auth_provider: 'keycloak',
    statut_compte: 'actif'
  },
  include: {
    utilisateur_role: { where: { actif: true } }
  }
});

// 2️⃣ NEW: Create wallet
await prisma.portefeuille.create({
  data: { id_utilisateur: dbUser.id_utilisateur }
});

// 3️⃣ EXISTING: Assign parkings
await Promise.all(
  parkings.map(p =>
    prisma.gestionnaire_parking.upsert({...})
  )
);
```

#### Checklist
- [ ] Ajouter `utilisateur_role` create
- [ ] Ajouter `portefeuille` create
- [ ] Supprimer champ `phone` redondant (ligne 1641)
- [ ] Tester: Gestionnaire a rôle local
- [ ] Tester: Gestionnaire a portefeuille

---

### TASK 3: Corriger otpVerify() (P3) - ⚠️ IMPORTANT

**Fichier**: `backend/src/controllers/keycloakAuthController.js` (ligne 947)  
**Impact**: Utilisateurs mobiles OTP  
**Changements**: Ajouter firstName/lastName

#### Code à modifier

**AVANT** (ligne 947):
```javascript
keycloakUser = await keycloakService.adminAPI.users.create({
  realm: process.env.KEYCLOAK_REALM,
  username: normalizedPhone,
  attributes: {
    phone: normalizedPhone
  },
  credentials: [{ ... }],
  enabled: true
});
```

**APRÈS**:
```javascript
keycloakUser = await keycloakService.adminAPI.users.create({
  realm: process.env.KEYCLOAK_REALM,
  username: normalizedPhone,
  firstName: '',  // 🔑 NEW: même si vide
  lastName: '',   // 🔑 NEW: même si vide
  attributes: {
    phone: normalizedPhone
  },
  credentials: [{ ... }],
  enabled: true
});
```

#### Checklist
- [ ] Ajouter `firstName` et `lastName`
- [ ] Tester: OTP creation crée Keycloak avec firstName/lastName
- [ ] Tester: User peut completer profil plus tard

---

### TASK 4: Supprimer double forgotPassword (P4) - SIMPLE

**Fichier**: `backend/src/controllers/keycloakAuthController.js`  
**Changements**: Supprimer VERSION 1, garder VERSION 2

#### Actions

1. **Supprimer la VERSION 1** (ligne 558-602)
```javascript
// ❌ SUPPRIMER:
async forgotPassword(req, res) {  // Ligne 558
  try {
    const { email } = req.body;
    // ... local implementation
    const reset_token = crypto.randomUUID();
    await prisma.utilisateur.update({...});
    await sendResetPasswordEmail(...);
    // ...
  }
}
```

2. **Garder VERSION 2** (ligne 1501-1553) - celle-ci utilise Keycloak

3. **Mettre à jour les routes** (`keycloakAuthRoutes.js`):
```javascript
// Le endpoint /auth/forgot-password doit appeler VERSION 2 uniquement
router.post('/forgot-password', forgotPasswordLimiter, async (req, res) => {
  // VERSION 2 (Keycloak)
  await KeycloakAuthController.forgotPassword(req, res);
});
```

#### Checklist
- [ ] Supprimer VERSION 1 (ligne 558)
- [ ] Vérifier VERSION 2 est utilisée
- [ ] Tester: /auth/forgot-password trigger Keycloak email
- [ ] Vérifier: Pas de conflits de noms

---

### TASK 5: Consolider gestionnaire creation (P5) - REFACTOR

**Objectif**: UNE SEULE implémentation pour créer gestionnaire  
**Stratégie**: Garder `GestionnaireService`, supprimer `keycloakAuthController.createGestionnaire()`

#### Actions

1. **Supprimer** `keycloakAuthController.createGestionnaire()` (ligne 1561-1752)
   ```javascript
   // ❌ SUPPRIMER toute cette méthode
   async createGestionnaire(req, res) { ... }
   ```

2. **Vérifier** `GestionnaireService.create()` (ligne 14) a TOUTES les fonctionnalités:
   - ✅ Crée en Keycloak
   - ✅ Crée en BD locale
   - ✅ Assigne rôle
   - ✅ Crée portefeuille (ADD if missing)
   - ✅ Assigne parkings
   - ✅ Envoie email
   - ✅ Cleanup en cas d'erreur

3. **Ajouter** portefeuille si manquant dans `GestionnaireService`:
   ```javascript
   // Dans le transaction, après user creation:
   await tx.portefeuille.create({
     data: { id_utilisateur: user.id_utilisateur }
   });
   ```

4. **Routes** (`keycloakAuthRoutes.js` ligne 317):
   ```javascript
   // ❌ SUPPRIMER:
   router.post('/admin/gestionnaires', async (req, res) => {
     await KeycloakAuthController.createGestionnaire(req, res);
   });

   // Routes via GestionnaireController reste intact:
   // POST /admin/gestionnaires → GestionnaireController.create
   ```

#### Checklist
- [ ] Supprimer `keycloakAuthController.createGestionnaire()`
- [ ] Ajouter portefeuille à `GestionnaireService` si manquant
- [ ] Tester: `/admin/gestionnaires` utilise GestionnaireService
- [ ] Tester: Gestionnaire a rôle + portefeuille + parkings

---

### TASK 6: Corriger auto-provisioning (P6) - MINOR

**Fichier**: `backend/src/controllers/keycloakAuthController.js` (ligne 123)  
**Changements**: Laisser `numero_telephone` NULL

#### Code à modifier

**AVANT**:
```javascript
numero_telephone: `temp-${keycloak_id.substring(0, 8)}`,  // ❌ PLACEHOLDER
```

**APRÈS**:
```javascript
numero_telephone: null,  // ✅ Laisser NULL - user peut l'ajouter plus tard
```

#### Checklist
- [ ] Changer `numero_telephone` à NULL
- [ ] Tester: Auto-provisioning laisse phone NULL
- [ ] Tester: User peut ajouter phone via profil

---

## 📅 Planning d'Exécution

### Phase 1: Préparation (30 min)
- [ ] Créer branche feature: `fix/user-creation-keycloak-sync`
- [ ] Lire ce plan d'action complètement
- [ ] Backup base de données locale
- [ ] Tester état actuel avec `TEST_CREATION_UTILISATEURS.md`

### Phase 2: Corrections (4 heures)
- [ ] **1h** - TASK 1 (createUserByAdmin) + test
- [ ] **30m** - TASK 2 (createGestionnaire rôle/portefeuille) + test
- [ ] **30m** - TASK 3 (otpVerify firstName/lastName) + test
- [ ] **30m** - TASK 4 (supprimer forgotPassword double) + test
- [ ] **1h** - TASK 5 (consolider gestionnaire) + test
- [ ] **30m** - TASK 6 (auto-provisioning phone) + test

### Phase 3: Validation (2 heures)
- [ ] Lancer suite de tests
- [ ] Vérifier pas de breaking changes
- [ ] Tester tous les 6 flux avec `TEST_CREATION_UTILISATEURS.md`
- [ ] Vérifier BD locale + Keycloak sync

### Phase 4: Déploiement (30 min)
- [ ] Squash commits
- [ ] Créer PR avec description
- [ ] Merger à main
- [ ] Deploy staging
- [ ] Monitor logs

---

## 🚨 Points d'Attention

### Breaking Changes

1. **createUserByAdmin** (TASK 1)
   - ❌ Utilisateurs créés précédemment SANS keycloak_id
   - ✅ Solution: Migration script pour populate keycloak_id? NON (créer dans KC manuellement)

2. **createGestionnaire** (TASK 2)
   - ❌ Endpoint `/auth/admin/gestionnaires` comportement change
   - ✅ Solution: Documenter changements, tester avant deploy

3. **Consolidated gestionnaire** (TASK 5)
   - ❌ Double endpoint pour même chose
   - ✅ Solution: Keep backward compatibility ou deprecate `/auth/admin/gestionnaires`

### Testing Essentials

**Avant chaque change**:
```bash
# 1. Créer utilisateur
curl -X POST /api/utilisateurs -d '{...}'

# 2. Vérifier BD locale
psql SELECT * FROM utilisateur WHERE email='...'

# 3. Vérifier Keycloak
curl /admin/realms/.../users?email=...

# 4. Login test
curl -X POST /auth/login -d '{email, password}'

# 5. Vérifier tokens + JWT
decode $access_token | grep roles
```

### Rollback Plan

Si quelque chose casse:

```bash
# 1. Revert code
git revert commit-id

# 2. Restaurer DB (si migration)
psql < backup.sql

# 3. Vérifier
curl /auth/login -d '{...}'
```

---

## ✅ Definition of Done

Pour chaque TASK:

- [ ] Code écrit et auto-reviewé
- [ ] Tests locaux passent (créer user → vérifier BD + KC)
- [ ] Logs montrent transactions correctes
- [ ] Email d'invitation envoyé
- [ ] Login après création fonctionne
- [ ] 2FA (si applicable) fonctionne
- [ ] Pas de données orphelines (KC sans DB ou vice-versa)
- [ ] Cleanup en cas d'erreur fonctionne

---

## 📞 Contacts

**Questions pendant implémentation**:
- Vérifier `ANALYSE_CREATION_UTILISATEURS.md` pour contexte
- Vérifier `TEST_CREATION_UTILISATEURS.md` pour cas de test
- Checker `keycloakService.js` pour API Keycloak disponible

