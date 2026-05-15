# 🗺️ Feuille de Route - Keycloak + Dockerisation Opérationnelle

**Date de démarrage:** 15 mai 2026  
**État actuel:** Dockerisation ✅ COMPLÈTE  
**État Keycloak:** ⏳ À configurer  
**Durée totale estimée:** 4-5 heures  

---

## 📊 Vue d'ensemble des phases

```
┌─────────────────────────────────────────────────────────────────────┐
│ PHASE 1: Configuration Keycloak (30-45 min)                         │
├─────────────────────────────────────────────────────────────────────┤
│ • Créer realm 'ndjigi'                                              │
│ • Créer 4 clients (backend, web, mobile)                            │
│ • Créer 4 rôles (admin, gestionnaire, chauffeur, passager)         │
│ • Créer utilisateur de test                                         │
│ ✓ Validation: Admin Console accessible                             │
└─────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────┐
│ PHASE 2: Intégration Backend (30-40 min)                            │
├─────────────────────────────────────────────────────────────────────┤
│ • Installer dépendances keycloak-connect                            │
│ • Ajouter variables d'environnement                                 │
│ • Appliquer migrations Prisma                                       │
│ • Configurer middleware dualAuth dans les routes                    │
│ ✓ Validation: API retourne 401 sans token, 200 avec token         │
└─────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────┐
│ PHASE 3: Intégration Frontend (45-60 min)                           │
├─────────────────────────────────────────────────────────────────────┤
│ • Installer keycloak-js et axios                                    │
│ • Créer service Keycloak                                            │
│ • Créer Context React pour Keycloak                                │
│ • Créer composants (ProtectedRoute, Login, etc.)                   │
│ • Intégrer dans App.jsx                                             │
│ ✓ Validation: Redirect vers Keycloak au login                      │
└─────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────┐
│ PHASE 4: Tests & Validation (30-45 min)                            │
├─────────────────────────────────────────────────────────────────────┤
│ • Tester login/logout                                               │
│ • Tester routes protégées                                           │
│ • Tester gestion des rôles                                          │
│ • Vérifier les tokens JWT                                           │
│ ✓ Validation: Tout fonctionne end-to-end                          │
└─────────────────────────────────────────────────────────────────────┘

DURÉE TOTALE ESTIMÉE: 4-5 HEURES
```

---

## 🔴 PHASE 1: Configuration Keycloak (30-45 min)

### Étape 1.1: Accéder à Keycloak Admin Console

```bash
# URL: http://localhost:8080
# Username: admin
# Password: admin_password_change_me_prod
```

### Étape 1.2: Créer le Realm 'ndjigi'

```bash
# Chemin: Admin Console > Create Realm

Configuration:
├── Realm name: ndjigi
├── Enabled: ON
├── Access Token Lifespan: 15 minutes
├── Refresh Token Lifespan: 7 days
└── Save
```

### Étape 1.3: Créer les Rôles (4 rôles)

```bash
# Chemin: Realm Settings > Roles > Create role

Créer 4 rôles:
┌──────────────────────────────────────────────┐
│ 1. ndjigi-admin                              │
│    Description: Administrateur du système    │
├──────────────────────────────────────────────┤
│ 2. ndjigi-gestionnaire                       │
│    Description: Gestionnaire de parking      │
├──────────────────────────────────────────────┤
│ 3. ndjigi-chauffeur                          │
│    Description: Chauffeur                    │
├──────────────────────────────────────────────┤
│ 4. ndjigi-passager                           │
│    Description: Passager                     │
└──────────────────────────────────────────────┘
```

### Étape 1.4: Créer le Client Backend

```bash
# Chemin: Clients > Create

Client Configuration:
├── Client ID: ndjigi-backend
├── Name: N'DJIJI Backend
├── Enabled: ON
├── Client Protocol: openid-connect
├── Access Type: confidential
└── Next

Access Settings:
├── Standard Flow Enabled: ON
├── Direct Access Grants Enabled: ON
├── Service Accounts Enabled: ON
├── Valid Redirect URIs: http://backend:8000/*, http://localhost:8000/*
├── Web Origins: http://backend:8000, http://localhost:8000
└── Save

Credentials:
├── Tab: Credentials
├── Client Authenticator: Client Id and Secret
├── Copy: COPIER LE CLIENT SECRET (important!)
└── Garder ce secret pour le .env du backend
```

