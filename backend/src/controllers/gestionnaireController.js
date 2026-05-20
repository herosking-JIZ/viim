const GestionnaireService = require('../services/gestionnaireService')
const { prisma } = require('../config/db')

const GestionnaireController = {
  /**
   * POST /admin/gestionnaires
   * Create a new gestionnaire with invitation email
   */
  async create(req, res) {
    try {
      const { nom, prenom, email, numero_telephone, adresse, id_parking } = req.body
      const adminId = req.user.id_utilisateur

      const result = await GestionnaireService.create(
        { nom, prenom, email, numero_telephone, adresse, id_parking },
        adminId
      )

      res.status(201).json({
        success: true,
        message: 'Gestionnaire créé. Un email d\'activation a été envoyé.',
        data: result,
        errors: null
      })
    } catch (error) {
      if (error.code === 'PARKING_NOT_FOUND') {
        return res.status(400).json({
          success: false,
          message: 'Parking introuvable.',
          data: null,
          errors: { code: 'PARKING_NOT_FOUND', id_parking: req.body.id_parking }
        })
      }
      if (error.code === 'EMAIL_DUPLICATE') {
        return res.status(409).json({
          success: false,
          message: 'Email déjà utilisé.',
          data: null,
          errors: { code: 'EMAIL_DUPLICATE', email: req.body.email }
        })
      }
      if (error.code === 'PHONE_DUPLICATE') {
        return res.status(409).json({
          success: false,
          message: 'Numéro de téléphone déjà utilisé.',
          data: null,
          errors: { code: 'PHONE_DUPLICATE', numero_telephone: req.body.numero_telephone }
        })
      }

      console.error('❌ Gestionnaire creation error:', error.message)
      res.status(500).json({
        success: false,
        message: 'Erreur serveur lors de la création.',
        data: null,
        errors: null
      })
    }
  }
}

module.exports = GestionnaireController
