const Joi = require('joi')

// Création d'un gestionnaire par l'admin
const createGestionnaireSchema = Joi.object({
  nom: Joi.string().min(2).max(100).required(),
  prenom: Joi.string().min(2).max(100).required(),
  email: Joi.string().email().required(),
  numero_telephone: Joi.string().min(8).max(20).required(),
  adresse: Joi.string().allow('', null).optional(),
  id_parking: Joi.string().uuid().required(),
})

// Activation première connexion (définir le mot de passe)
const firstConnectionSchema = Joi.object({
  token: Joi.string().uuid().required(),
  email: Joi.string().email().required(),
  nouveau_mot_de_passe: Joi.string()
    .min(12)
    .required()
    .pattern(/[A-Z]/).messages({ 'string.pattern.base': 'Min 1 majuscule' })
    .pattern(/[a-z]/).messages({ 'string.pattern.base': 'Min 1 minuscule' })
    .pattern(/[0-9]/).messages({ 'string.pattern.base': 'Min 1 chiffre' })
    .pattern(/[!@#$%^&*]/).messages({ 'string.pattern.base': 'Min 1 caractère spécial (!@#$%^&*)' }),
  accepte_conditions: Joi.boolean().valid(true).required(),
})

// Upload document pour gestionnaire
const documentUploadSchema = Joi.object({
  type: Joi.string().valid('cnib', 'casier_judiciaire', 'photo_identite').required(),
})

// Renvoi invitation
const resendInvitationSchema = Joi.object({
  id_utilisateur: Joi.string().uuid().required(),
})

module.exports = {
  createGestionnaireSchema,
  firstConnectionSchema,
  documentUploadSchema,
  resendInvitationSchema,
}
