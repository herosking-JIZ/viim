# Guide Complet : Dockeriser et Intégrer Keycloak

## 📋 Table des matières

1. [Architecture globale](#architecture-globale)
2. [Dockerisation du projet](#dockerisation-du-projet)
3. [Configuration Keycloak](#configuration-keycloak)
4. [Intégration Keycloak dans le backend](#intégration-keycloak-dans-le-backend)
5. [Migration de l'authentification](#migration-de-lauthentification)
6. [Déploiement complet](#déploiement-complet)

---

## Architecture globale

```
┌─────────────────────────────────────────────────────────┐
│                    Docker Compose                        │
├─────────────────────────────────────────────────────────┤
│                                                           │
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│ │ PostgreSQL   │  │ Keycloak     │  │ Backend      │    │
│ │ (Port 5432)  │  │ (Port 8080)  │  │ (Port 8000)  │    │
│ └──────────────┘  └──────────────┘  └──────────────┘    │
│        ▲                  ▲                    ▲          │
│        └──────────────────┴────────────────────┘         │
│                  Connexions DB                           │
│                                                           │
│ ┌──────────────┐                                         │
│ │ Web Frontend │ ────────────► Backend + Keycloak       │
│ │ (localhost)  │                                         │
│ └──────────────┘                                         │
│                                                           │
│ ┌──────────────┐                                         │
│ │ Mobile App   │ ────────────► Backend + Keycloak       │
│ │ (Flutter)    │                                         │
│ └──────────────┘                                         │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

---

## Dockerisation du projet

### 1. Créer `docker-compose.yml` à la racine du projet

```yaml
version: '3.8'

services:
  # ============================================
  # PostgreSQL Database
  # ============================================
  postgres:
    image: postgres:16-alpine
    container_name: ndjigi-postgres
    environment:
      POSTGRES_USER: ndjigi_user
      POSTGRES_PASSWORD: secure_password_change_me
      POSTGRES_DB: ndjigi_db
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --locale=en_US.UTF-8"
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backend/prisma/migrations:/docker-entrypoint-initdb.d:ro
    networks:
      - ndjigi-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ndjigi_user"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ============================================
  # Keycloak Identity Provider
  # ============================================
  keycloak:
    image: keycloak/keycloak:latest
    container_name: ndjigi-keycloak
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin_password_change_me
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak_db
      KC_DB_USERNAME: ndjigi_user
      KC_DB_PASSWORD: secure_password_change_me
      KC_HOSTNAME_STRICT: false
      KC_PROXY: edge
      KC_HTTP_ENABLED: true
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - ndjigi-network
    command:
      - start-dev
    # Pour la production, utiliser : start

  # ============================================
  # Backend Node.js/Express
  # ============================================
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: ndjigi-backend
    environment:
      NODE_ENV: development
      PORT: 8000
      DATABASE_URL: postgresql://ndjigi_user:secure_password_change_me@postgres:5432/ndjigi_db
      
      # Keycloak Configuration
      KEYCLOAK_URL: http://keycloak:8080
      KEYCLOAK_REALM: ndjigi
      KEYCLOAK_CLIENT_ID: ndjigi-backend
      KEYCLOAK_CLIENT_SECRET: your_client_secret_here
      KEYCLOAK_PUBLIC_KEY_URL: http://keycloak:8080/realms/ndjigi/protocol/openid-connect/certs
      
      # JWT Configuration (si toujours utilisé en interne)
      JWT_SECRET: your_jwt_secret_key
      JWT_REFRESH_SECRET: your_jwt_refresh_secret
      JWT_EXPIRES_IN: 15m
      JWT_REFRESH_EXPIRES_IN: 7d
      
      # Autres variables
      CORS_ORIGIN: http://localhost:3000,http://localhost:8081
    ports:
      - "8000:8000"
    depends_on:
      postgres:
        condition: service_healthy
      keycloak:
        condition: service_started
    volumes:
      - ./backend:/app
      - /app/node_modules
    networks:
      - ndjigi-network
    command: npm run dev

  # ============================================
  # Web Frontend (React/Vue)
  # ============================================
  web:
    build:
      context: ./web/n-djigi
      dockerfile: Dockerfile
    container_name: ndjigi-web
    environment:
      REACT_APP_API_URL: http://localhost:8000/api/v1
      REACT_APP_KEYCLOAK_URL: http://localhost:8080
      REACT_APP_KEYCLOAK_REALM: ndjigi
      REACT_APP_KEYCLOAK_CLIENT_ID: ndjigi-web
    ports:
      - "3000:3000"
    depends_on:
      - backend
    networks:
      - ndjigi-network
    # Optionnel: volumes en développement
    volumes:
      - ./web/n-djigi/src:/app/src
      - ./web/n-djigi/public:/app/public

volumes:
  postgres_data:

networks:
  ndjigi-network:
    driver: bridge
```

### 2. Créer `backend/Dockerfile`

```dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app

# Installer les dépendances
COPY package.json package-lock.json ./
RUN npm ci

# Copier le code
COPY . .

# Générer les types Prisma
RUN npm run prisma:generate || true

# Stage 2: Runtime
FROM node:20-alpine
WORKDIR /app

# Installer dumb-init pour gérer les signaux
RUN apk add --no-cache dumb-init

# Copier les dépendances depuis le builder
COPY --from=builder /app/node_modules ./node_modules

# Copier le code source et la config Prisma
COPY . .

# Créer un utilisateur non-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

USER nodejs

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8000/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

EXPOSE 8000

# Utiliser dumb-init pour gérer les signaux correctement
ENTRYPOINT ["dumb-init", "--"]
CMD ["npm", "run", "dev"]
```

### 3. Créer `backend/package.json` (mise à jour des scripts)

Ajouter/modifier les scripts dans `package.json`:

```json
{
  "scripts": {
    "dev": "nodemon app.js",
    "start": "node app.js",
    "seed": "node prisma/seed.js",
    "test": "echo \"Error: no test specified\" && exit 1",
    "prisma:generate": "prisma generate",
    "prisma:migrate": "prisma migrate dev",
    "prisma:studio": "prisma studio"
  }
}
```

### 4. Créer `web/n-djigi/Dockerfile`

```dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

# Stage 2: Runtime avec nginx
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY --from=builder /app/nginx.conf /etc/nginx/nginx.conf

EXPOSE 3000
CMD ["nginx", "-g", "daemon off;"]
```

### 5. Créer `web/n-djigi/nginx.conf` (si React)

```nginx
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 3000;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;

        location / {
            try_files $uri $uri/ /index.html;
        }

        location /api/v1/ {
            proxy_pass http://backend:8000/api/v1/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
```

---

## Configuration Keycloak

### 1. Configuration initiale

Une fois Keycloak lancé (`docker-compose up keycloak`):

1. Aller sur `http://localhost:8080`
2. Se connecter avec `admin / admin_password_change_me`
3. Créer un realm `ndjigi`

### 2. Créer le Realm "ndjigi"

```bash
# Via l'interface Admin Console
1. Click "Create realm"
2. Name: ndjigi
3. Enabled: ON
4. Click "Create"
```

### 3. Créer les Clients

#### Client Backend (confidential)

```
Clients > Create
- Client ID: ndjigi-backend
- Client Protocol: openid-connect
- Root URL: http://backend:8000

Access settings:
- Valid Redirect URIs: http://backend:8000/*
- Web Origins: http://backend:8000

Credentials:
- Client Authenticator: Client Id and Secret
- (Générer et sauvegarder le secret)
```

#### Client Web (public)

```
Clients > Create
- Client ID: ndjigi-web
- Client Protocol: openid-connect
- Root URL: http://localhost:3000

Access settings:
- Valid Redirect URIs: 
  - http://localhost:3000/*
  - http://localhost:3000/callback
- Web Origins: http://localhost:3000
```

#### Client Mobile (public)

```
Clients > Create
- Client ID: ndjigi-mobile
- Client Protocol: openid-connect
- Root URL: app://ndjigi-mobile

Access settings:
- Valid Redirect URIs: 
  - app://ndjigi-mobile/*
  - io.flutter.plugins.firebase.auth://
```

### 4. Créer les Rôles

```
Roles > Create role
- ndjigi-admin
- ndjigi-gestionnaire
- ndjigi-chauffeur
- ndjigi-passager
```

### 5. Créer les Utilisateurs (optionnel, pour les tests)

```
Users > Create user
- Username: testuser
- Email: test@example.com
- Assign roles: ndjigi-passager
- Set Password: (temporary or permanent)
```

---

## Intégration Keycloak dans le backend

### 1. Installer les dépendances

```bash
npm install keycloak-connect express-session
```

Ajouter au `package.json`:

```json
{
  "dependencies": {
    "keycloak-connect": "^23.0.0",
    "express-session": "^1.17.3",
    "jsonwebtoken": "^9.0.3"
  }
}
```

### 2. Créer `backend/src/config/keycloak.js`

```javascript
const KeycloakConnect = require('keycloak-connect');
const session = require('express-session');

const keycloakConfig = {
  realm: process.env.KEYCLOAK_REALM || 'ndjigi',
  'bearer-only': true,
  'auth-server-url': process.env.KEYCLOAK_URL || 'http://localhost:8080',
  'ssl-required': 'none',
  resource: process.env.KEYCLOAK_CLIENT_ID || 'ndjigi-backend',
  'public-client': false,
  credentials: {
    secret: process.env.KEYCLOAK_CLIENT_SECRET
  }
};

// Initialiser Keycloak
const keycloak = new KeycloakConnect({}, keycloakConfig);

module.exports = { keycloak, keycloakConfig };
```

### 3. Modifier `backend/app.js` pour intégrer Keycloak

```javascript
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const { connectDB, disconnectDB } = require('./src/config/db');
const { keycloak } = require('./src/config/keycloak');
const route = require('./src/routes/index');

const app = express();
app.set('etag', false);
const PORT = process.env.PORT || 8000;

// Connexion à la base de données
connectDB();

// --- MIDDLEWARES DE SÉCURITÉ ---
app.use(helmet());

app.use(cors({
  origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'],
  credentials: true
}));

// Initialiser Keycloak
app.use(keycloak.middleware());

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: {
    success: false,
    message: "Trop de requêtes, réessayez plus tard."
  }
});
app.use(limiter);

// --- PARSING ---
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true }));

// --- ERROR HANDLERS & ROUTES ---
// ... (reste du code app.js)

app.use('/api/v1', keycloak.protect(), route);

// Health Check
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    status: 'ok',
    timestamp: new Date().toISOString()
  });
});

const server = app.listen(PORT, () => {
  console.log(`🚀 Serveur N'DJIGI à l'écoute sur le port : ${PORT}`);
});

// ... (reste du code pour graceful shutdown)
```

### 4. Créer `backend/src/middlewares/authenticateKeycloak.js` (nouveau middleware)

```javascript
const jwt = require('jsonwebtoken');

const authenticateKeycloak = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Token manquant. Connectez-vous.'
      });
    }

    const token = authHeader.split(' ')[1];

    // Vérifier le token (sans vérifier la signature car Keycloak l'a déjà fait)
    const decoded = jwt.decode(token, { complete: true });

    if (!decoded) {
      return res.status(401).json({
        success: false,
        message: 'Token invalide.'
      });
    }

    const payload = decoded.payload;

    // Attacher l'utilisateur à req.user
    req.user = {
      id_utilisateur: payload.sub,
      email: payload.email,
      prenom: payload.given_name,
      nom: payload.family_name,
      roles: payload.realm_access?.roles || [],
      keycloak_id: payload.sub
    };

    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Token invalide.'
    });
  }
};

module.exports = { authenticateKeycloak };
```

---

## Migration de l'authentification

### Phase 1 : Dual Authentication (Support JWT et Keycloak)

Créer un middleware `backend/src/middlewares/dualAuth.js`:

```javascript
const { verifyAccessToken } = require('../utils/jwt');
const jwt = require('jsonwebtoken');
const { prisma } = require('../config/db');

const dualAuthenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Token manquant. Connectez-vous.'
      });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.decode(token, { complete: true });

    // Vérifier si c'est un token Keycloak (a "iss" claim)
    if (decoded.payload.iss?.includes('keycloak')) {
      // Token Keycloak
      req.user = {
        id_utilisateur: decoded.payload.sub,
        email: decoded.payload.email,
        prenom: decoded.payload.given_name,
        nom: decoded.payload.family_name,
        roles: decoded.payload.realm_access?.roles || [],
        auth_provider: 'keycloak'
      };
    } else {
      // Token JWT custom
      const jwtDecoded = verifyAccessToken(token);
      
      const user = await prisma.utilisateur.findUnique({
        where: { id_utilisateur: jwtDecoded.sub },
        include: {
          utilisateur_role: { where: { actif: true } }
        }
      });

      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Utilisateur non trouvé.'
        });
      }

      const { mot_de_passe_hash, reset_token, ...userSafe } = user;
      req.user = { ...userSafe, auth_provider: 'jwt' };
    }

    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Token invalide.'
    });
  }
};

module.exports = { dualAuthenticate };
```

### Phase 2 : Migration de la base de données

Ajouter les champs Keycloak à la table utilisateur:

```prisma
// backend/prisma/schema.prisma

model Utilisateur {
  id_utilisateur     String   @id @default(cuid())
  email              String   @unique
  numero_telephone   String?  @unique
  nom                String
  prenom             String
  mot_de_passe_hash  String   // Garder pour retrocompatibilité
  
  // Nouveaux champs Keycloak
  keycloak_id        String?  @unique // ID Keycloak de l'utilisateur
  auth_provider      String   @default("jwt") // "jwt" ou "keycloak"
  
  reset_token        String?
  reset_token_expire DateTime?
  bloque_jusqu_au    DateTime?
  created_at         DateTime @default(now())
  updated_at         DateTime @updatedAt

  utilisateur_role   UtilisateurRole[]
  
  @@map("utilisateurs")
}

model UtilisateurRole {
  id                String   @id @default(cuid())
  id_utilisateur    String
  utilisateur       Utilisateur @relation(fields: [id_utilisateur], references: [id_utilisateur], onDelete: Cascade)
  role              String
  actif             Boolean  @default(true)
  
  @@unique([id_utilisateur, role])
  @@map("utilisateurs_roles")
}
```

Créer une migration:

```bash
npx prisma migrate dev --name add_keycloak_fields
```

---

## Déploiement complet

### 1. Lancer l'infrastructure

```bash
# À la racine du projet
docker-compose up -d

# Vérifier que tout est lancé
docker-compose ps

# Afficher les logs
docker-compose logs -f
```

### 2. Initialiser la base de données

```bash
# Se connecter au conteneur backend
docker-compose exec backend bash

# Exécuter les migrations Prisma
npx prisma migrate deploy

# Seeder les données de base (optionnel)
npm run seed

# Quitter le conteneur
exit
```

### 3. Tester Keycloak

```bash
# Accéder au Admin Console
http://localhost:8080

# Créer le realm et les clients selon la section "Configuration Keycloak"
```

### 4. Tester l'API Backend

```bash
# Health check
curl http://localhost:8000/health

# Lister les utilisateurs (une fois protégé par Keycloak)
curl -H "Authorization: Bearer <token>" http://localhost:8000/api/v1/utilisateurs
```

### 5. Arrêter l'infrastructure

```bash
docker-compose down

# Avec suppression des volumes (attention!)
docker-compose down -v
```

---

## Checklist de migration

- [ ] Créer le fichier `docker-compose.yml`
- [ ] Créer les `Dockerfile` pour backend et web
- [ ] Installer les dépendances Keycloak (`npm install keycloak-connect`)
- [ ] Configurer Keycloak (realm, clients, rôles)
- [ ] Implémenter le dual auth middleware
- [ ] Ajouter les champs Keycloak à Prisma schema
- [ ] Migrer les données utilisateur
- [ ] Tester l'authentification Keycloak
- [ ] Mettre à jour le frontend pour utiliser Keycloak
- [ ] Mettre à jour la mobile pour utiliser Keycloak
- [ ] Désactiver l'ancienne authentification JWT (phase 3)
- [ ] Déployer en production

---

## Configuration .env (backend)

```env
# Database
DATABASE_URL="postgresql://ndjigi_user:secure_password_change_me@postgres:5432/ndjigi_db"

# Server
NODE_ENV=development
PORT=8000

# Keycloak
KEYCLOAK_URL=http://keycloak:8080
KEYCLOAK_REALM=ndjigi
KEYCLOAK_CLIENT_ID=ndjigi-backend
KEYCLOAK_CLIENT_SECRET=<your_client_secret>

# JWT (pour rétrocompatibilité temporaire)
JWT_SECRET=your_jwt_secret_key
JWT_REFRESH_SECRET=your_jwt_refresh_secret
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# CORS
CORS_ORIGIN=http://localhost:3000,http://localhost:8081

# Email (optionnel)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
```

---

## Ressources utiles

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [keycloak-connect GitHub](https://github.com/keycloak/keycloak-node-connect)
- [Docker Compose Docs](https://docs.docker.com/compose/)
- [Prisma Migrations](https://www.prisma.io/docs/orm/prisma-migrate/understanding-prisma-migrate)
