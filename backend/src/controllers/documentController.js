const { prisma } = require('../config/db');

const documentController = {

  // GET /documents?statut=en_attente  OU  ?statut=valide,rejete
  async list(req, res) {
    try {
      const { statut } = req.query;

      // Construire le filtre statut
      const statutFilter = statut
        ? { statut_verification: { in: statut.split(',') } }
        : {};

      const documents = await prisma.document.findMany({
        where: { ...statutFilter },
        orderBy: { date_soumission: 'desc' },
        include: {
          utilisateur: {
            select: { nom: true, prenom: true }
          }
        }
      });

      // Aplatir utilisateur_nom / utilisateur_prenom comme le front l'attend
      const data = documents.map((d) => ({
        id_document:          d.id_document,
        id_utilisateur:       d.id_utilisateur,
        utilisateur_nom:      d.utilisateur.nom,
        utilisateur_prenom:   d.utilisateur.prenom,
        type:                 d.type,
        url_fichier:          d.url_fichier,
        statut_verification:  d.statut_verification,
        date_soumission:      d.date_soumission,
        date_expiration:      d.date_expiration ?? null,
        motif_rejet:          d.motif_rejet ?? null,
      }));

      return res.status(200).json({
        success: true,
        message: 'Documents récupérés.',
        data,
        errors: null,
      });
    } catch (error) {
      console.error('[document.list]', error);
      return res.status(500).json({
        success: false,
        message: 'Erreur serveur.',
        data: null,
        errors: error.message,
      });
    }
  },

  // PATCH /documents/:id/valider
  async valider(req, res) {
    try {
      const { id } = req.params;

      await prisma.document.update({
        where: { id_document: id },
        data:  { statut_verification: 'valide', motif_rejet: null },
      });

      return res.status(200).json({
        success: true,
        message: 'Document validé.',
        data: null,
        errors: null,
      });
    } catch (error) {
      if (error.code === 'P2025') {
        return res.status(404).json({
          success: false,
          message: 'Document introuvable.',
          data: null,
          errors: { code: 'DOCUMENT_NOT_FOUND' },
        });
      }
      console.error('[document.valider]', error);
      return res.status(500).json({
        success: false,
        message: 'Erreur serveur.',
        data: null,
        errors: error.message,
      });
    }
  },

  // PATCH /documents/:id/rejeter  — body: { motif: string }
  async rejeter(req, res) {
    try {
      const { id }    = req.params;
      const { motif } = req.body;

      if (!motif || !motif.trim()) {
        return res.status(400).json({
          success: false,
          message: 'Le motif de rejet est obligatoire.',
          data: null,
          errors: { field: 'motif', code: 'MISSING_MOTIF' },
        });
      }

      await prisma.document.update({
        where: { id_document: id },
        data:  { statut_verification: 'rejete', motif_rejet: motif.trim() },
      });

      return res.status(200).json({
        success: true,
        message: 'Document rejeté.',
        data: null,
        errors: null,
      });
    } catch (error) {
      if (error.code === 'P2025') {
        return res.status(404).json({
          success: false,
          message: 'Document introuvable.',
          data: null,
          errors: { code: 'DOCUMENT_NOT_FOUND' },
        });
      }
      console.error('[document.rejeter]', error);
      return res.status(500).json({
        success: false,
        message: 'Erreur serveur.',
        data: null,
        errors: error.message,
      });
    }
  },

  // POST /documents  — upload (utilisateur connecté, conservé pour la suite)
  async uploadDocument(req, res) {
    try {
      const id_utilisateur              = req.user.id_utilisateur;
      const { type, url_fichier, date_expiration } = req.body;

      const document = await prisma.document.create({
        data: {
          id_utilisateur,
          type,
          url_fichier,
          date_expiration:      date_expiration || null,
          statut_verification:  'en_attente',
        },
      });

      return res.status(201).json({
        success: true,
        message: 'Document téléversé avec succès.',
        data: document,
        errors: null,
      });
    } catch (error) {
      console.error('[document.uploadDocument]', error);
      return res.status(500).json({
        success: false,
        message: 'Erreur serveur.',
        data: null,
        errors: error.message,
      });
    }
  },

  // GET /documents/me  — mes documents (utilisateur connecté, conservé)
  async mesDocuments(req, res) {
    try {
      const id_utilisateur = req.user.id_utilisateur;

      const documents = await prisma.document.findMany({
        where:   { id_utilisateur },
        orderBy: { date_soumission: 'desc' },
      });

      return res.status(200).json({
        success: true,
        message: 'Documents récupérés.',
        data: documents,
        errors: null,
      });
    } catch (error) {
      console.error('[document.mesDocuments]', error);
      return res.status(500).json({
        success: false,
        message: 'Erreur serveur.',
        data: null,
        errors: error.message,
      });
    }
  },
};

module.exports = documentController;