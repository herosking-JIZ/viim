/**
 * MIDDLEWARES/AUTHENTICATEKEYCLOAK.JS — Vérification des tokens Keycloak
 */

const jwt = require('jsonwebtoken');
const { prisma } = require('../config/db');
const { getRedisClient } = require('../config/redis');
const { getLocalRole } = require('../constants/roles');
const redis = getRedisClient();

/**
 * Middleware d'authentification Keycloak
 * Vérifie le token Bearer, la blacklist, et attache l'utilisateur à req.user
 */
const authenticateKeycloak = async (req, res, next) => {
  try {
    // 1. Récupérer le token dans le header
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Token manquant. Connectez-vous.'
      });
    }

    // Handle double "Bearer Bearer" prefix from frontend
    let token = authHeader.replace('Bearer ', '').trim();
    // Remove any additional "Bearer " prefix if present
    token = token.replace(/^Bearer\s+/i, '').trim();

    // 2. Décoder le token (sans vérifier la signature car Keycloak l'a déjà fait)
    const decoded = jwt.decode(token, { complete: true });

    if (!decoded || !decoded.payload) {
      return res.status(401).json({
        success: false,
        message: 'Token invalide.'
      });
    }

    const payload = decoded.payload;

    // 3. Vérifier que le token n'est pas expiré
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp && payload.exp < now) {
      return res.status(401).json({
        success: false,
        message: 'Session expirée. Reconnectez-vous.',
        code: 'TOKEN_EXPIRED'
      });
    }

    // 4. Vérifier si le token est dans la blacklist (logout)
    const jti = payload.jti || payload.sub;
    const isBlacklisted = await redis.exists(`blacklist:${jti}`);
    if (isBlacklisted) {
      return res.status(401).json({
        success: false,
        message: 'Token révoqué. Reconnectez-vous.',
        code: 'TOKEN_REVOKED'
      });
    }

    // 5. Chercher ou créer l'utilisateur en base de données (avec cache Redis)
    const cacheKey = `auth:user:${payload.sub}`;
    let user = null;

    // Essayer de récupérer du cache Redis (TTL 60s)
    const cachedUser = await redis.get(cacheKey);
    if (cachedUser) {
      user = JSON.parse(cachedUser);
    } else {
      // Pas en cache → requête BD
      user = await prisma.utilisateur.findUnique({
        where: { keycloak_id: payload.sub },
        include: {
          utilisateur_role: { where: { actif: true } }
        }
      });

      // Si l'utilisateur n'existe pas par keycloak_id, chercher par email
      if (!user) {
        // Chercher un utilisateur existant avec le même email
        user = await prisma.utilisateur.findUnique({
          where: { email: payload.email },
          include: {
            utilisateur_role: { where: { actif: true } }
          }
        });

        if (user) {
          // Email existe → mettre à jour le keycloak_id (lier le compte)
          console.log(`🔗 Liaison Keycloak: ${payload.email} (ID: ${user.id_utilisateur}) → keycloak_id=${payload.sub}`);
          user = await prisma.utilisateur.update({
            where: { id_utilisateur: user.id_utilisateur },
            data: { keycloak_id: payload.sub },
            include: {
              utilisateur_role: { where: { actif: true } }
            }
          });
        } else {
          // Aucun compte existant → créer un nouvel utilisateur
          const numeroTelephone = payload.numero_telephone || payload.phone_number;

          if (!numeroTelephone) {
            return res.status(422).json({
              success: false,
              message: 'Numéro de téléphone requis.',
              code: 'PHONE_NUMBER_REQUIRED',
              keycloak_data: {
                keycloak_id: payload.sub,
                email: payload.email,
                prenom: payload.given_name || '',
                nom: payload.family_name || '',
              }
            });
          }

          console.log(`✅ Création d'un nouvel utilisateur depuis Keycloak: ${payload.email}`);
          user = await prisma.utilisateur.create({
            data: {
              keycloak_id: payload.sub,
              email: payload.email,
              prenom: payload.given_name || '',
              nom: payload.family_name || '',
              numero_telephone: numeroTelephone,
              mot_de_passe_hash: 'KEYCLOAK_AUTH',
              auth_provider: 'keycloak',
              utilisateur_role: {
                create: { role: 'passager', actif: true }
              }
            },
            include: {
              utilisateur_role: { where: { actif: true } }
            }
          });
        }
      }

      // user est toujours non-null ici (trouvé ou créé)
      await redis.setex(cacheKey, 60, JSON.stringify(user));
    }

    // 6. Check if account is pending activation (invitation system)
    if (user.statut_compte === 'en_attente_activation') {
      return res.status(403).json({
        success: false,
        message: 'Compte non activé. Veuillez accepter l\'invitation par email.',
        code: 'ACCOUNT_PENDING_ACTIVATION'
      });
    }

    // 7. Vérifier si l'utilisateur est bloqué
    if (user.bloque_jusqu_au && user.bloque_jusqu_au > new Date()) {
      return res.status(401).json({
        success: false,
        message: 'Compte temporairement bloqué.',
        bloque_jusqu_au: user.bloque_jusqu_au
      });
    }

    // 8. Extraire et convertir les rôles depuis le token Keycloak
    // Keycloak token contient les rôles realm (ndjigi-admin, ndjigi-gestionnaire, etc.)
    const keycloakRealmRoles = payload.realm_access?.roles || [];

    // Convertir les rôles Keycloak realm en rôles locaux (admin, gestionnaire, etc.)
    const roles = keycloakRealmRoles
      .map(kcRole => getLocalRole(kcRole))
      .filter(role => role !== null); // Exclure les rôles invalides

    // 9. Attacher l'utilisateur à la requête
    const { mot_de_passe_hash, ...userSafe } = user;

    req.user = {
      ...userSafe,
      id_utilisateur: user.id_utilisateur, // Maintenir la compatibilité
      roles: roles,
      auth_provider: 'keycloak',
      keycloak_id: payload.sub
    };

    next();

  } catch (error) {
    console.error('❌ Erreur authentification Keycloak:', error.message);
    return res.status(401).json({
      success: false,
      message: 'Token invalide.'
    });
  }
};

module.exports = { authenticateKeycloak };
