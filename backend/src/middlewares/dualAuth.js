/**
 * MIDDLEWARES/DUALAUTH.JS — Support simultané JWT et Keycloak
 * Phase de transition vers Keycloak unique
 */

const jwt = require('jsonwebtoken');
const { verifyAccessToken } = require('../utils/jwt');
const { prisma } = require('../config/db');

/**
 * Middleware d'authentification dual
 * Accepte les tokens JWT (custom) et Keycloak
 */
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

    if (!decoded || !decoded.payload) {
      return res.status(401).json({
        success: false,
        message: 'Token invalide.'
      });
    }

    const payload = decoded.payload;

    // Déterminer le type de token basé sur l'issuer
    const isKeycloakToken = payload.iss?.includes('keycloak');

    if (isKeycloakToken) {
      // ========================================
      // Authentification Keycloak
      // ========================================

      // Vérifier l'expiration
      const now = Math.floor(Date.now() / 1000);
      if (payload.exp && payload.exp < now) {
        return res.status(401).json({
          success: false,
          message: 'Session expirée. Reconnectez-vous.',
          code: 'TOKEN_EXPIRED'
        });
      }

      // Chercher l'utilisateur en base
      let user = await prisma.utilisateur.findUnique({
        where: { keycloak_id: payload.sub },
        include: {
          utilisateur_role: { where: { actif: true } }
        }
      });

      // Créer l'utilisateur s'il n'existe pas
      if (!user) {
        console.log(`✅ Création utilisateur depuis Keycloak: ${payload.email}`);

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

      // Vérifier le blocage
      if (user.bloque_jusqu_au && user.bloque_jusqu_au > new Date()) {
        return res.status(401).json({
          success: false,
          message: 'Compte temporairement bloqué.',
          bloque_jusqu_au: user.bloque_jusqu_au
        });
      }

      const { mot_de_passe_hash, reset_token, ...userSafe } = user;
      req.user = {
        ...userSafe,
        id_utilisateur: user.id_utilisateur,
        roles: user.utilisateur_role?.map(r => r.role) || [],
        auth_provider: 'keycloak'
      };

    } else {
      // ========================================
      // Authentification JWT Custom (ancienne)
      // ========================================

      try {
        const jwtDecoded = verifyAccessToken(token);

        if (jwtDecoded.type !== 'access') {
          return res.status(401).json({
            success: false,
            message: 'Type de token invalide.'
          });
        }

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

        if (user.bloque_jusqu_au && user.bloque_jusqu_au > new Date()) {
          return res.status(401).json({
            success: false,
            message: 'Compte temporairement bloqué.',
            bloque_jusqu_au: user.bloque_jusqu_au
          });
        }

        const { mot_de_passe_hash, reset_token, ...userSafe } = user;
        req.user = {
          ...userSafe,
          id_utilisateur: user.id_utilisateur,
          roles: user.utilisateur_role?.map(r => r.role) || [],
          auth_provider: 'jwt'
        };

      } catch (error) {
        if (error.name === 'TokenExpiredError') {
          return res.status(401).json({
            success: false,
            message: 'Session expirée. Reconnectez-vous.',
            code: 'TOKEN_EXPIRED'
          });
        }
        throw error;
      }
    }

    next();

  } catch (error) {
    console.error('❌ Erreur authentification dual:', error.message);
    return res.status(401).json({
      success: false,
      message: 'Token invalide.'
    });
  }
};

module.exports = { dualAuthenticate };
