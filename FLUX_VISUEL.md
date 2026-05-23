# 🎬 FLUX VISUEL - DE BOUT EN BOUT

## ✅ LE FLUX QUI DOIT S'APPLIQUER

```
┌─────────────────────────────────────────────────────────────────────────┐
│ ADMIN                                                                    │
└─────────────────────────────────────────────────────────────────────────┘
         │
         │ POST /admin/gestionnaires
         │ { nom, prenom, email, numero_telephone, id_parking }
         ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ BACKEND - gestionnaireService.create()                                 │
├─────────────────────────────────────────────────────────────────────────┤
│ 1. Valide parking                                                        │
│ 2. Appelle userProvisioningService.create()                            │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ KEYCLOAK + POSTGRESQL                                                  │
├─────────────────────────────────────────────────────────────────────────┤
│ userProvisioningService.create()                                        │
│                                                                          │
│ 1. Génère un UUID: invitation_token                                     │
│    └─ invitation_token = "ABC-123-DEF-456"                             │
│    └─ invitation_token_expire = NOW + 24h                              │
│                                                                          │
│ 2. Crée user Keycloak:                                                  │
│    └─ username = email                                                  │
│    └─ temporary password = "%TvPHaGl7KCb"                              │
│    └─ requiredActions: ['UPDATE_PASSWORD']                             │
│    └─ Retourne: keycloak_id                                            │
│                                                                          │
│ 3. Crée user PostgreSQL:                                               │
│    ├─ id_utilisateur, keycloak_id, email, nom, prenom                 │
│    ├─ invitation_token ✅ NEW                                          │
│    ├─ invitation_token_expire ✅ NEW                                   │
│    ├─ invitation_used_at = null ✅ NEW                                 │
│    ├─ invitation_resend_count = 0 ✅ NEW                               │
│    ├─ Crée gestionnaire_parking                                        │
│    └─ Crée portefeuille                                               │
│                                                                          │
│ 4. Appelle EmailService.sendUserInvitation({                           │
│      email: "xxx@gmail.com",                                           │
│      nom, prenom, role: 'gestionnaire',                                │
│      token: "ABC-123-DEF-456", ✅ NOUVEAU                              │
│      appUrl: "http://localhost:3000"                                   │
│    })                                                                    │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ EMAIL ENVOYÉ                                                            │
├─────────────────────────────────────────────────────────────────────────┤
│ Destination: xxx@gmail.com                                              │
│                                                                          │
│ ┌──────────────────────────────────────────────────────────────────┐   │
│ │ Bienvenue sur N'DJIGI                                            │   │
│ │                                                                  │   │
│ │ Pour ACTIVER votre compte:                                      │   │
│ │ [Bouton: ACTIVER MON COMPTE]                                    │   │
│ │ http://localhost:3000/auth/first-connection?token=ABC-123...    │   │
│ │                                                                  │   │
│ │ Parking assigné: Compaoré Guetawende Zacharie                  │   │
│ │                                                                  │   │
│ │ Ce lien expire dans 24 heures.                                  │   │
│ └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│ ❌ N'ENVOIE PAS le mot de passe temporaire                             │
│ ❌ N'ENVOIE PAS les instructions "va sur /login"                       │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ GESTIONNAIRE CLIQUE LE LIEN                                            │
├─────────────────────────────────────────────────────────────────────────┤
│ URL: http://localhost:3000/auth/first-connection?token=ABC-123...     │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ FRONTEND - FirstConnectionPage.tsx CHARGE                              │
├─────────────────────────────────────────────────────────────────────────┤
│ 1. Lit token du URL: token = "ABC-123..."                              │
│                                                                          │
│ 2. Appelle: GET /auth/verify-invitation?token=ABC-123...              │
│                                                                          │
│    Backend vérifie:                                                     │
│    ├─ Token existe en BD                                               │
│    ├─ Token pas expiré (invitation_token_expire > NOW)                │
│    └─ Retourne: { email, id_utilisateur, parking_nom }               │
│                                                                          │
│ 3. Affiche: PasswordSetupForm.tsx                                      │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ PAGE D'ACTIVATION - GESTIONNAIRE REMPLIS LE FORMULAIRE                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ Activation de compte                                           │    │
│  ├────────────────────────────────────────────────────────────────┤    │
│  │ Email: xxx@gmail.com                                           │    │
│  │ Parking: Compaoré Guetawende Zacharie                         │    │
│  ├────────────────────────────────────────────────────────────────┤    │
│  │ Mot de passe: [MonMotDePasse123!    ]                         │    │
│  │ Confirmer:    [MonMotDePasse123!    ]                         │    │
│  ├────────────────────────────────────────────────────────────────┤    │
│  │ ✅ Au moins 12 caractères                                      │    │
│  │ ✅ Au moins 1 majuscule                                        │    │
│  │ ✅ Au moins 1 minuscule                                        │    │
│  │ ✅ Au moins 1 chiffre                                          │    │
│  │ ✅ Au moins 1 caractère spécial                                │    │
│  ├────────────────────────────────────────────────────────────────┤    │
│  │ [✅] J'accepte les conditions d'utilisation                    │    │
│  ├────────────────────────────────────────────────────────────────┤    │
│  │        [Activer mon compte]                                    │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
         │
         │ Soumet le formulaire
         ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ BACKEND - invitationController.completeFirstConnection()              │
├─────────────────────────────────────────────────────────────────────────┤
│ POST /auth/complete-first-connection                                    │
│ {                                                                        │
│   token: "ABC-123...",                                                  │
│   email: "xxx@gmail.com",                                               │
│   nouveau_mot_de_passe: "MonMotDePasse123!",                           │
│   accepte_conditions: true                                              │
│ }                                                                        │
│                                                                          │
│ 1. Cherche l'utilisateur:                                               │
│    ├─ WHERE invitation_token = "ABC-123..."                            │
│    ├─ WHERE invitation_token_expire > NOW (pas expiré)                 │
│    └─ WHERE email = "xxx@gmail.com"                                    │
│                                                                          │
│ 2. Vérifie que le lien n'a pas déjà été utilisé:                       │
│    └─ IF user.invitation_used_at IS NOT NULL → Erreur                  │
│                                                                          │
│ 3. MET À JOUR KEYCLOAK:                                                 │
│    └─ resetPassword(user.keycloak_id, nouveau_mot_de_passe)           │
│       └─ ✅ Cela complète l'action UPDATE_PASSWORD                     │
│       └─ ✅ Le mot de passe n'est plus temporaire                      │
│                                                                          │
│ 4. MET À JOUR POSTGRESQL:                                               │
│    ├─ invitation_token = NULL (efface le token)                        │
│    ├─ invitation_token_expire = NULL                                   │
│    ├─ invitation_used_at = NOW() (marque comme utilisé)                │
│    ├─ mot_de_passe_hash = hash(nouveau_mot_de_passe)                   │
│    └─ statut_compte = 'actif'                                          │
│                                                                          │
│ 5. Retourne: { id_utilisateur, email, statut_compte: 'actif' }        │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ FRONTEND - PAGE DE SUCCÈS                                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ✅ Compte activé!                                                      │
│                                                                          │
│  Vous allez être redirigé vers la connexion dans 1.5 secondes...       │
│                                                                          │
│  → navigate('/login')                                                   │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ↓ Après 1.5 secondes
┌─────────────────────────────────────────────────────────────────────────┐
│ PAGE DE LOGIN                                                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ N'DJIGI - Connexion                                              │  │
│  ├──────────────────────────────────────────────────────────────────┤  │
│  │ Email:    [xxx@gmail.com         ]                               │  │
│  │ Mot de passe: [MonMotDePasse123!]                               │  │
│  ├──────────────────────────────────────────────────────────────────┤  │
│  │        [Se connecter]                                            │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│ POST /api/v1/auth/login                                                │
│ {                                                                        │
│   email: "xxx@gmail.com",                                               │
│   password: "MonMotDePasse123!"                                        │
│ }                                                                        │
│                                                                          │
│ ✅ Keycloak:                                                            │
│    ├─ Mot de passe correct                                             │
│    ├─ Aucune requiredAction (UPDATE_PASSWORD a été complétée)         │
│    └─ Retourne: access_token, refresh_token                           │
│                                                                          │
│ ✅ Frontend:                                                            │
│    └─ Connecté! Redirige vers dashboard                               │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ GESTIONNAIRE CONNECTÉ                                                  │
├─────────────────────────────────────────────────────────────────────────┤
│ ✅ Accès au dashboard                                                   │
│ ✅ Accès aux parkings assignés                                          │
│ ✅ Peut gérer les véhicules, trajets, etc.                             │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 CAS EDGE: LE LIEN EST UTILISÉ 2 FOIS

```
1️⃣ Première utilisation:
   POST /auth/complete-first-connection { token, ... }
   ✅ Succès, invitation_used_at = NOW()