### Étape 1.5: Créer le Client Web

```bash
# Chemin: Clients > Create

Client Configuration:
├── Client ID: ndjigi-web
├── Name: N'DJIGI Web
├── Enabled: ON
├── Client Protocol: openid-connect
├── Access Type: public
└── Next

Access Settings:
├── Standard Flow Enabled: ON
├── Implicit Flow Enabled: OFF
├── Direct Access Grants Enabled: ON
├── Valid Redirect URIs:
│   ├── http://localhost:3000/*
│   ├── http://localhost:3000/callback
│   └── http://localhost:3000/silent-check-sso.html
├── Web Origins: http://localhost:3000
└── Save
```

### Étape 1.6: Créer le Client Mobile (optionnel pour maintenant)

```bash
# Chemin: Clients > Create

Client Configuration:
├── Client ID: ndjigi-mobile
├── Name: N'DJIGI Mobile
├── Enabled: ON
├── Client Protocol: openid-connect
├── Access Type: public
└── Next

Access Settings:
├── Standard Flow Enabled: ON
├── Valid Redirect URIs: app://ndjigi-mobile/*
└── Save
```

### Étape 1.7: Créer un Utilisateur de Test

```bash
# Chemin: Users > Create user

User Details:
├── Username: testuser
├── Email: test@ndjigi.local
├── First Name: Test
├── Last Name: User
├── Enabled: ON
└── Save

Credentials Tab:
├── Set password: TestPassword123!
├── Temporary: OFF
└── Set password

Role Mappings Tab:
├── Available Roles: ndjigi-passager
├── Click: Add selected
└── Assigned Roles should show ndjigi-passager
```

### ✅ Checkpoint Phase 1

```bash
□ Realm 'ndjigi' créé et visible dans Admin Console
□ 4 rôles créés (admin, gestionnaire, chauffeur, passager)
□ Client 'ndjigi-backend' créé et CLIENT SECRET copié
□ Client 'ndjigi-web' créé
□ Utilisateur 'testuser' créé avec rôle 'ndjigi-passager'
□ Pouvez vous connecter à Keycloak avec testuser?
```

---

## 🟠 PHASE 2: Intégration Backend (30-40 min)

### Étape 2.1: Copier le CLIENT SECRET

```bash
# À partir de Keycloak Admin Console
Clients > ndjigi-backend > Credentials > Copy Secret

Sauvegarder cette valeur: xxxxxxxxxxxxxxxx
```

### Étape 2.2: Mettre à jour le fichier .env du backend

```bash
# Fichier: backend/.env

DATABASE_URL="postgresql://ndjigi_user:secure_password_change_me_prod@postgres:5432/ndjigi_db"
NODE_ENV=development
PORT=8000

# ⭐ AJOUTER/METTRE À JOUR:
KEYCLOAK_URL=http://keycloak:8080
KEYCLOAK_REALM=ndjigi
KEYCLOAK_CLIENT_ID=ndjigi-backend
KEYCLOAK_CLIENT_SECRET=<COLLER_LE_SECRET_ICI>

JWT_SECRET=your_jwt_secret_key
JWT_REFRESH_SECRET=your_jwt_refresh_secret
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

CORS_ORIGIN=http://localhost:3000,http://localhost:8081,http://web:3000
```

### Étape 2.3: Installer les dépendances Keycloak

```bash
# Se connecter au conteneur backend
docker-compose exec backend bash

# À l'intérieur du conteneur:
npm install keycloak-connect express-session

# Vérifier l'installation
npm list keycloak-connect

# Quitter le conteneur
exit
```

### Étape 2.4: Exécuter les migrations Prisma

```bash
# Appliquer les migrations
docker-compose exec backend npx prisma migrate deploy

# Ou si vous avez des migrations en attente:
docker-compose exec backend npx prisma migrate dev

# Vérifier la structure (optionnel)
docker-compose exec backend npx prisma studio
# Puis ouvrir http://localhost:5555
```

