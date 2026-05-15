# Migration Prisma pour Keycloak

## 1. Modifier le schema Prisma

Mettre à jour `backend/prisma/schema.prisma`:

```prisma
// This is your Prisma schema file,
// learn more about it in the docs: https://pris.ly/d/prisma-schema

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ============================================
// UTILISATEURS ET AUTHENTIFICATION
// ============================================

model Utilisateur {
  id_utilisateur     String   @id @default(cuid())
  
  // Infos de base
  email              String   @unique
  numero_telephone   String?  @unique
  nom                String
  prenom             String
  
  // Authentification
  mot_de_passe_hash  String?  // Null pour les utilisateurs Keycloak
  auth_provider      String   @default("jwt") // "jwt" ou "keycloak"
  
  // Keycloak
  keycloak_id        String?  @unique
  
  // Récupération de mot de passe
  reset_token        String?
  reset_token_expire DateTime?
  
  // Blocage du compte
  bloque_jusqu_au    DateTime?
  
  // Timestamps
  created_at         DateTime @default(now())
  updated_at         DateTime @updatedAt
  
  // Relations
  utilisateur_role   UtilisateurRole[]
  gestionnaire       Gestionnaire?
  
  @@map("utilisateurs")
}

model UtilisateurRole {
  id                String   @id @default(cuid())
  id_utilisateur    String
  utilisateur       Utilisateur @relation(fields: [id_utilisateur], references: [id_utilisateur], onDelete: Cascade)
  role              String
  actif             Boolean  @default(true)
  
  created_at        DateTime @default(now())
  
  @@unique([id_utilisateur, role])
  @@map("utilisateurs_roles")
}

// ============================================
// AUTRES MODÈLES (exemples)
// ============================================

model Gestionnaire {
  id_gestionnaire    String   @id @default(cuid())
  id_utilisateur     String   @unique
  utilisateur        Utilisateur @relation(fields: [id_utilisateur], references: [id_utilisateur], onDelete: Cascade)
  id_parking         String
  
  created_at         DateTime @default(now())
  updated_at         DateTime @updatedAt
  
  @@map("gestionnaires")
}

// Ajouter vos autres modèles ici (Parking, Chauffeur, etc.)
```

## 2. Créer la migration

```bash
cd backend

# Créer une migration pour les changements Keycloak
npx prisma migrate dev --name add_keycloak_support

# Ou pour la production (sans prompt)
npx prisma migrate deploy
```

## 3. Script de migration des utilisateurs existants

Créer `backend/scripts/migrate-to-keycloak.js`:

```javascript
/**
 * SCRIPTS/MIGRATE-TO-KEYCLOAK.JS
 * Migration des utilisateurs existants vers Keycloak
 * À exécuter MANUELLEMENT avant de désactiver JWT
 */

const { prisma } = require('../src/config/db');

async function migrateUsers() {
  try {
    console.log('🔄 Début de la migration des utilisateurs vers Keycloak...\n');

    // Étape 1: Sauvegarder les anciennes données
    const backupFile = `users-backup-${Date.now()}.json`;
    const allUsers = await prisma.utilisateur.findMany({
      include: { utilisateur_role: true }
    });

    require('fs').writeFileSync(backupFile, JSON.stringify(allUsers, null, 2));
    console.log(`✅ Sauvegarde créée: ${backupFile}\n`);

    // Étape 2: Mettre à jour les utilisateurs JWT existants
    console.log('📝 Mise à jour des utilisateurs...');
    
    const updated = await prisma.utilisateur.updateMany({
      where: {
        auth_provider: 'jwt'
      },
      data: {
        // Garder les données existantes, juste updater le flag
        // Ne pas supprimer les mots de passe (nécessaires si rollback)
      }
    });

    console.log(`✅ ${updated.count} utilisateurs mis à jour\n`);

    // Étape 3: Lister les utilisateurs qui doivent être migrés manuellement
    const jwtUsers = await prisma.utilisateur.findMany({
      where: {
        auth_provider: 'jwt',
        keycloak_id: null
      },
      select: {
        id_utilisateur: true,
        email: true,
        prenom: true,
        nom: true
      }
    });

    console.log('📋 Utilisateurs à créer dans Keycloak:\n');
    jwtUsers.forEach((user, idx) => {
      console.log(`${idx + 1}. ${user.prenom} ${user.nom} (${user.email})`);
    });

    console.log(`\n⚠️  Total: ${jwtUsers.length} utilisateurs`);
    console.log('\n⚠️  Actions manuelles requises:');
    console.log('   1. Créer ces utilisateurs dans Keycloak');
    console.log('   2. Récupérer leurs keycloak_id');
    console.log('   3. Exécuter le script sync-keycloak-ids.js');

    await prisma.$disconnect();

  } catch (error) {
    console.error('❌ Erreur migration:', error);
    process.exit(1);
  }
}

// Exécuter la migration
migrateUsers();
```

## 4. Script de synchronisation des IDs Keycloak

Créer `backend/scripts/sync-keycloak-ids.js`:

```javascript
/**
 * SCRIPTS/SYNC-KEYCLOAK-IDS.JS
 * Synchronise les utilisateurs de Keycloak avec la base de données
 */

const { prisma } = require('../src/config/db');
const axios = require('axios');

const KEYCLOAK_URL = process.env.KEYCLOAK_URL || 'http://localhost:8080';
const REALM = process.env.KEYCLOAK_REALM || 'ndjigi';
const CLIENT_ID = process.env.KEYCLOAK_CLIENT_ID;
const CLIENT_SECRET = process.env.KEYCLOAK_CLIENT_SECRET;

async function getAccessToken() {
  try {
    const response = await axios.post(
      `${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token`,
      new URLSearchParams({
        client_id: 'admin-cli',
        username: 'admin',
        password: process.env.KEYCLOAK_ADMIN_PASSWORD,
        grant_type: 'password'
      })
    );
    return response.data.access_token;
  } catch (error) {
    throw new Error(`Impossible d'obtenir le token admin: ${error.message}`);
  }
}

