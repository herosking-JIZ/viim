/**
 * MIDDLEWARES/AUTHENTICATE.JS — Middleware d'authentification principal
 * Ré-exporte le middleware Keycloak pour compatibilité
 */

const { authenticateKeycloak } = require('./authenticateKeycloak');

module.exports = {
  authenticate: authenticateKeycloak
};
