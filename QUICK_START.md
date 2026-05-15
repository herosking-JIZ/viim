# 🚀 Quick Start: Dockeriser + Keycloak

## 📋 Vue d'ensemble

Ce projet contient tous les fichiers nécessaires pour:
1. **Dockeriser** l'application complète (backend, frontend, base de données)
2. **Intégrer Keycloak** comme système d'authentification centralisé

## ⏱️ Durée estimée: 30-45 minutes

---

## Phase 1: Dockerisation (10-15 min)

### 1.1 Vérifier que Docker est installé

```bash
docker --version
docker-compose --version
```

### 1.2 Lancer l'infrastructure

```bash
# À la racine du projet
docker-compose up -d

# Vérifier que tout est lancé
docker-compose ps

# Afficher les logs en temps réel
docker-compose logs -f
```

**Attendu:**
```
CONTAINER ID   IMAGE                    STATUS
...
...postgres   postgres:16-alpine       Up (healthy)
...keycloak   keycloak/keycloak:latest Up (healthy)
...backend    ndjigi-backend:latest    Up
...web        ndjigi-web:latest        Up
```

### 1.3 Vérifier la base de données

```bash
# Vérifier que PostgreSQL répond
docker-compose exec postgres psql -U ndjigi_user -d ndjigi_db -c "SELECT 1"
```

### 1.4 Tester la santé de l'API

```bash
# Health check
curl http://localhost:8000/health

# Résultat attendu:
# {"success":true,"status":"ok","timestamp":"2026-05-15T..."}
```

---

## Phase 2: Configuration Keycloak (10-15 min)

### 2.1 Accéder à l'Admin Console

1. Ouvrir `http://localhost:8080`
2. Se connecter:
   - **Username:** `admin`
   - **Password:** `admin_password_change_me_prod`

### 2.2 Configuration manuelle (simplifié)

#### Créer le Realm

```
1. Click "Create Realm" en haut à droite
2. Name: ndjigi
3. Enabled: ON
4. Click "Create"
```

#### Créer les Rôles

```
Realm Settings > Roles > Create role
- ndjigi-admin (Description: Administrateur du système)
- ndjigi-gestionnaire (Description: Gestionnaire de parking)
- ndjigi-chauffeur (Description: Chauffeur)
- ndjigi-passager (Description: Passager)
```

#### Créer le Client Backend

```
Clients > Create
Client ID: ndjigi-backend
Client Protocol: openid-connect
Root URL: http://backend:8000

Accès:
- Standard flow enabled: ON
- Direct access grants enabled: ON
- Service accounts enabled: ON
- Valid Redirect URIs: http://backend:8000/*
- Web Origins: http://backend:8000

Credentials tab:
- Copier le Client Secret (vous en aurez besoin)
```

#### Créer le Client Web

```
Clients > Create
Client ID: ndjigi-web
Name: N'DJIGI Web
Public Client: ON
Standard flow enabled: ON

Accès:
- Valid Redirect URIs:
  - http://localhost:3000/*
  - http://localhost:3000/callback
  - http://localhost:3000/silent-check-sso.html
- Web Origins: http://localhost:3000
```

### 2.3 Alternative: Script automatisé

```bash
# Rendre le script exécutable
chmod +x ./KEYCLOAK_SETUP.sh

# Exécuter le script
./KEYCLOAK_SETUP.sh
```

---

## Phase 3: Configuration Environnement (5 min)

### 3.1 Mettre à jour backend/.env

```bash
# Backend/.env
DATABASE_URL="postgresql://ndjigi_user:secure_password_change_me_prod@postgres:5432/ndjigi_db"
NODE_ENV=development
PORT=8000

KEYCLOAK_URL=http://keycloak:8080
KEYCLOAK_REALM=ndjigi
KEYCLOAK_CLIENT_ID=ndjigi-backend
KEYCLOAK_CLIENT_SECRET=<COPIER_LE_CLIENT_SECRET_DE_KEYCLOAK>

JWT_SECRET=change_this_secret_key
JWT_REFRESH_SECRET=change_this_refresh_secret
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

CORS_ORIGIN=http://localhost:3000,http://localhost:8081,http://web:3000
```

