const Joi = require('joi')

const listTicketsSchema = Joi.object({
  page:   Joi.number().integer().min(1).default(1),
  limit:  Joi.number().integer().min(1).max(100).default(20),
  search: Joi.string().allow('').optional(),
  statut: Joi.string().valid('ouvert', 'en_cours', 'resolu', 'ferme').allow('').optional(),
})

const updateStatutSchema = Joi.object({
  statut: Joi.string().valid('ouvert', 'en_cours', 'resolu', 'ferme').required()
    .messages({ 'any.only': 'Statut invalide. Valeurs acceptées : ouvert, en_cours, resolu, ferme' }),
})

const createTicketSchema = Joi.object({
  sujet:       Joi.string().min(5).max(255).required()
    .messages({ 'string.min': 'Le sujet doit faire au moins 5 caractères' }),
  description: Joi.string().min(10).required()
    .messages({ 'string.min': 'La description doit faire au moins 10 caractères' }),
  priorite:    Joi.string().valid('faible', 'normale', 'haute', 'urgente').default('normale'),
  id_trajet:   Joi.string().uuid().optional().allow(null),
  id_paiement: Joi.string().uuid().optional().allow(null),
})

const remboursementSchema = Joi.object({
  id_utilisateur: Joi.string().uuid().required(),
  montant:        Joi.number().positive().required()
    .messages({ 'number.positive': 'Le montant doit être supérieur à 0' }),
  motif:          Joi.string().min(3).required(),
  id_ticket:      Joi.string().uuid().required(),
})

module.exports = {
  listTicketsSchema,
  updateStatutSchema,
  createTicketSchema,
  remboursementSchema,
}