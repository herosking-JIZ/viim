/**
 * CONTROLLERS/PAIEMENTCONTROLLER.JS
 */

const { prisma } = require('../config/db');

const PaiementController = {

  // ── Lister les paiements ────────────────────────────────────
  async lister(req, res) {
    try {
      const { statut, methode, page = 1, limit = 20 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);

      const where = {};
      if (statut)  where.statut  = statut;
      if (methode) where.methode = methode;

      const [paiements, total] = await Promise.all([
        prisma.paiement.findMany({
          where,
          skip,
          take: parseInt(limit),
          orderBy: { date_paiement: 'desc' },
          include: {
            utilisateur: { select: { nom: true, prenom: true, email: true } }
          }
        }),
        prisma.paiement.count({ where })
      ]);

      return res.status(200).json({
        success: true,
        data: paiements,
        meta: { total, page: parseInt(page), limit: parseInt(limit) }
      });
    } catch (error) {
      console.error('[paiement.lister]', error);
      return res.status(500).json({ success: false, message: 'Erreur serveur.' });
    }
  },

  // ── Créer un paiement ───────────────────────────────────────
  async creer(req, res) {
    try {
      const { montant, methode, id_objet_lie, reference_transaction } = req.body;
      const id_utilisateur = req.user.id_utilisateur;

      if (!montant || !methode) {
        return res.status(400).json({ success: false, message: 'montant et methode requis.' });
      }

      const paiement = await prisma.paiement.create({
        data: {
          id_utilisateur,
          montant:               parseFloat(montant),
          methode,
          id_objet_lie:          id_objet_lie         ?? null,
          reference_transaction: reference_transaction ?? null,
          statut: 'en_attente',
        }
      });

      return res.status(201).json({ success: true, data: paiement });
    } catch (error) {
      if (error.code === 'P2002') {
        return res.status(409).json({ success: false, message: 'Référence de transaction déjà utilisée.' });
      }
      console.error('[paiement.creer]', error);
      return res.status(500).json({ success: false, message: 'Erreur serveur.' });
    }
  },

  // ── Confirmer un paiement ───────────────────────────────────
  async confirmer(req, res) {
    try {
      const { id } = req.params;
      const { reference_transaction } = req.body;

      const paiement = await prisma.paiement.findUnique({ where: { id_paiement: id } });
      if (!paiement) {
        return res.status(404).json({ success: false, message: 'Paiement introuvable.' });
      }

      const updated = await prisma.paiement.update({
        where: { id_paiement: id },
        data: {
          statut: 'confirme',
          ...(reference_transaction && { reference_transaction })
        }
      });

      return res.status(200).json({ success: true, data: updated });
    } catch (error) {
      console.error('[paiement.confirmer]', error);
      return res.status(500).json({ success: false, message: 'Erreur serveur.' });
    }
  },

  // ── Mes paiements ───────────────────────────────────────────
  async mesPaiements(req, res) {
    try {
      const id_utilisateur = req.user.id_utilisateur;
      const { page = 1, limit = 10 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);

      const paiements = await prisma.paiement.findMany({
        where: { id_utilisateur },
        skip,
        take: parseInt(limit),
        orderBy: { date_paiement: 'desc' }
      });

      return res.status(200).json({ success: true, data: paiements });
    } catch (error) {
      console.error('[paiement.mesPaiements]', error);
      return res.status(500).json({ success: false, message: 'Erreur serveur.' });
    }
  },
};

// ─────────────────────────────────────────────────────────────
// PORTEFEUILLE
// ─────────────────────────────────────────────────────────────

