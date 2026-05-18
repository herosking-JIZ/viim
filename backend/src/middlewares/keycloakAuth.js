/**
 * MIDDLEWARES/KEYCLOAKAUTH.JS
 * Validation Keycloak + auto-provisioning utilisateurs
 *
 * Flow:
 *  1. Extrait Bearer token
 *  2. Valide via JWKS (RS256, iss, exp, aud)
 *  3. Si user inexistant en BDD → crée ligne utilisateur (auto-provisioning)
 *  4. Synchronise les rôles depuis token.realm_access.roles
 *  5. Attache req.user avec rôles Keycloak
 */

const { verifyKeycloakToken } = require('../config/keycloak');
const { prisma } = require('../config/db');

const keycloakAuth = async (req, res, next) => {
  try {
    // 1️⃣ Récupérer et vérifier le format du header
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Token manquant. Connectez-vous.',
        code: 'NO_TOKEN'
      });
    }

    const token = authHeader.split(' ')[1];

    // 2️⃣ Valider le token via JWKS
    let decoded;
    try {
      decoded = await verifyKeycloakToken(token);
    } catch (err) {
      console.error('❌ Token validation error:', err.message);
      return res.status(401).json({
        success: false,
        message: 'Token invalide ou expiré.',
        code: 'INVALID_TOKEN'
      });
    }

    // 3️⃣ Extraire les données du token
    const {
      sub: keycloak_id,
      email,
      given_name: prenom,
      family_name: nom,
      realm_access: realmAccess = {}
    } = decoded;

    if (!keycloak_id) {
      return res.status(401).json({
        success: false,
        message: 'Token mal formé (sub manquant).',
        code: 'INVALID_TOKEN_STRUCTURE'
      });
    }

    // 4️⃣ Récupérer ou créer l'utilisateur (auto-provisioning)
    let user = await prisma.utilisateur.findUnique({
      where: { keycloak_id },
      include: {
        utilisateur_role: { where: { actif: true } }
      }
    });

    if (!user) {
      console.log(`✅ Auto-provisioning user: ${keycloak_id} (${email})`);

      // Créer l'utilisateur avec un numero_telephone temporaire
      // (sera complété lors du premier login complet)
      const tempPhone = `temp-${keycloak_id.substring(0, 8)}`;

      user = await prisma.utilisateur.create({
        data: {
          keycloak_id,
          email: email || null,
          prenom: prenom || '',
          nom: nom || '',
          numero_telephone: tempPhone,
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

      console.log(`  ✅ User créé: ${user.id_utilisateur}`);
    }

    // 5️⃣ Extraire les rôles du token Keycloak
    const kcRoles = realmAccess.roles || [];
    const validAppRoles = [
      'ndjigi-admin',
      'ndjigi-gestionnaire',
      'ndjigi-chauffeur',
      'ndjigi-passager',
      'ndjigi-proprietaire'
    ];

    // Filtrer uniquement les rôles valides
    const userRoles = kcRoles.filter((r) => validAppRoles.includes(r));

    // 6️⃣ Attacher l'utilisateur à la requête
    req.user = {
      id_utilisateur: user.id_utilisateur,
      keycloak_id: user.keycloak_id,
      email: user.email,
      nom: user.nom,
      prenom: user.prenom,
      numero_telephone: user.numero_telephone,
      photo_profil: user.photo_profil,
      roles: userRoles.length > 0 ? userRoles : ['ndjigi-passager'],
      auth_provider: 'keycloak',
      utilisateur_role: user.utilisateur_role,
      token: token // Garder le token pour les appels Admin API en Phase 2+
    };

    next();
  } catch (err) {
    console.error('❌ keycloakAuth error:', err);
    res.status(500).json({
      success: false,
      message: 'Erreur d\'authentification serveur.',
      code: 'AUTH_ERROR'
    });
  }
};

module.exports = { keycloakAuth };