### Étape 2.5: Configurer les routes protégées

**Modifier: `backend/src/routes/index.js`**

```javascript
const express = require('express');
const { dualAuthenticate } = require('../middlewares/dualAuth');

const router = express.Router();

// ⭐ APPLIQUER LE MIDDLEWARE À TOUTES LES ROUTES PROTÉGÉES
router.use(dualAuthenticate);

// Exemple de route protégée
router.get('/utilisateurs', async (req, res) => {
  // req.user contient: id_utilisateur, email, roles, etc.
  try {
    const users = await prisma.utilisateur.findMany();
    res.json({
      success: true,
      data: users,
      message: 'Utilisateurs récupérés'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
});

// Exemple de route protégée avec vérification de rôle
router.get('/admin/stats', async (req, res) => {
  // Vérifier le rôle
  const hasAdminRole = req.user?.roles?.includes('ndjigi-admin');
  
  if (!hasAdminRole) {
    return res.status(403).json({
      success: false,
      message: 'Accès refusé. Seuls les admins peuvent accéder.'
    });
  }
  
  // Logique admin
  res.json({ success: true, data: { /* stats */ } });
});

module.exports = router;
```

### Étape 2.6: Redémarrer le backend

```bash
# Redémarrer le service
docker-compose restart backend

# Vérifier les logs
docker-compose logs backend --tail=30

# Tester la health check
curl http://localhost:8000/health
# Devrait retourner: {"success":true,"status":"ok",...}
```

### ✅ Checkpoint Phase 2

```bash
□ Variables d'environnement Keycloak configurées
□ Dépendances keycloak-connect installées
□ Migrations Prisma exécutées
□ Routes configurées avec middleware dualAuthenticate
□ Backend redémarré sans erreurs
□ curl http://localhost:8000/health retourne 200
```

---

## 🟡 PHASE 3: Intégration Frontend (45-60 min)

### Étape 3.1: Installer les dépendances

```bash
cd web/n-djigi

# Installer keycloak-js et axios
npm install keycloak-js axios

# Vérifier
npm list keycloak-js axios
```

### Étape 3.2: Créer le service Keycloak

**Créer: `web/n-djigi/src/services/keycloakService.js`**

```javascript
import Keycloak from 'keycloak-js';

const keycloakConfig = {
  url: import.meta.env.VITE_KEYCLOAK_URL,
  realm: import.meta.env.VITE_KEYCLOAK_REALM,
  clientId: import.meta.env.VITE_KEYCLOAK_CLIENT_ID
};

let keycloakInstance = null;

export const initKeycloak = async () => {
  if (!keycloakInstance) {
    keycloakInstance = new Keycloak(keycloakConfig);
    
    const authenticated = await keycloakInstance.init({
      onLoad: 'login-required',
      silentCheckSsoRedirectUri: window.location.origin + '/silent-check-sso.html',
      pkceMethod: 'S256'
    });
    
    if (authenticated) {
      setupTokenRefresh();
    }
    
    return authenticated;
  }
  
  return keycloakInstance.authenticated;
};

export const getKeycloakInstance = () => keycloakInstance;
export const getAccessToken = () => keycloakInstance?.token;
export const getUserInfo = () => keycloakInstance?.tokenParsed;
export const getUserRoles = () => {
  const realmRoles = keycloakInstance?.tokenParsed?.realm_access?.roles || [];
  return realmRoles;
};
export const hasRole = (role) => getUserRoles().includes(role);
export const logout = () => keycloakInstance?.logout({ redirectUri: window.location.origin });

const setupTokenRefresh = () => {
  setInterval(() => {
    keycloakInstance?.updateToken(30)
      .catch(() => logout());
  }, 60000);
};

export default keycloakInstance;
```

### Étape 3.3: Créer le Context React

**Créer: `web/n-djigi/src/context/KeycloakContext.jsx`**

