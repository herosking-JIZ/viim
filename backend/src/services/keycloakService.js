/**
 * SERVICE/KEYCLOAKSERVICE.JS
 * Encapsule les appels au Keycloak token endpoint
 *
 * Utilisé par keycloakAuthController pour:
 *  - login(email, password)
 *  - refresh(refresh_token)
 *  - logout(refresh_token)
 */

const axios = require('axios');
const { KEYCLOAK_URL, KEYCLOAK_REALM, KEYCLOAK_CLIENT_ID } = require('../config/keycloak');
const KEYCLOAK_CLIENT_SECRET = process.env.KEYCLOAK_CLIENT_SECRET || '';

const keycloakClient = axios.create({
  baseURL: `${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect`,
  timeout: 5000,
  headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
});

/**
 * Login via Keycloak Direct Access Grant (Resource Owner Password)
 * @param {string} email
 * @param {string} password
 * @returns {object} { access_token, refresh_token, expires_in, token_type }
 */
async function login(email, password) {
  try {
    const response = await keycloakClient.post('/token', {
      grant_type: 'password',
      client_id: KEYCLOAK_CLIENT_ID,
      client_secret: KEYCLOAK_CLIENT_SECRET,
      username: email,
      password: password,
      scope: 'openid profile email'
    });

    return response.data;
  } catch (error) {
    const errorData = error.response?.data || {};
    const message = errorData.error_description || error.message;

    console.error(`❌ Keycloak login failed: ${message}`);

    throw new Error(`Login failed: ${message}`);
  }
}

/**
 * Refresh access token
 * @param {string} refresh_token
 * @returns {object} { access_token, refresh_token, expires_in, token_type }
 */
async function refresh(refresh_token) {
  try {
    const response = await keycloakClient.post('/token', {
      grant_type: 'refresh_token',
      client_id: KEYCLOAK_CLIENT_ID,
      client_secret: KEYCLOAK_CLIENT_SECRET,
      refresh_token: refresh_token,
      scope: 'openid profile email'
    });

    return response.data;
  } catch (error) {
    const errorData = error.response?.data || {};
    const message = errorData.error_description || error.message;

    console.error(`❌ Keycloak refresh failed: ${message}`);

    throw new Error(`Refresh failed: ${message}`);
  }
}

/**
 * Logout: invalide la session Keycloak
 * @param {string} refresh_token
 */
async function logout(refresh_token) {
  try {
    await keycloakClient.post('/logout', {
      client_id: KEYCLOAK_CLIENT_ID,
      client_secret: KEYCLOAK_CLIENT_SECRET,
      refresh_token: refresh_token
    });

    return { success: true };
  } catch (error) {
    // Logout peut échouer silencieusement en dev (token déjà expiré, etc.)
    console.warn(`⚠️  Keycloak logout warning: ${error.message}`);
    return { success: true };
  }
}

module.exports = {
  login,
  refresh,
  logout
};
