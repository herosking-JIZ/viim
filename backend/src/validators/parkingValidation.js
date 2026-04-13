const Joi = require('joi')

const receptionSchema = Joi.object({
  immatriculation: Joi.string().min(4).max(20).uppercase().required(),
  etat_vehicule:   Joi.string().valid('bon', 'a_verifier', 'dommage').required(),
  commentaire:     Joi.string().allow('', null).optional(),
})

const sortieSchema = Joi.object({
  immatriculation: Joi.string().min(4).max(20).uppercase().required(),
  etat_vehicule:   Joi.string().valid('bon', 'a_verifier', 'dommage').required(),
  commentaire:     Joi.string().allow('', null).optional(),
})

const maintenanceSchema = Joi.object({
  id_vehicule: Joi.string().uuid().required(),
  motif:       Joi.string().min(5).required()
    .messages({ 'string.min': 'Le motif doit faire au moins 5 caractères' }),
})

const updateVehiculeSchema = Joi.object({
  immatriculation: Joi.string().min(4).max(20).uppercase().required(),
  marque:          Joi.string().min(2).required(),
  modele:          Joi.string().min(1).required(),
  categorie:       Joi.string().required(),
})

const mouvementsQuerySchema = Joi.object({
  search: Joi.string().allow('').optional(),
})

module.exports = {
  receptionSchema,
  sortieSchema,
  maintenanceSchema,
  updateVehiculeSchema,
  mouvementsQuerySchema,
}