```javascript
import React, { createContext, useContext, useEffect, useState } from 'react';
import { initKeycloak, getKeycloakInstance, getAccessToken, getUserInfo, getUserRoles, hasRole, logout } from '../services/keycloakService';

const KeycloakContext = createContext();

export const KeycloakProvider = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [user, setUser] = useState(null);

  useEffect(() => {
    const init = async () => {
      try {
        const authenticated = await initKeycloak();
        setIsAuthenticated(authenticated);
        if (authenticated) {
          setUser({
            info: getUserInfo(),
            roles: getUserRoles(),
            token: getAccessToken()
          });
        }
      } catch (error) {
        console.error('Erreur Keycloak:', error);
      } finally {
        setIsLoading(false);
      }
    };

    init();
  }, []);

  const value = {
    isAuthenticated,
    isLoading,
    user,
    keycloak: getKeycloakInstance(),
    getToken: getAccessToken,
    hasRole: hasRole,
    logout: logout
  };

  return (
    <KeycloakContext.Provider value={value}>
      {children}
    </KeycloakContext.Provider>
  );
};

export const useKeycloak = () => {
  const context = useContext(KeycloakContext);
  if (!context) {
    throw new Error('useKeycloak doit être utilisé à l\'intérieur d\'un KeycloakProvider');
  }
  return context;
};
```

### Étape 3.4: Créer ProtectedRoute

**Créer: `web/n-djigi/src/components/ProtectedRoute.jsx`**

```javascript
import React from 'react';
import { Navigate } from 'react-router-dom';
import { useKeycloak } from '../context/KeycloakContext';

export const ProtectedRoute = ({ children, requiredRoles = [] }) => {
  const { isAuthenticated, isLoading, hasRole } = useKeycloak();

  if (isLoading) {
    return <div className="flex items-center justify-center h-screen">Chargement...</div>;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (requiredRoles.length > 0) {
    const hasRequiredRole = requiredRoles.some(role => hasRole(role));
    if (!hasRequiredRole) {
      return <Navigate to="/unauthorized" replace />;
    }
  }

  return children;
};
```

### Étape 3.5: Créer composant Login

**Créer: `web/n-djigi/src/components/Login.jsx`**

```javascript
import React from 'react';
import { useKeycloak } from '../context/KeycloakContext';

export const Login = () => {
  const { keycloak, isLoading } = useKeycloak();

  const handleLogin = () => {
    keycloak?.login();
  };

  if (isLoading) {
    return <div className="flex items-center justify-center h-screen">Chargement...</div>;
  }

  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-100">
      <div className="bg-white rounded-lg shadow-lg p-8">
        <h1 className="text-3xl font-bold mb-6">N'DJIGI</h1>
        <p className="text-gray-600 mb-8">Connectez-vous pour continuer</p>
        <button
          onClick={handleLogin}
          className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded-lg"
        >
          Se connecter avec Keycloak
        </button>
      </div>
    </div>
  );
};
```

### Étape 3.6: Intégrer dans App.jsx

```javascript
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { KeycloakProvider } from './context/KeycloakContext';
import { ProtectedRoute } from './components/ProtectedRoute';
import Login from './components/Login';
import Dashboard from './pages/Dashboard';
import AdminPanel from './pages/AdminPanel';

function App() {
  return (
    <KeycloakProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          
          <Route
            path="/dashboard"
            element={
              <ProtectedRoute>
                <Dashboard />
              </ProtectedRoute>
            }
          />
          
          <Route
            path="/admin"
            element={
              <ProtectedRoute requiredRoles={['ndjigi-admin']}>
                <AdminPanel />
              </ProtectedRoute>
            }
          />
          
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </BrowserRouter>
    </KeycloakProvider>
  );
}

export default App;
```

### Étape 3.7: Mettre à jour le .env frontend

**Fichier: `web/n-djigi/.env`**

```env
VITE_API_URL=http://localhost:8000/api/v1
VITE_KEYCLOAK_URL=http://localhost:8080
VITE_KEYCLOAK_REALM=ndjigi
VITE_KEYCLOAK_CLIENT_ID=ndjigi-web
```

### Étape 3.8: Créer silent-check-sso.html

**Créer: `web/n-djigi/public/silent-check-sso.html`**

