/**
 * UTILS/JWT.JS — Utilitaires JSON Web Token
 */
const jwt = require('jsonwebtoken');
require('dotenv').config();

const JWT_SECRET          = process.env.JWT_SECRET;
const JWT_REFRESH_SECRET  = process.env.JWT_REFRESH_SECRET;
const JWT_EXPIRES_IN      = process.env.JWT_EXPIRES_IN         || '15m';
const JWT_REFRESH_EXPIRES = process.env.JWT_REFRESH_EXPIRES_IN || '7d';

/** Extrait les rôles actifs depuis la relation utilisateur_role */
function extractRoles(user) {
  if (!user.utilisateur_role) return [];
  return user.utilisateur_role
    .filter(r => r.actif)
    .map(r => r.role);
}

/** Génère un Access Token (courte durée) */
function generateAccessToken(user) {
  return jwt.sign(
    {
      sub:    user.id_utilisateur,   // ✅ clé primaire correcte
      email:  user.email,
      roles:  extractRoles(user),    // ✅ tableau de rôles ex: ["passager"]
      prenom: user.prenom,
      nom:    user.nom,
      type:   'access'
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN, issuer: 'auth-system', audience: 'auth-system-client' }
  );
}

/** Génère un Refresh Token (longue durée) */
function generateRefreshToken(user) {
  return jwt.sign(
    {
      sub:  user.id_utilisateur,    // ✅ était "id_utilisateur" sans "user." → bug corrigé
      type: 'refresh'
    },
    JWT_REFRESH_SECRET,
    { expiresIn: JWT_REFRESH_EXPIRES, issuer: 'auth-system', audience: 'auth-system-client' }
  );
}

/** Vérifie un Access Token et retourne le payload */
function verifyAccessToken(token) {
  return jwt.verify(token, JWT_SECRET, {
    issuer:   'auth-system',
    audience: 'auth-system-client'
  });
}

/** Vérifie un Refresh Token et retourne le payload */
function verifyRefreshToken(token) {
  return jwt.verify(token, JWT_REFRESH_SECRET, {
    issuer:   'auth-system',
    audience: 'auth-system-client'
  });
}

/** Calcule le timestamp d'expiration d'un refresh token */
function getRefreshTokenExpiry(duration) {
  duration = duration || JWT_REFRESH_EXPIRES;
  const units = { d: 86400000, h: 3600000, m: 60000, s: 1000 };
  const match = duration.match(/^(\d+)([dhms])$/);
  if (!match) return new Date(Date.now() + 7 * 86400000);  // ✅ retourne un Date pour Prisma
  return new Date(Date.now() + parseInt(match[1]) * units[match[2]]);
}

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
  getRefreshTokenExpiry
};