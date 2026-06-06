/**
 * SERVICES/PROVISIONING.SERVICE.JS
 * Passager provisioning service (user + wallet + profile)
 */

class PhoneRequiredError extends Error {
  constructor(payload) {
    super('Numéro de téléphone requis.');
    this.name = 'PhoneRequiredError';
    this.code = 'PHONE_NUMBER_REQUIRED';
    this.payload = payload;
  }
}

/**
 * Provision a passenger user with wallet and profile in a single transaction
 * Uses upsert for idempotency (handles P2002 race conditions)
 *
 * @param {object} payload - Keycloak token payload
 * @param {string} payload.sub - Keycloak user ID
 * @param {string} payload.email - User email
 * @param {string} payload.given_name - First name
 * @param {string} payload.family_name - Last name
 * @param {string} [payload.numero_telephone] - Phone number
 * @param {string} [payload.phone_number] - Phone number (fallback)
 * @param {object} tx - Prisma transaction handle
 *
 * @returns {Promise<object>} Created/updated utilisateur with roles
 * @throws {PhoneRequiredError} If phone number is missing
 */
async function provisionPassagerBaseline(payload, tx) {
  const numero = payload.numero_telephone || payload.phone_number;
  if (!numero) throw new PhoneRequiredError(payload);

  // Upsert user: idempotent, absorbs race conditions (handles P2002)
  const user = await tx.utilisateur.upsert({
    where: { keycloak_id: payload.sub },
    update: {},
    create: {
      keycloak_id: payload.sub,
      email: payload.email,
      prenom: payload.given_name || '',
      nom: payload.family_name || '',
      numero_telephone: numero,
      mot_de_passe_hash: 'KEYCLOAK_AUTH',
      auth_provider: 'keycloak',
      utilisateur_role: { create: { role: 'passager', actif: true } },
    },
    include: { utilisateur_role: { where: { actif: true } } },
  });

  // Create wallet (idempotent)
  await tx.portefeuille.upsert({
    where: { id_utilisateur: user.id_utilisateur },
    update: {},
    create: {
      id_utilisateur: user.id_utilisateur,
      devise: 'XOF',
      statut: 'actif',
    },
  });

  // Create passager profile (idempotent)
  await tx.passager.upsert({
    where: { id_passager: user.id_utilisateur },
    update: {},
    create: { id_passager: user.id_utilisateur },
  });

  return user;
}

module.exports = {
  provisionPassagerBaseline,
  PhoneRequiredError,
};