### 3.2 Mettre à jour web/n-djigi/.env

```bash
REACT_APP_API_URL=http://localhost:8000/api/v1
REACT_APP_KEYCLOAK_URL=http://localhost:8080
REACT_APP_KEYCLOAK_REALM=ndjigi
REACT_APP_KEYCLOAK_CLIENT_ID=ndjigi-web
```

### 3.3 Relancer les conteneurs

```bash
docker-compose down
docker-compose up -d
```

---

## Phase 4: Intégration Backend (10-15 min)

### 4.1 Installer les dépendances

```bash
cd backend

# Via npm
npm install keycloak-connect express-session

# Via conteneur Docker
docker-compose exec backend npm install keycloak-connect express-session
```

### 4.2 Mettre à jour les routes

Modifier `backend/src/routes/index.js`:

```javascript
const express = require('express');
const { dualAuthenticate } = require('../middlewares/dualAuth');
// Ou utilisez authenticateKeycloak pour Keycloak uniquement

const router = express.Router();

// Appliquer le middleware d'authentification
router.use(dualAuthenticate);

// Vos routes protégées ici
router.get('/utilisateurs', async (req, res) => {
  // req.user contient les infos de l'utilisateur
  res.json({ user: req.user });
});

module.exports = router;
```

### 4.3 Gérer les rôles dans les routes

```javascript
// Middleware de vérification des rôles
const requireRole = (requiredRoles) => {
  return (req, res, next) => {
    const userRoles = req.user?.roles || [];
    const hasRole = requiredRoles.some(role => userRoles.includes(role));
    
    if (!hasRole) {
      return res.status(403).json({
        success: false,
        message: 'Accès refusé.'
      });
    }
    next();
  };
};

// Utilisation
router.get('/admin/stats', 
  dualAuthenticate, 
  requireRole(['ndjigi-admin']), 
  async (req, res) => {
    // Seuls les admins peuvent accéder
  }
);
```

---

## Phase 5: Intégration Frontend (15-20 min)

### 5.1 Installer les dépendances

```bash
cd web/n-djigi

npm install keycloak-js axios
```

### 5.2 Copier les fichiers de configuration

```bash
# Copier depuis le guide
# Voir KEYCLOAK_FRONTEND.md pour les détails complets
```

Fichiers à créer:
- ✅ `src/services/keycloakService.js`
- ✅ `src/context/KeycloakContext.jsx`
- ✅ `src/components/ProtectedRoute.jsx`
- ✅ `src/components/Login.jsx`
- ✅ `src/components/UserProfile.jsx`
- ✅ `src/services/apiService.js`
- ✅ `public/silent-check-sso.html`

### 5.3 Modifier le point d'entrée (index.js ou main.jsx)

```javascript
import { KeycloakProvider } from './context/KeycloakContext';

root.render(
  <React.StrictMode>
    <KeycloakProvider>
      <App />
    </KeycloakProvider>
  </React.StrictMode>
);
```

### 5.4 Utiliser ProtectedRoute dans App.jsx

```javascript
import { ProtectedRoute } from './components/ProtectedRoute';
import Login from './components/Login';
import Dashboard from './pages/Dashboard';

function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/dashboard" element={
        <ProtectedRoute>
          <Dashboard />
        </ProtectedRoute>
      } />
      <Route path="/admin" element={
        <ProtectedRoute requiredRoles={['ndjigi-admin']}>
          <AdminPanel />
        </ProtectedRoute>
      } />
    </Routes>
  );
}
```

---

## Phase 6: Migration de la Base de Données (5-10 min)

### 6.1 Appliquer les migrations Prisma

```bash
docker-compose exec backend npx prisma migrate deploy
```

### 6.2 Générer le client Prisma

```bash
docker-compose exec backend npx prisma generate
```

### 6.3 Vérifier la structure

```bash
docker-compose exec backend npx prisma studio

# Vérifier que la table utilisateurs a les colonnes:
# ✅ keycloak_id
# ✅ auth_provider
```