const PortefeuilleController = {

  // ── Mon portefeuille ────────────────────────────────────────
  async monPortefeuille(req, res) {
    try {
      const id_utilisateur = req.user.id_utilisateur;

      const portefeuille = await prisma.portefeuille.findUnique({
        where: { id_utilisateur },
      });

      if (!portefeuille) {
        return res.status(404).json({ success: false, message: 'Portefeuille introuvable.' });
      }

      return res.status(200).json({ success: true, data: portefeuille });
    } catch (error) {
      console.error('[portefeuille.monPortefeuille]', error);
      return res.status(500).json({ success: false, message: 'Erreur serveur.' });
    }
  },

  // ── Créditer un portefeuille ────────────────────────────────
  async crediter(req, res) {
    try {
      const { id } = req.params;
      const { montant, type_operation, id_objet_lie } = req.body;

      if (!montant || parseFloat(montant) <= 0) {
        return res.status(400).json({ success: false, message: 'Montant invalide.' });
      }

      const result = await prisma.$transaction(async (tx) => {
        const portefeuille = await tx.portefeuille.findUnique({
          where: { id_portefeuille: id }
        });

        if (!portefeuille) throw new Error('Portefeuille introuvable.');

        const nouveau_solde = parseFloat(portefeuille.solde) + parseFloat(montant);

        const updated = await tx.portefeuille.update({
          where: { id_portefeuille: id },
          data: { solde: nouveau_solde }
        });

        await tx.mouvement_portefeuille.create({
          data: {
            id_portefeuille: id,
            type_operation:  type_operation ?? 'credit',
            montant:         parseFloat(montant),
            sens:            'credit',
            solde_apres:     nouveau_solde,
            id_objet_lie:    id_objet_lie ?? null,
          }
        });

        return updated;
      });

      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      console.error('[portefeuille.crediter]', error);
      return res.status(500).json({ success: false, message: error.message || 'Erreur serveur.' });
    }
  },

  // ── Débiter un portefeuille ─────────────────────────────────
  async debiter(req, res) {
    try {
      const { id } = req.params;
      const { montant, type_operation, id_objet_lie } = req.body;

      if (!montant || parseFloat(montant) <= 0) {
        return res.status(400).json({ success: false, message: 'Montant invalide.' });
      }

      const result = await prisma.$transaction(async (tx) => {
        const portefeuille = await tx.portefeuille.findUnique({
          where: { id_portefeuille: id }
        });

        if (!portefeuille) throw new Error('Portefeuille introuvable.');

        if (parseFloat(portefeuille.solde) < parseFloat(montant)) {
          throw new Error('Solde insuffisant.');
        }

        const nouveau_solde = parseFloat(portefeuille.solde) - parseFloat(montant);

        const updated = await tx.portefeuille.update({
          where: { id_portefeuille: id },
          data: { solde: nouveau_solde }
        });

        await tx.mouvement_portefeuille.create({
          data: {
            id_portefeuille: id,
            type_operation:  type_operation ?? 'debit',
            montant:         parseFloat(montant),
            sens:            'debit',
            solde_apres:     nouveau_solde,
            id_objet_lie:    id_objet_lie ?? null,
          }
        });

        return updated;
      });

      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      if (error.message === 'Solde insuffisant.') {
        return res.status(400).json({ success: false, message: error.message });
      }
      console.error('[portefeuille.debiter]', error);
      return res.status(500).json({ success: false, message: 'Erreur serveur.' });
    }
  },

  // ── Historique des mouvements ───────────────────────────────
  async mouvements(req, res) {
    try {
      const id_utilisateur = req.user.id_utilisateur;
      const { page = 1, limit = 20 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);

      const portefeuille = await prisma.portefeuille.findUnique({
        where: { id_utilisateur }
      });

      if (!portefeuille) {
        return res.status(404).json({ success: false, message: 'Portefeuille introuvable.' });
      }

      const mouvements = await prisma.mouvement_portefeuille.findMany({
        where: { id_portefeuille: portefeuille.id_portefeuille },
        skip,
        take: parseInt(limit),
        orderBy: { date_operation: 'desc' }
      });

      return res.status(200).json({ success: true, data: mouvements });
    } catch (error) {
      console.error('[portefeuille.mouvements]', error);
      return res.status(500).json({ success: false, message: 'Erreur serveur.' });
    }
  },
};

module.exports = { PaiementController, PortefeuilleController };
