/**
 * MIDDLEWARES/AUTHENTICATEKEYCLOAK.JS — Vérification des tokens Keycloak
 */

const jwt = require('jsonwebtoken');
const { prisma } = require('../config/db');
const { redis } = require('../config/redis');

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

    const token = authHeader.split(' ')[1];

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

    // 5. Chercher ou créer l'utilisateur en base de données
    let user = await prisma.utilisateur.findUnique({
      where: { keycloak_id: payload.sub },
      include: {
        utilisateur_role: { where: { actif: true } }
      }
    });

    // Si l'utilisateur n'existe pas, le créer
    if (!user) {
      console.log(`✅ Création d'un nouvel utilisateur depuis Keycloak: ${payload.email}`);

      user = await prisma.utilisateur.create({
        data: {
          keycloak_id: payload.sub,
          email: payload.email,
          prenom: payload.given_name || '',
          nom: payload.family_name || '',
          numero_telephone: null,
          mot_de_passe_hash: 'KEYCLOAK_AUTH',
          auth_provider: 'keycloak',
          utilisateur_role: {
            create: {
              role: 'passager',
              actif: true
            }
          }
        },
        include: {
          utilisateur_role: { where: { actif: true } }
        }
      });
    }

    // 6. Vérifier si l'utilisateur est bloqué
    if (user.bloque_jusqu_au && user.bloque_jusqu_au > new Date()) {
      return res.status(401).json({
        success: false,
        message: 'Compte temporairement bloqué.',
        bloque_jusqu_au: user.bloque_jusqu_au
      });
    }

    // 7. Extraire les rôles depuis Keycloak ou depuis la base de données
    const keycloakRoles = payload.realm_access?.roles || [];
    const dbRoles = user.utilisateur_role?.map(r => r.role) || [];

    // Fusionner les rôles (priorité à ceux de Keycloak)
    const roles = [...new Set([...keycloakRoles, ...dbRoles])];

    // 8. Attacher l'utilisateur à la requête
    const { mot_de_passe_hash, reset_token, reset_token_expire, ...userSafe } = user;

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