2️⃣ Deuxième utilisation (même lien):
   POST /auth/complete-first-connection { token, ... }
   
   Backend:
   - Cherche user WHERE invitation_token = token
   - Trouve l'utilisateur
   - ✅ MAIS user.invitation_used_at IS NOT NULL
   - ❌ Retourne: "Lien invalide ou expiré"

3️⃣ Lien expiré après 24h:
   GET /auth/verify-invitation?token=ABC-123...
   
   Backend:
   - Cherche user WHERE invitation_token = token
   - Cherche user WHERE invitation_token_expire > NOW
   - ❌ NOW > invitation_token_expire
   - ❌ Retourne: "Lien invalide ou expiré"
```

---

## 📊 COMPARAISON: AVANT vs APRÈS

| Aspect | ❌ AVANT (Cassé) | ✅ APRÈS (Fixé) |
|--------|------------------|-----------------|
| **Email reçu** | Mot de passe temporaire | Lien d'activation |
| **Instructions** | "Va sur /login avec le mot de passe temp" | "Clique le lien pour activer" |
| **Token en BD** | Inexistant | UUID généré + stocké |
| **Page d'activation** | Existe mais inutilisable | Fonctionne correctement |
| **Changement mot de passe** | Impossible (deadlock Keycloak) | Possible via formulaire |
| **Connexion après activation** | Échoue avec "Account not set up" | Succès ✅ |
| **Sécurité du lien** | N/A | Token unique, expires, one-time use |

---

## 🎯 3 FICHIERS À MODIFIER

```
1️⃣ backend/prisma/schema.prisma
   └─ Ajouter 4 champs à model utilisateur

2️⃣ backend/src/services/userProvisioningService.js
   └─ Générer token + passer à emailService

3️⃣ backend/src/services/emailService.js
   └─ Envoyer lien avec token (pas le mot de passe)
```

**C'est tout! Rien d'autre à modifier.**

---

## ✅ ES-TU D'ACCORD AVEC CE FLUX?

**Confirme:**
- [ ] Le flux est correct
- [ ] Les 3 fichiers sont les bons
- [ ] Je comprends pourquoi ça ne fonctionne pas actuellement
- [ ] Je comprends comment ça va fonctionner après

**Questions avant le GO:**
- ?