```html
<!DOCTYPE html>
<html>
  <head>
    <title>silent-check-sso</title>
  </head>
  <body>
    <script>
      parent.postMessage(location.href, location.origin);
    </script>
  </body>
</html>
```

### Étape 3.9: Reconstruire le frontend

```bash
cd web/n-djigi

# Reconstruire
npm run build

# Ou relancer en dev
docker-compose restart web
```

### ✅ Checkpoint Phase 3

```bash
□ keycloak-js et axios installés
□ Service Keycloak créé
□ Context KeycloakProvider créé
□ ProtectedRoute créé
□ Composant Login créé
□ App.jsx intégré avec routes protégées
□ .env frontend configuré
□ Frontend reconstruit et relancé
```

---

## 🟢 PHASE 4: Tests & Validation (30-45 min)

### Étape 4.1: Tester le Login

```bash
# 1. Ouvrir le frontend
# URL: http://localhost:3000

# 2. Vous devriez être redirigé vers:
# http://localhost:8080/realms/ndjigi/protocol/openid-connect/auth...

# 3. Se connecter avec:
# Username: testuser
# Password: TestPassword123!

# 4. Vérifier que vous êtes redirigé vers:
# http://localhost:3000/dashboard
```

### Étape 4.2: Tester les routes protégées

```bash
# 1. Essayer d'accéder à une route admin
# URL: http://localhost:3000/admin

# Résultat attendu:
# - Vous êtes redirigé vers /unauthorized
# - Car testuser a le rôle 'ndjigi-passager' et pas 'ndjigi-admin'

# 2. Créer un utilisateur admin dans Keycloak
# Users > Create user > adminuser > Roles > ndjigi-admin

# 3. Se reconnecter avec adminuser
# 4. Vérifier que vous pouvez accéder à /admin
```

### Étape 4.3: Tester l'API avec token

```bash
# 1. Obtenir un token Keycloak
# Via Postman ou curl:

curl -X POST http://localhost:8080/realms/ndjigi/protocol/openid-connect/token \
  -d "client_id=ndjigi-backend" \
  -d "client_secret=<VOTRE_CLIENT_SECRET>" \
  -d "username=testuser" \
  -d "password=TestPassword123!" \
  -d "grant_type=password"

# Résultat: JSON avec "access_token"

# 2. Utiliser le token pour appeler l'API
TOKEN="<access_token_from_above>"

curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/v1/utilisateurs

# Résultat attendu: 200 OK avec les données
```

### Étape 4.4: Tester sans token (401)

```bash
# Appeler l'API sans token
curl http://localhost:8000/api/v1/utilisateurs

# Résultat attendu: 401 Unauthorized
# {"success": false, "message": "Token manquant. Connectez-vous."}
```

### Étape 4.5: Vérifier les logs

```bash
# Logs Keycloak
docker-compose logs keycloak --tail=50

# Logs Backend
docker-compose logs backend --tail=50

# Logs Frontend
docker-compose logs web --tail=50

# Chercher les messages d'erreur
```

### ✅ Checkpoint Phase 4

```bash
□ Login/Logout fonctionne
□ Routes protégées redirigent vers login
□ Vérification des rôles fonctionne
□ API retourne 401 sans token
□ API retourne 200 avec token valide
□ Token est rafraîchi automatiquement
□ Logs montrent pas d'erreurs critiques
```

---

## 📋 CHECKLIST COMPLÈTE

### État Dockerisation
- [x] PostgreSQL lancé et healthy
- [x] Keycloak lancé
- [x] Backend lancé
- [x] Frontend lancé

### Phase 1: Configuration Keycloak
- [ ] Realm 'ndjigi' créé
- [ ] 4 rôles créés
- [ ] Client 'ndjigi-backend' créé avec secret copié
- [ ] Client 'ndjigi-web' créé
- [ ] Utilisateur 'testuser' créé

### Phase 2: Intégration Backend
- [ ] Variables d'environnement Keycloak configurées
- [ ] keycloak-connect installé
- [ ] Migrations Prisma exécutées
- [ ] Routes protégées avec dualAuthenticate
- [ ] Backend redémarré sans erreurs

