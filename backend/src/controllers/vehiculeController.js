/**
 * CONTROLLERS/VEHICULECONTROLLER.JS
 */

const { prisma } = require('../config/db');

const VehiculeController = {

  // ── Lister les véhicules ────────────────────────────────────
  async lister(req, res) {
    try {
      const { statut, categorie, page = 1, limit = 20 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);

      const where = { supprime_le: null };
      if (statut)    where.statut    = statut;
      if (categorie) where.categorie = categorie;

      const [vehicules, total] = await Promise.all([
        prisma.vehicule.findMany({
          where,
          skip,
          take: parseInt(limit),
          include: {
            proprietaire: {
              include: {
                utilisateur: {
                  select: { nom: true, prenom: true, numero_telephone: true }
                }
              }
            },
            affectation_vehicule: {
              where: { est_active: true },
              include: {
                chauffeur: {
                  include: {
                    utilisateur: { select: { nom: true, prenom: true } }
                  }
                }
              }
            }
          }
        }),
        prisma.vehicule.count({ where })
      ]);

      return res.status(200).json({
        success: true,
        data: vehicules,
        meta: { total, page: parseInt(page), limit: parseInt(limit) }
      });
    } catch (error) {
      console.error('[vehicule.lister]', error);
      return res.status(500).json({ success: false, message: 'Erreur serveur.' });
    }
  },

  // ── Récupérer un véhicule ───────────────────────────────────
  async findOne(req, res) {
    try {
      const { id } = req.params;

      const vehicule = await prisma.vehicule.findUnique({
        where: { id_vehicule: id },
        include: {
          proprietaire: {
            include: {
              utilisateur: {
                select: { nom: true, prenom: true, email: true, numero_telephone: true }
              }
            }
          },
          affectation_vehicule: {
            include: { chauffeur: true }
          },
          tracking_vehicule: {
            orderBy: { horodatage: 'desc' },
            take: 1
          }
        }
      });

      if (!vehicule || vehicule.supprime_le) {
        return res.status(404).json({ success: false, message: 'Véhicule introuvable.' });
      }

      return res.status(200).json({ success: true, data: vehicule });
    } catch (error) {
      console.error('[vehicule.findOne]', error);
      return res.status(500).json({ success: false, message: 'Erreur serveur.' });
    }
  },

  // ── Créer un véhicule ───────────────────────────────────────
  async creer(req, res) {
    try {
      const {
        immatriculation, marque, modele, annee,
        categorie, nb_places, couleur, climatisation, photos
      } = req.body;

      if (!immatriculation || !marque || !modele || !annee || !categorie || !nb_places) {
        return res.status(400).json({ success: false, message: 'Champs obligatoires manquants.' });
      }

      const vehicule = await prisma.vehicule.create({
        data: {
          id_proprietaire: req.user.id_utilisateur,
          immatriculation,
          marque,
          modele,
          annee: parseInt(annee),
          categorie,
          nb_places: parseInt(nb_places),
          couleur,
          climatisation: climatisation ?? false,
          photos: photos ?? null,
        }
      });

      return res.status(201).json({ success: true, data: vehicule });
    } catch (error) {
      if (error.code === 'P2002') {
        return res.status(409).json({ success: false, message: 'Immatriculation déjà enregistrée.' });
      }
      console.error('[vehicule.creer]', error);
      return res.status(500).json({ success: false, message: 'Erreur serveur.' });
    }
  },

  // ── Mettre à jour un véhicule ───────────────────────────────
  async modifier(req, res) {
    try {
      const { id } = req.params;
      const { couleur, climatisation, statut, photos, gps_actif, nb_places } = req.body;

      const vehicule = await prisma.vehicule.update({
        where: { id_vehicule: id },
        data: {
          ...(couleur      !== undefined && { couleur }),
          ...(climatisation !== undefined && { climatisation }),
          ...(statut        !== undefined && { statut }),
          ...(photos        !== undefined && { photos }),
          ...(gps_actif     !== undefined && { gps_actif }),
          ...(nb_places     !== undefined && { nb_places: parseInt(nb_places) }),
        }
      });

      return res.status(200).json({ success: true, data: vehicule });
    } catch (error) {
      console.error('[vehicule.modifier]', error);
      return res.status(500).json({ success: false, message: 'Erreur serveur.' });
    }
  },

  // ── Soft delete un véhicule ─────────────────────────────────
  async supprimer(req, res) {
    try {
      const { id } = req.params;

      await prisma.vehicule.update({
        where: { id_vehicule: id },
        data: { supprime_le: new Date(), statut: 'desactive' }
      });

      return res.status(200).json({ success: true, message: 'Véhicule retiré de la flotte.' });
    } catch (error) {
      console.error('[vehicule.supprimer]', error);
      return res.status(500).json({ success: false, message: 'Erreur serveur.' });
    }
  },

  // ── Mettre à jour la position GPS ──────────────────────────
  async updatePosition(req, res) {
    try {
      const { id } = req.params;
      const { latitude, longitude, vitesse, cap } = req.body;

      if (latitude === undefined || longitude === undefined) {
        return res.status(400).json({ success: false, message: 'Latitude et longitude requises.' });
      }

      await prisma.$transaction([
        // Mettre à jour la position actuelle sur le véhicule
        prisma.vehicule.update({
          where: { id_vehicule: id },
          data: {
            latitude_actuelle:  parseFloat(latitude),
            longitude_actuelle: parseFloat(longitude),
          }
        }),
        // Enregistrer dans l'historique de tracking
        prisma.tracking_vehicule.create({
          data: {
            id_vehicule: id,
            latitude:    parseFloat(latitude),
            longitude:   parseFloat(longitude),
            vitesse:     vitesse ? parseInt(vitesse) : null,
            cap:         cap     ? parseInt(cap)     : null,
          }
        })
      ]);

      return res.status(200).json({ success: true, message: 'Position mise à jour.' });
    } catch (error) {
      console.error('[vehicule.updatePosition]', error);
      return res.status(500).json({ success: false, message: 'Erreur serveur.' });
    }
  },

  // ── Historique tracking ─────────────────────────────────────
  async tracking(req, res) {
    try {
      const { id } = req.params;
      const { limit = 50 } = req.query;

      const historique = await prisma.tracking_vehicule.findMany({
        where: { id_vehicule: id },
        orderBy: { horodatage: 'desc' },
        take: parseInt(limit),
      });

      return res.status(200).json({ success: true, data: historique });
    } catch (error) {
      console.error('[vehicule.tracking]', error);
      return res.status(500).json({ success: false, message: 'Erreur serveur.' });
    }
  },
};

module.exports = VehiculeController;