async function getKeycloakUsers(token) {
  try {
    const response = await axios.get(
      `${KEYCLOAK_URL}/admin/realms/${REALM}/users`,
      {
        headers: { Authorization: `Bearer ${token}` }
      }
    );
    return response.data;
  } catch (error) {
    throw new Error(`Impossible de récupérer les utilisateurs Keycloak: ${error.message}`);
  }
}

async function syncUsers() {
  try {
    console.log('🔄 Synchronisation des utilisateurs Keycloak...\n');

    const token = await getAccessToken();
    console.log('✅ Token admin obtenu\n');

    const keycloakUsers = await getKeycloakUsers(token);
    console.log(`📋 ${keycloakUsers.length} utilisateurs trouvés dans Keycloak\n`);

    let synced = 0;
    let created = 0;
    let errors = 0;

    for (const keycloakUser of keycloakUsers) {
      try {
        const existingUser = await prisma.utilisateur.findUnique({
          where: { email: keycloakUser.email }
        });

        if (existingUser) {
          // Mise à jour avec l'ID Keycloak
          await prisma.utilisateur.update({
            where: { id_utilisateur: existingUser.id_utilisateur },
            data: {
              keycloak_id: keycloakUser.id,
              auth_provider: 'keycloak'
            }
          });
          synced++;
          console.log(`✅ ${keycloakUser.email} synchronisé`);
        } else {
          // Création d'un nouvel utilisateur
          await prisma.utilisateur.create({
            data: {
              keycloak_id: keycloakUser.id,
              email: keycloakUser.email,
              prenom: keycloakUser.firstName || '',
              nom: keycloakUser.lastName || '',
              mot_de_passe_hash: 'KEYCLOAK_AUTH',
              auth_provider: 'keycloak',
              utilisateur_role: {
                create: {
                  role: 'passager',
                  actif: true
                }
              }
            }
          });
          created++;
          console.log(`🆕 ${keycloakUser.email} créé`);
        }
      } catch (error) {
        errors++;
        console.error(`❌ Erreur avec ${keycloakUser.email}:`, error.message);
      }
    }

    console.log(`\n========================================`);
    console.log(`✅ Synchronisés: ${synced}`);
    console.log(`🆕 Créés: ${created}`);
    console.log(`❌ Erreurs: ${errors}`);
    console.log(`========================================`);

    await prisma.$disconnect();

  } catch (error) {
    console.error('❌ Erreur synchronisation:', error.message);
    process.exit(1);
  }
}

syncUsers();
```

## 5. Ajouter les scripts au package.json

Mettre à jour `backend/package.json`:

```json
{
  "scripts": {
    "dev": "nodemon app.js",
    "start": "node app.js",
    "seed": "node prisma/seed.js",
    "prisma:generate": "prisma generate",
    "prisma:migrate": "prisma migrate dev",
    "prisma:deploy": "prisma migrate deploy",
    "prisma:studio": "prisma studio",
    "migrate:to-keycloak": "node scripts/migrate-to-keycloak.js",
    "sync:keycloak-ids": "node scripts/sync-keycloak-ids.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  }
}
```

## 6. Exécuter la migration

### Phase 1: Préparation

```bash
# Générer le client Prisma avec les nouveaux modèles
npx prisma generate

# Créer la migration
npx prisma migrate dev --name add_keycloak_support

# Vérifier les changements
npx prisma studio
```

### Phase 2: Migration des utilisateurs

```bash
# Sauvegarder et lister les utilisateurs
npm run migrate:to-keycloak

# À ce stade:
# 1. Créer manuellement les utilisateurs dans Keycloak
# 2. OU utiliser un script Keycloak pour les créer en masse
# 3. Récupérer leurs IDs
```

### Phase 3: Synchronisation

```bash
# Synchroniser les IDs Keycloak avec la base
npm run sync:keycloak-ids
```

## 7. Vérifier la migration

```bash
# Ouvrir Prisma Studio
npx prisma studio

# Vérifier que:
# ✅ Les utilisateurs ont keycloak_id rempli
# ✅ auth_provider = "keycloak" pour les utilisateurs migrés
# ✅ Les rôles sont toujours intacts
```

## 8. Rollback en cas de problème

```bash
# Si quelque chose se passe mal
npx prisma migrate resolve --rolled-back add_keycloak_support

# Restaurer depuis la sauvegarde JSON si nécessaire
node scripts/restore-from-backup.js
```

## Checklist Migration

- [ ] Sauvegarder la base de données
- [ ] Créer la migration Prisma
- [ ] Exécuter `prisma migrate deploy`
- [ ] Lister les utilisateurs JWT avec `migrate:to-keycloak`
- [ ] Créer ces utilisateurs dans Keycloak
- [ ] Synchroniser les IDs avec `sync:keycloak-ids`
- [ ] Vérifier dans Prisma Studio
- [ ] Tester les logins avec Keycloak
- [ ] Tester les logins JWT (compatible jusqu'à désactivation)
- [ ] Désactiver JWT dans les routes (phase 3)
