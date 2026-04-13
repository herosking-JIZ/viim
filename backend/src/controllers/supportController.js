const {
  listTicketsSchema,
  updateStatutSchema,
  createTicketSchema,
  remboursementSchema,
} = require('../validators/supportValidation')

const {prisma} = require('../config/db')

function joiErrors(error) {
  return error.details.reduce((acc, d) => {
    const key = d.path.join('.') || 'global'
    acc[key] = d.message
    return acc
  }, {})
}

const supportController = {

  // ─── GET /api/support/tickets ─────────────────────────────────
  async list(req, res) {
    const { error, value } = listTicketsSchema.validate(req.query, { abortEarly: false })
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Paramètres de filtrage invalides',
        data:    null,
        errors:  joiErrors(error),
      })
    }

    try {
      const { page, limit, search, statut } = value
      const skip = (page - 1) * limit

      const where = {
        ...(statut && statut !== '' && { statut }),
        ...(search && search !== '' && {
          OR: [
            { sujet:       { contains: search, mode: 'insensitive' } },
            { description: { contains: search, mode: 'insensitive' } },
            {
              utilisateur: {
                OR: [
                  { nom:    { contains: search, mode: 'insensitive' } },
                  { prenom: { contains: search, mode: 'insensitive' } },
                ],
              },
            },
          ],
        }),
      }

      const [tickets, total] = await prisma.$transaction([
        prisma.ticket.findMany({
          where,
          skip,
          take: limit,
          orderBy: [
            { date_creation: 'desc' },
          ],
          include: {
            utilisateur: {
              select: { nom: true, prenom: true },
            },
          },
        }),
        prisma.ticket.count({ where }),
      ])

      // Aplatir utilisateur.nom / prenom au niveau racine (format attendu par le front)
      const data = tickets.map(({ utilisateur, ...t }) => ({
        ...t,
        utilisateur_nom:    utilisateur.nom,
        utilisateur_prenom: utilisateur.prenom,
      }))

      return res.status(200).json({
        success: true,
        message: 'Liste des tickets récupérée',
        data: {
          data,
          total,
          page,
          limit,
          totalPages: Math.ceil(total / limit),
        },
        errors: null,
      })
    } catch (err) {
      console.error('[support.list]', err)
      return res.status(500).json({
        success: false,
        message: 'Erreur serveur',
        data:    null,
        errors:  null,
      })
    }
  },

  // ─── GET /api/support/tickets/:id ────────────────────────────
  async getOne(req, res) {
    try {
      const ticket = await prisma.ticket.findUnique({
        where: { id_ticket: req.params.id },
        include: {
          utilisateur: {
            select: {
              nom: true,
              prenom: true,
              email: true,
              numero_telephone: true,
            },
          },
          trajet: {
            select: {
              adresse_depart:  true,
              adresse_arrivee: true,
              statut:          true,
              tarif_final:     true,
            },
          },
          remboursement: true,
        },
      })

      if (!ticket) {
        return res.status(404).json({
          success: false,
          message: 'Ticket introuvable',
          data:    null,
          errors:  null,
        })
      }

      const { utilisateur, ...rest } = ticket
      return res.status(200).json({
        success: true,
        message: 'Ticket récupéré',
        data: {
          ...rest,
          utilisateur_nom:       utilisateur.nom,
          utilisateur_prenom:    utilisateur.prenom,
          utilisateur_email:     utilisateur.email,
          utilisateur_telephone: utilisateur.numero_telephone,
        },
        errors: null,
      })
    } catch (err) {
      console.error('[support.getOne]', err)
      return res.status(500).json({
        success: false,
        message: 'Erreur serveur',
        data:    null,
        errors:  null,
      })
    }
  },

  // ─── POST /api/support/tickets ───────────────────────────────
  async create(req, res) {
    const { error, value } = createTicketSchema.validate(req.body, { abortEarly: false })
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Données invalides',
        data:    null,
        errors:  joiErrors(error),
      })
    }

    try {
      const id_utilisateur = req.user.id_utilisateur
      const { sujet, description, priorite, id_trajet, id_paiement } = value

      // ── Calcul automatique de l'éligibilité au remboursement ──
      let eligible_remboursement = false

      if (id_trajet) {
        const trajet = await prisma.trajet.findUnique({
          where:  { id_trajet },
          select: { statut: true },
        })
        if (trajet?.statut === 'annule') {
          eligible_remboursement = true
        }
      }

      if (!eligible_remboursement && id_paiement) {
        const paiement = await prisma.paiement.findUnique({
          where:  { id_paiement },
          select: { statut: true, date_paiement: true },
        })
        if (paiement && paiement.statut === 'complete') {
          const joursEcoules = (Date.now() - new Date(paiement.date_paiement).getTime()) / 86_400_000
          if (joursEcoules <= 7) eligible_remboursement = true
        }
      }

      const ticket = await prisma.ticket.create({
        data: {
          id_utilisateur,
          sujet,
          description,
          priorite,
          id_trajet:   id_trajet   ?? null,
          id_paiement: id_paiement ?? null,
          eligible_remboursement,
        },
      })

      return res.status(201).json({
        success: true,
        message: 'Ticket créé avec succès',
        data:    ticket,
        errors:  null,
      })
    } catch (err) {
      console.error('[support.create]', err)
      return res.status(500).json({
        success: false,
        message: 'Erreur serveur',
        data:    null,
        errors:  null,
      })
    }
  },

  // ─── PATCH /api/support/tickets/:id/statut ───────────────────
  async updateStatut(req, res) {
    const { error, value } = updateStatutSchema.validate(req.body, { abortEarly: false })
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Statut invalide',
        data:    null,
        errors:  joiErrors(error),
      })
    }

    try {
      const { statut } = value

      // Vérifier que le ticket existe
      const exists = await prisma.ticket.findUnique({
        where:  { id_ticket: req.params.id },
        select: { id_ticket: true },
      })
      if (!exists) {
        return res.status(404).json({
          success: false,
          message: 'Ticket introuvable',
          data:    null,
          errors:  null,
        })
      }

      const ticket = await prisma.ticket.update({
        where: { id_ticket: req.params.id },
        data:  {
          statut,
          // Horodater la résolution dès qu'on passe en resolu ou ferme
          ...((statut === 'resolu' || statut === 'ferme') && {
            date_resolution: new Date(),
          }),
        },
      })

      return res.status(200).json({
        success: true,
        message: 'Statut mis à jour',
        data:    ticket,
        errors:  null,
      })
    } catch (err) {
      console.error('[support.updateStatut]', err)
      return res.status(500).json({
        success: false,
        message: 'Erreur serveur',
        data:    null,
        errors:  null,
      })
    }
  },

  // ─── POST /api/finances/remboursements ───────────────────────
  async rembourser(req, res) {
    const { error, value } = remboursementSchema.validate(req.body, { abortEarly: false })
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Données de remboursement invalides',
        data:    null,
        errors:  joiErrors(error),
      })
    }

    try {
      const { id_utilisateur, montant, motif, id_ticket } = value

      // ── Vérifications métier avant la transaction ──────────────

      const ticket = await prisma.ticket.findUnique({
        where:  { id_ticket },
        select: { id_ticket: true, eligible_remboursement: true, statut: true },
      })
      if (!ticket) {
        return res.status(404).json({
          success: false,
          message: 'Ticket introuvable',
          data:    null,
          errors:  null,
        })
      }
      if (!ticket.eligible_remboursement) {
        return res.status(422).json({
          success: false,
          message: 'Ce ticket n\'est pas éligible à un remboursement',
          data:    null,
          errors:  null,
        })
      }
      if (ticket.statut === 'ferme') {
        return res.status(422).json({
          success: false,
          message: 'Impossible de rembourser un ticket fermé',
          data:    null,
          errors:  null,
        })
      }

      // Idempotence : remboursement déjà en cours ou traité ?
      const dejaRembourse = await prisma.remboursement.findFirst({
        where: { id_ticket, statut: { in: ['en_attente', 'traite'] } },
      })
      if (dejaRembourse) {
        return res.status(422).json({
          success: false,
          message: 'Un remboursement est déjà en cours ou effectué pour ce ticket',
          data:    null,
          errors:  null,
        })
      }

      const portefeuille = await prisma.portefeuille.findUnique({
        where: { id_utilisateur },
      })
      if (!portefeuille) {
        return res.status(404).json({
          success: false,
          message: 'Portefeuille utilisateur introuvable',
          data:    null,
          errors:  null,
        })
      }

      // ── Transaction atomique ───────────────────────────────────
      const nouveauSolde = Number(portefeuille.solde) + montant

      const remboursement = await prisma.$transaction(async (tx) => {

        // 1. Créer le remboursement
        const rmb = await tx.remboursement.create({
          data: {
            id_ticket,
            id_utilisateur,
            montant,
            motif,
            statut:          'traite',
            id_agent:        req.user?.id_utilisateur ?? null,
            date_traitement: new Date(),
          },
        })

        // 2. Créditer le portefeuille
        await tx.portefeuille.update({
          where: { id_utilisateur },
          data:  { solde: nouveauSolde },
        })

        // 3. Enregistrer le mouvement dans l'historique
        await tx.mouvement_portefeuille.create({
          data: {
            id_portefeuille: portefeuille.id_portefeuille,
            id_objet_lie:    id_ticket,
            type_operation:  'remboursement',
            montant,
            sens:            'credit',
            solde_apres:     nouveauSolde,
          },
        })

        // 4. Passer le ticket en résolu
        await tx.ticket.update({
          where: { id_ticket },
          data:  { statut: 'resolu', date_resolution: new Date() },
        })

        // 5. Notifier l'utilisateur
        await tx.notification.create({
          data: {
            id_utilisateur,
            type:         'remboursement',
            titre:        'Remboursement effectué',
            contenu:      `Un remboursement de ${montant} FCFA a été crédité sur votre portefeuille. Motif : ${motif}`,
            id_objet_lie: rmb.id_remboursement,
          },
        })

        return rmb
      })

      return res.status(201).json({
        success: true,
        message: `Remboursement de ${montant} FCFA effectué avec succès`,
        data:    remboursement,
        errors:  null,
      })
    } catch (err) {
      console.error('[support.rembourser]', err)
      return res.status(500).json({
        success: false,
        message: 'Erreur serveur lors du remboursement',
        data:    null,
        errors:  null,
      })
    }
  },
}

module.exports = supportController ;