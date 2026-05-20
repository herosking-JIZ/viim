const { prisma } = require('../config/db')
const bcrypt = require('bcrypt')
const EmailService = require('./emailService')
const { generateInitialPassword } = require('../utils/passwordGenerator')
const KcAdminClient = require('@keycloak/keycloak-admin-client').default

const GestionnaireService = {
  /**
   * Create a gestionnaire account with temporary password
   * @param {Object} data - { nom, prenom, email, numero_telephone, adresse?, id_parking }
   * @param {String} adminId - UUID of admin creating this gestionnaire
   * @returns {Promise<Object>} Created gestionnaire data (tempPassword included for email only)
   */
  async create(data, adminId) {
    // Validate parking exists
    const parking = await prisma.parking.findUnique({
      where: { id_parking: data.id_parking }
    })

    if (!parking) {
      throw { code: 'PARKING_NOT_FOUND', statusCode: 400 }
    }

    // Check email doesn't exist
    const existingEmail = await prisma.utilisateur.findUnique({
      where: { email: data.email }
    })
    if (existingEmail) {
      throw { code: 'EMAIL_DUPLICATE', statusCode: 409 }
    }

    // Check phone doesn't exist
    const existingPhone = await prisma.utilisateur.findUnique({
      where: { numero_telephone: data.numero_telephone }
    })
    if (existingPhone) {
      throw { code: 'PHONE_DUPLICATE', statusCode: 409 }
    }

    // Generate unique temporary password
    const tempPassword = generateInitialPassword()
    const hashedPassword = await bcrypt.hash(tempPassword, 10)

    // Create user in transaction
    const gestionnaire = await prisma.$transaction(async (tx) => {
      const user = await tx.utilisateur.create({
        data: {
          nom: data.nom,
          prenom: data.prenom,
          email: data.email,
          numero_telephone: data.numero_telephone,
          adresse: data.adresse || null,
          mot_de_passe_hash: hashedPassword,
          mot_de_passe_temporaire: true,
          statut_compte: 'actif',
          auth_provider: 'email',
          created_by: adminId,
          utilisateur_role: {
            create: {
              role: 'gestionnaire',
              actif: true
            }
          }
        },
        include: {
          utilisateur_role: true
        }
      })

      // Link to parking
      await tx.gestionnaire_parking.create({
        data: {
          id_gestionnaire: user.id_utilisateur,
          id_parking: data.id_parking,
          date_prise_poste: new Date()
        }
      })

      return user
    })

    // Create user in Keycloak
    let keycloak_id = null
    try {
      const kcAdminClient = new KcAdminClient({
        baseUrl: process.env.KEYCLOAK_URL,
        realmName: process.env.KEYCLOAK_REALM
      })

      await kcAdminClient.auth({
        clientId: process.env.KEYCLOAK_CLIENT_ID,
        clientSecret: process.env.KEYCLOAK_CLIENT_SECRET,
        grant_type: 'client_credentials'
      })

      const keycloakUser = await kcAdminClient.users.create({
        realm: process.env.KEYCLOAK_REALM,
        username: gestionnaire.email,
        email: gestionnaire.email,
        firstName: gestionnaire.prenom,
        lastName: gestionnaire.nom,
        enabled: true,
        credentials: [
          {
            type: 'password',
            value: tempPassword,
            temporary: true
          }
        ]
      })

      keycloak_id = keycloakUser.id

      // Assign ndjigi-gestionnaire role
      const role = await kcAdminClient.roles.findOneByName({
        realm: process.env.KEYCLOAK_REALM,
        name: 'ndjigi-gestionnaire'
      })

      if (role) {
        await kcAdminClient.users.addRealmRoleMappings({
          realm: process.env.KEYCLOAK_REALM,
          id: keycloak_id,
          roles: [role]
        })
      }

      // Update gestionnaire with keycloak_id
      await prisma.utilisateur.update({
        where: { id_utilisateur: gestionnaire.id_utilisateur },
        data: { keycloak_id, auth_provider: 'keycloak' }
      })

      console.log(`✅ [KEYCLOAK_CREATED] gestionnaire=${gestionnaire.id_utilisateur} keycloak_id=${keycloak_id}`)
    } catch (keycloakErr) {
      console.error('❌ Keycloak creation failed:', keycloakErr.message)
      // Delete from PostgreSQL to avoid orphaned user
      try {
        await prisma.utilisateur.delete({
          where: { id_utilisateur: gestionnaire.id_utilisateur }
        })
        await prisma.gestionnaire_parking.deleteMany({
          where: { id_gestionnaire: gestionnaire.id_utilisateur }
        })
      } catch (cleanupErr) {
        console.error('❌ Cleanup failed:', cleanupErr.message)
      }
      throw keycloakErr
    }

    // Send welcome email with temporary password
    try {
      await EmailService.sendGestionnaireInvitation(
        gestionnaire.email,
        {
          prenom: gestionnaire.prenom,
          nom: gestionnaire.nom,
          email: gestionnaire.email,
          parking_nom: parking.nom,
          tempPassword: tempPassword
        }
      )
    } catch (emailErr) {
      console.error('❌ Email send failed but user created:', emailErr.message)
      // Continue - email failure doesn't block user creation
    }

    console.log(`✅ [GESTIONNAIRE_CREATED] admin=${adminId} gestionnaire=${gestionnaire.id_utilisateur} parking=${data.id_parking}`)

    return {
      id_utilisateur: gestionnaire.id_utilisateur,
      email: gestionnaire.email,
      parking: {
        id_parking: parking.id_parking,
        nom: parking.nom
      }
    }
  },

}

module.exports = GestionnaireService
