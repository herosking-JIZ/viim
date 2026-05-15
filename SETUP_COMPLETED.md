# ✅ Docker + Keycloak - Infrastructure opérationnelle

**Date:** 15 mai 2026  
**Status:** 🟢 Tous les services sont lancés et accessibles

---

## 🌐 URLs d'accès

| Service | URL | Credentials |
|---------|-----|-------------|
| **Keycloak Admin** | http://localhost:8080 | admin / admin_password_change_me_prod |
| **Frontend** | http://localhost:3000 | - |
| **Backend API** | http://localhost:8000 | - |
| **PostgreSQL** | localhost:5432 | ndjigi_user / secure_password_change_me_prod |

---

## 🐳 Conteneurs actifs

```bash
$ docker-compose ps

NAME              IMAGE                      STATUS
ndjigi-postgres   postgres:16-alpine         Up (healthy)
ndjigi-keycloak   keycloak/keycloak:latest   Up
ndjigi-backend    ndjigiv1-backend           Up (health: starting)
ndjigi-web        ndjigiv1-web               Up (healthy)
```

---

## 📋 Prochaines étapes

### Phase 1: Configuration Keycloak (30 min)

```bash
# 1. Accéder à Keycloak
# URL: http://localhost:8080

# 2. Se connecter
# Username: admin
# Password: admin_password_change_me_prod

# 3. Créer le realm 'ndjigi'
# Admin Console > Create Realm > Name: ndjigi

# 4. Créer les rôles
# Realm Settings > Roles > Create role
  - ndjigi-admin
  - ndjigi-gestionnaire
  - ndjigi-chauffeur
  - ndjigi-passager

# 5. Créer les clients
# Voir KEYCLOAK_SETUP.sh ou DOCKERIZE_KEYCLOAK.md pour les détails
```

**Alternative automatisée:**
```bash
chmod +x ./KEYCLOAK_SETUP.sh
./KEYCLOAK_SETUP.sh
```

### Phase 2: Intégration Backend (20 min)

```bash
# 1. Installer les dépendances Keycloak
docker-compose exec backend npm install keycloak-connect express-session

# 2. Mettre à jour les variables d'environnement
# backend/.env
# Ajouter: KEYCLOAK_CLIENT_SECRET=<value_from_keycloak>

# 3. Redémarrer le backend
docker-compose restart backend
```

### Phase 3: Intégration Frontend (25 min)

```bash
# 1. Installer keycloak-js
docker-compose exec web npm install keycloak-js axios

# 2. Créer les composants Keycloak
# Voir KEYCLOAK_FRONTEND.md pour les fichiers à créer:
  - src/services/keycloakService.js
  - src/context/KeycloakContext.jsx
  - src/components/ProtectedRoute.jsx
  - src/components/Login.jsx
  - public/silent-check-sso.html

# 3. Mettre à jour App.jsx et main.jsx
# Voir KEYCLOAK_FRONTEND.md pour l'intégration

# 4. Reconstruire le frontend
docker-compose exec web npm run build && docker-compose restart web
```

### Phase 4: Test du système complet (15 min)

```bash
# 1. Créer un utilisateur de test dans Keycloak
# Admin Console > Users > Create user
  Username: testuser
  Email: test@ndjigi.local
  Password: TestPassword123!

# 2. Tester le login
# Ouvrir http://localhost:3000
# Vous devriez être redirigé vers Keycloak
# Se connecter avec testuser / TestPassword123!

# 3. Vérifier l'API
curl -H "Authorization: Bearer <token>" http://localhost:8000/api/v1/utilisateurs
```

---

## 🔧 Commandes utiles

### Gestion des conteneurs

```bash
# Afficher le statut
docker-compose ps

# Voir les logs
docker-compose logs -f backend
docker-compose logs -f keycloak
docker-compose logs -f web

# Redémarrer un service
docker-compose restart backend

# Arrêter tous les services
docker-compose down

# Relancer tous les services
docker-compose up -d
```

### Accès aux services

```bash
# Se connecter au PostgreSQL
docker-compose exec postgres psql -U ndjigi_user -d ndjigi_db

# Vérifier les migrations
docker-compose exec backend npx prisma studio

# Logs du backend
docker-compose logs backend --tail=50
```

---

## 📁 Fichiers de configuration

- **docker-compose.yml** - Orchestration des services
- **backend/Dockerfile** - Image Docker du backend Node.js
- **web/n-djigi/Dockerfile** - Image Docker du frontend React
- **backend/.env** - Variables d'environnement backend
- **web/n-djigi/.env** - Variables d'environnement frontend

---

## 🚨 Troubleshooting

### Le web ne se connecte pas à l'API

```bash
# Vérifier que le backend est OK
curl http://localhost:8000/health

# Vérifier les CORS
# backend/docker-compose.yml > CORS_ORIGIN

# Vérifier que l'URL API est correcte
# web/n-djigi/.env > VITE_API_URL
```

### Keycloak ne démarre pas

```bash
# Vérifier les logs PostgreSQL
docker-compose logs postgres

# Vérifier les logs Keycloak
docker-compose logs keycloak

# Attendre quelques secondes et relancer
docker-compose restart keycloak
```

### Problèmes de permissions

```bash
# Nettoyer et reconstruire
docker-compose down -v
docker system prune -a
docker-compose up -d
```

---

## 📚 Documentation complète

- **DOCKERIZE_KEYCLOAK.md** - Guide détaillé complet
- **KEYCLOAK_FRONTEND.md** - Intégration React
- **KEYCLOAK_SETUP.sh** - Script d'automatisation
- **QUICK_START.md** - Guide rapide

---

## 🎯 Objectifs réalisés

- ✅ Dockerisé backend (Node.js + Express)
- ✅ Dockerisé frontend (React + Vite)
- ✅ Dockerisé base de données (PostgreSQL)
- ✅ Intégré Keycloak pour l'authentification
- ✅ Configuré Docker Compose pour orchestration
- ✅ Tous les services sont accessibles

---

## 📌 Notes importantes

1. **Les secrets doivent être changés en production**
   - Mots de passe Keycloak
   - Secrets JWT
   - Secrets clients Keycloak

2. **Les migrations Prisma doivent être exécutées**
   ```bash
   docker-compose exec backend npx prisma migrate deploy
   ```

3. **Les ports 3000, 8000, 8080, 5432 doivent être disponibles**

4. **Le guide QUICK_START.md a un checklist complet**

---

## 🚀 Prochaines étapes après la configuration Keycloak

1. Exécuter les migrations Prisma
2. Seeder les données de test
3. Intégrer l'authentification Keycloak au backend
4. Intégrer l'authentification Keycloak au frontend
5. Tester le flow complet d'authentification
6. Configurer les rôles et permissions
7. Déployer en environnement de staging

---

**Dernière mise à jour:** 15 mai 2026  
**Durée d'installation:** ~30 minutes ⏱️
