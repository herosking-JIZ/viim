/**
 * CONFIG/KEYCLOAK.JS — Configuration Keycloak
 */

require('dotenv').config();

const keycloakConfig = {
  realm: process.env.KEYCLOAK_REALM || 'ndjigi',
  'bearer-only': true,
  'auth-server-url': process.env.KEYCLOAK_URL || 'http://localhost:8080',
  'ssl-required': process.env.NODE_ENV === 'production' ? 'all' : 'none',
  resource: process.env.KEYCLOAK_CLIENT_ID || 'ndjigi-backend',
  'public-client': false,
  credentials: {
    secret: process.env.KEYCLOAK_CLIENT_SECRET || 'your-client-secret'
  }
};

/**
 * Valide que la configuration Keycloak est présente
 */
function validateKeycloakConfig() {
  const required = [
    'KEYCLOAK_URL',
    'KEYCLOAK_REALM',
    'KEYCLOAK_CLIENT_ID',
    'KEYCLOAK_CLIENT_SECRET'
  ];

  const missing = required.filter(key => !process.env[key]);

  if (missing.length > 0) {
    console.warn(`⚠️  Variables Keycloak manquantes : ${missing.join(', ')}`);
    console.warn('Les routes protégées par Keycloak peuvent ne pas fonctionner.');
  }
}

validateKeycloakConfig();

module.exports = { keycloakConfig };
