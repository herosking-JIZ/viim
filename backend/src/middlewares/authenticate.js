const { verifyAccessToken } = require('../utils/jwt');
const { prisma } = require('../config/db');

const authenticate = async (req, res, next) => {
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

    // 2. Vérifier la signature JWT
    const decoded = verifyAccessToken(token);

    if (decoded.type !== 'access') {
      return res.status(401).json({
        success: false,
        message: 'Type de token invalide.'
      });
    }

    // 3. Vérifier que l'utilisateur existe encore en base
    const user = await prisma.utilisateur.findUnique({
      where: { id_utilisateur: decoded.sub },
      include: {
        utilisateur_role: { where: { actif: true } }
      }
    });

// Ton modèle a bloque_jusqu_au DateTime?
// Un utilisateur bloqué temporairement peut quand même accéder aux routes

    if (user.bloque_jusqu_au && user.bloque_jusqu_au > new Date()) {
      return res.status(401).json({
        success: false,
        message: 'Compte temporairement bloqué.',
        bloque_jusqu_au: user.bloque_jusqu_au
    });
}

    // 4. Attacher l'utilisateur à la requête
    const { mot_de_passe_hash, reset_token, reset_token_expire, ...userSafe } = user;
    req.user = userSafe;

    next(); // ✅ passer au controller

  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Session expirée. Reconnectez-vous.',
        code: 'ACCESS_EXPIRED'
      });
    }
    return res.status(401).json({
      success: false,
      message: 'Token invalide.'
    });
  }
};

module.exports = { authenticate };