### Phase 3: Intégration Frontend
- [ ] keycloak-js et axios installés
- [ ] Service Keycloak créé
- [ ] Context KeycloakProvider créé
- [ ] ProtectedRoute créé
- [ ] App.jsx intégré
- [ ] .env configuré
- [ ] silent-check-sso.html créé
- [ ] Frontend reconstruit

### Phase 4: Tests
- [ ] Login/Logout fonctionne
- [ ] Routes protégées redirigent
- [ ] Vérification rôles fonctionne
- [ ] API authentification fonctionne
- [ ] Tokens rafraîchis automatiquement

---

## 🆘 Troubleshooting rapide

### Keycloak ne démarre pas
```bash
docker-compose logs keycloak
docker-compose restart keycloak
# Attendre 60 secondes
```

### Erreur: "Client Secret invalide"
```bash
# Vérifier le secret dans:
# Keycloak Admin > Clients > ndjigi-backend > Credentials > Copy
# Puis mettre à jour backend/.env
docker-compose restart backend
```

### Frontend redirect infini vers login
```bash
# Vérifier:
# 1. Valid Redirect URIs dans Keycloak incluent http://localhost:3000
# 2. VITE_KEYCLOAK_* variables correctes dans .env
# 3. Lire les logs: docker-compose logs web
```

### Token invalide depuis le frontend
```bash
# Vérifier:
# 1. Keycloak URL accessible depuis le navigateur
# 2. CORS configurés dans Keycloak
# 3. Client 'ndjigi-web' est PUBLIC (pas confidential)
```

### API retourne toujours 401
```bash
# Vérifier:
# 1. middleware dualAuthenticate dans les routes
# 2. Token est dans le header Authorization: Bearer <token>
# 3. KEYCLOAK_URL correcte dans backend/.env
docker-compose logs backend | grep -i "auth\|error"
```

---

## ⏱️ Temps estimé par phase

| Phase | Tâche | Temps |
|-------|-------|-------|
| 1 | Configuration Keycloak | 30-45 min |
| 2 | Intégration Backend | 30-40 min |
| 3 | Intégration Frontend | 45-60 min |
| 4 | Tests & Validation | 30-45 min |
| **TOTAL** | | **2.5-3.5 heures** |

---

## 🎯 Après la phase 4: Optimisations

Une fois que tout fonctionne:

1. **Passer de dualAuth à authenticateKeycloak uniquement**
   - Plus de support JWT, seulement Keycloak
   - Nettoyer le code JWT

2. **Ajouter Keycloak aux routes mobile**
   - Créer le client mobile
   - Intégrer dans Flutter

3. **Configurer les rôles par endpoint**
   - Créer middleware `requireRole('ndjigi-admin')`
   - Protéger les endpoints sensibles

4. **Mettre en place la synchronisation utilisateurs**
   - Sync automatique Keycloak → PostgreSQL
   - Lors du premier login, créer l'utilisateur en BD

5. **Ajouter les attributs personnalisés**
   - Numéro de téléphone
   - Adresse
   - Etc.

6. **Configurer les webhooks**
   - Actions à l'utilisateur créé
   - Actions à l'utilisateur supprimé
   - Etc.

---

## 📞 Questions fréquentes

**Q: Quelle est la différence entre JWT et Keycloak?**  
A: JWT est local, Keycloak est centralisé. Avec Keycloak, on délègue toute l'authentification à un serveur dédié.

**Q: Dois-je supprimer le JWT?**  
A: Non, le dualAuth permet une transition progressive. Garder JWT pour la rétrocompatibilité.

**Q: Où stocker le token?**  
A: keycloak-js le gère automatiquement en localStorage ou sessionStorage.

**Q: Comment gérer l'expiration du token?**  
A: keycloak-js rafraîchit automatiquement via updateToken().

**Q: Est-ce sécurisé de mettre le secret en .env?**  
A: Non en production. Utiliser les secrets Docker ou Kubernetes.

---

**Prêt à commencer? Lisez PHASE 1 ci-dessus!** 🚀