---

## Phase 7: Tests (10-15 min)

### 7.1 Créer un utilisateur de test dans Keycloak

```
Admin Console > Users > Create user
Username: testuser
Email: test@ndjigi.local
First name: Test
Last name: User
Enabled: ON

Credentials tab:
- Set password: TestPassword123!
- Temporary: OFF
```

### 7.2 Assigner un rôle

```
Users > testuser > Role mappings
Available roles > ndjigi-passager > Add selected
```

### 7.3 Tester le login

1. Ouvrir `http://localhost:3000`
2. Vous devriez être redirigé vers Keycloak
3. Vous connecter avec `testuser / TestPassword123!`
4. Vérifier que vous êtes redirigé à `http://localhost:3000`

### 7.4 Tester l'API

```bash
# Obtenir un token (simulé, le vrai provient de Keycloak)
TOKEN="<token_from_keycloak>"

# Tester une route protégée
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/v1/utilisateurs
```

---

## 🎉 Succès!

Votre application est maintenant:
- ✅ Dockerisée (backend, frontend, base de données, Keycloak)
- ✅ Protégée par Keycloak
- ✅ Supportant la gestion des rôles
- ✅ Prête pour la production

---

## 📚 Documentation Complète

Voir les fichiers:
- 📄 **DOCKERIZE_KEYCLOAK.md** - Guide détaillé complet
- 📄 **KEYCLOAK_FRONTEND.md** - Intégration React/Vue
- 📄 **PRISMA_MIGRATION_KEYCLOAK.md** - Migrations base de données
- 📝 **docker-compose.yml** - Configuration Docker
- 🛠️ **KEYCLOAK_SETUP.sh** - Script d'automatisation

---

## 🆘 Troubleshooting

### Keycloak ne démarre pas

```bash
# Vérifier les logs
docker-compose logs keycloak

# Vérifier que PostgreSQL est prêt
docker-compose logs postgres

# Attendre quelques secondes et relancer
docker-compose restart keycloak
```

### Erreur: Connection refused

```bash
# Vérifier que tous les conteneurs sont actifs
docker-compose ps

# Recréer les conteneurs
docker-compose down
docker-compose up -d
```

### Token invalide

```bash
# Vérifier que KEYCLOAK_CLIENT_SECRET est correct dans .env
# Vérifier dans Keycloak Admin Console > Clients > ndjigi-backend > Credentials

# Redémarrer le backend
docker-compose restart backend
```

### Problèmes de CORS

```bash
# Vérifier que Web Origins est correct dans Keycloak
# Admin Console > Realm: ndjigi > Clients > ndjigi-web

# Ajouter votre URL si nécessaire
# Puis redémarrer Keycloak
docker-compose restart keycloak
```

---

## 📞 Besoin d'aide?

1. Consulter la **documentation officielle**:
   - [Keycloak Docs](https://www.keycloak.org/documentation)
   - [Docker Compose Docs](https://docs.docker.com/compose/)
   - [Prisma Docs](https://www.prisma.io/docs)

2. Vérifier les **logs** des conteneurs:
   ```bash
   docker-compose logs -f [service]
   ```

3. Se connecter **dans un conteneur**:
   ```bash
   docker-compose exec backend bash
   docker-compose exec postgres psql -U ndjigi_user -d ndjigi_db
   ```

---

## ✅ Checklist finale

- [ ] Docker et docker-compose installés
- [ ] `docker-compose up -d` fonctionne
- [ ] Keycloak accessible sur `http://localhost:8080`
- [ ] Realm `ndjigi` créé
- [ ] Clients (backend, web) créés
- [ ] Rôles créés
- [ ] Variables d'environnement configurées
- [ ] Backend relancé
- [ ] Frontend configuré avec Keycloak
- [ ] Migrations Prisma appliquées
- [ ] Utilisateur de test créé
- [ ] Login/logout fonctionnent
- [ ] Routes protégées fonctionnent
- [ ] Gestion des rôles fonctionne

---

**Dernière mise à jour:** Mai 2026

Bonne dockerisation et intégration Keycloak! 🚀
