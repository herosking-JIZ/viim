/**
 * CONTROLLERS/TRAJETCONTROLLER.JS
 */
const { prisma } = require('../config/db');

// ─── Includes ────────────────────────────────────────────────
const INCLUDE_TRAJET_LISTE = {
  zone_tarifaire: { select: { nom: true, vitesse_moyenne_kmh: true, coefficient_max: true } },

  affectation_vehicule: {
    include: {
      chauffeur: {
        include: {
          utilisateur: { select: { nom: true, prenom: true, photo_profil: true } }
        }
      },
      vehicule: { select: { marque: true, modele: true, immatriculation: true, couleur: true } }
    }
  },
  reservation: {
    include: {
      passager: {
        include: {
          utilisateur: { select: { nom: true, prenom: true, photo_profil: true } }
        }
      }
    }
  }
};

const INCLUDE_TRAJET_COMPLET = {
  zone_tarifaire: true,
  affectation_vehicule: {
    include: {
      chauffeur: {
        include: {
          utilisateur: { select: { nom: true, prenom: true, photo_profil: true, numero_telephone: true } }
        }
      },
      vehicule: true
    }
  },
  reservation: {
    include: {
      passager: {
        include: {
          utilisateur: { select: { nom: true, prenom: true, photo_profil: true } }
        }
      }
    }
  },
  avis: true,
  incident_securite: true,
  utilisation_promo: { include: { code_promo: true } }
};

// ─── Helper : aplatir un trajet pour le front ─────────────────
function aplatirTrajet(t) {
  // Chauffeur
  const chauffeurUser = t.affectation_vehicule?.chauffeur?.utilisateur
  const chauffeur_nom = chauffeurUser
    ? `${chauffeurUser.prenom} ${chauffeurUser.nom}`
    : '—'

  // Passager — on prend le premier passager de la première réservation non annulée
  const reservationActive = t.reservation?.find(r => r.statut !== 'annule') ?? t.reservation?.[0]
  console.log('reservation:', JSON.stringify(t.reservation?.[0], null, 2))  // 👈 ajoute ça

  const passagerUser = reservationActive?.passager?.utilisateur
  const passager_nom = passagerUser
    ? `${passagerUser.prenom} ${passagerUser.nom}`
    : '—'

  // Véhicule
  const vehicule = t.affectation_vehicule?.vehicule

  return {
    id_trajet: t.id_trajet,
    adresse_depart: t.adresse_depart,
    adresse_arrivee: t.adresse_arrivee,
    distance_km: t.distance_km,
    duree_estimee_min: t.duree_estimee_min,
    date_heure_debut: t.date_heure_debut,
    date_heure_fin: t.date_heure_fin,
    statut: t.statut,
    type_trajet: t.type_trajet,
    tarif_final: t.tarif_final,
    methode_paiement: t.methode_paiement ?? null,
    coordonnees_depart: t.coordonnees_depart,
    coordonnees_arrivee: t.coordonnees_arrivee,
    polyline_trajet: t.polyline_trajet,
    // Champs aplatis attendus par le front
    passager_nom,
    chauffeur_nom,
    chauffeur_photo: chauffeurUser?.photo_profil ?? null,
    passager_photo: passagerUser?.photo_profil ?? null,
    vehicule_info: vehicule ? `${vehicule.marque} ${vehicule.modele} — ${vehicule.immatriculation}` : '—',
    zone_nom: t.zone_tarifaire?.nom ?? null,
  }
}

const STATUTS_ANNULABLES = ['en_attente', 'confirme', 'en_cours']
const STATUTS_DEMARRABLES = ['en_attente', 'confirme']

// ─────────────────────────────────────────────────────────────
const TrajetController = {

  // ── GET /api/trajets?statut=en_cours ─────────────────────
  // Utilisé par trajetsService.enCours()
  async lister(req, res) {
    try {
      const { statut, type_trajet, page = 1, limit = 20 } = req.query
      const skip = (parseInt(page) - 1) * parseInt(limit)
      const where = {}
      if (statut) where.statut = statut
      if (type_trajet) where.type_trajet = type_trajet

      const [trajets, total] = await Promise.all([
        prisma.trajet.findMany({
          where,
          skip,
          take: parseInt(limit),
          orderBy: { date_heure_debut: 'desc' },
          include: INCLUDE_TRAJET_LISTE
        }),
        prisma.trajet.count({ where })
      ])

      const data = trajets.map(aplatirTrajet)

      return res.status(200).json({
        success: true,
        message: 'Trajets récupérés.',
        data,
        meta: { total, page: parseInt(page), limit: parseInt(limit) },
        errors: null,
      })
    } catch (error) {
      console.error('[trajet.lister]', error)
      return res.status(500).json({ success: false, message: 'Erreur serveur.', data: null, errors: error.message })
    }
  },

  // ── GET /api/trajets/historique ───────────────────────────
  // Utilisé par trajetsService.historique()
  // Recherche par nom/prénom passager, nom/prénom chauffeur, adresse
  async historique(req, res) {
    try {
      const { page = 1, limit = 20, search } = req.query
      const skip = (parseInt(page) - 1) * parseInt(limit)

      // Statuts considérés comme "historique"
      const statutsHistorique = ['termine', 'annule']

      const where = {
        statut: { in: statutsHistorique }
      }

      // Recherche sur passager (nom/prenom) et chauffeur (nom/prenom) et adresses
      if (search && search.trim()) {
        where.OR = [
          { adresse_depart: { contains: search, mode: 'insensitive' } },
          { adresse_arrivee: { contains: search, mode: 'insensitive' } },
          {
            affectation_vehicule: {
              chauffeur: {
                utilisateur: {
                  OR: [
                    { nom: { contains: search, mode: 'insensitive' } },
                    { prenom: { contains: search, mode: 'insensitive' } },
                    { email: { contains: search, mode: 'insensitive' } },
                  ]
                }
              }
            }
          },
          {
            reservation: {
              some: {
                passager: {
                  utilisateur: {
                    OR: [
                      { nom: { contains: search, mode: 'insensitive' } },
                      { prenom: { contains: search, mode: 'insensitive' } },
                      { email: { contains: search, mode: 'insensitive' } },
                    ]
                  }
                }
              }
            }
          }
        ]
      }

      const [trajets, total] = await Promise.all([
        prisma.trajet.findMany({
          where,
          skip,
          take: parseInt(limit),
          orderBy: { date_heure_debut: 'desc' },
          include: INCLUDE_TRAJET_LISTE
        }),
        prisma.trajet.count({ where })
      ])

      const data = trajets.map(aplatirTrajet)

      return res.status(200).json({
        success: true,
        message: 'Historique récupéré.',
        data: {
          data,
          total,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages: Math.ceil(total / parseInt(limit)),
        },
        errors: null,
      })
    } catch (error) {
      console.error('[trajet.historique]', error)
      return res.status(500).json({ success: false, message: 'Erreur serveur.', data: null, errors: error.message })
    }
  },

  // ── GET /api/trajets/:id ──────────────────────────────────
  async findOne(req, res) {
    try {
      const { id } = req.params
      const trajet = await prisma.trajet.findUnique({
        where: { id_trajet: id },
        include: INCLUDE_TRAJET_COMPLET
      })
      if (!trajet) {
        return res.status(404).json({ success: false, message: 'Trajet introuvable.', data: null, errors: null })
      }
      return res.status(200).json({
        success: true,
        message: 'Trajet trouvé.',
        data: aplatirTrajet(trajet),
        errors: null,
      })
    } catch (error) {
      console.error('[trajet.findOne]', error)
      return res.status(500).json({ success: false, message: 'Erreur serveur.', data: null, errors: error.message })
    }
  },

  // ── POST /api/trajets ─────────────────────────────────────
  async creer(req, res) {
    try {
      const {
        id_affectation, id_zone, adresse_depart, adresse_arrivee,
        coordonnees_depart, coordonnees_arrivee, type_trajet,
        distance_km, duree_estimee_min,
      } = req.body

      if (!id_affectation || !adresse_depart || !adresse_arrivee || !type_trajet) {
        return res.status(400).json({
          success: false,
          message: 'Champs obligatoires manquants.',
          data: null,
          errors: { code: 'MISSING_FIELDS' }
        })
      }

      // APRÈS — le tarif dépend maintenant de la zone ET de la catégorie du véhicule
      // On récupère id_categorie via l'affectation → véhicule
      let tarif_final = null
      if (id_zone && distance_km && duree_estimee_min && id_affectation) {
        const affectation = await prisma.affectation_vehicule.findUnique({
          where: { id_affectation },
          include: { vehicule: { select: { id_categorie: true } } }
        })
        const id_categorie = affectation?.vehicule?.id_categorie

        if (id_categorie) {
          const tarif = await prisma.tarif_categorie_zone.findUnique({
            where: { id_zone_id_categorie: { id_zone, id_categorie } }
          })
          const zone = await prisma.zone_tarifaire.findUnique({
            where: { id_zone },
            select: { actif: true, vitesse_moyenne_kmh: true }
          })

          if (tarif?.actif && zone?.actif) {
            tarif_final = parseFloat((
              parseFloat(tarif.tarif_base) +
              parseFloat(tarif.tarif_km) * parseFloat(distance_km) +
              parseFloat(tarif.tarif_minute) * parseInt(duree_estimee_min)
            ).toFixed(2))
          }
        }
      }

      const trajet = await prisma.trajet.create({
        data: {
          id_affectation,
          id_zone: id_zone ?? null,
          adresse_depart,
          adresse_arrivee,
          coordonnees_depart: coordonnees_depart ?? null,
          coordonnees_arrivee: coordonnees_arrivee ?? null,
          type_trajet,
          distance_km: distance_km ? parseFloat(distance_km) : null,
          duree_estimee_min: duree_estimee_min ? parseInt(duree_estimee_min) : null,
          tarif_final,
          statut: 'en_attente',
        },
        include: INCLUDE_TRAJET_COMPLET
      })

      return res.status(201).json({
        success: true,
        message: 'Trajet créé.',
        data: aplatirTrajet(trajet),
        errors: null,
      })
    } catch (error) {
      console.error('[trajet.creer]', error)
      return res.status(500).json({ success: false, message: 'Erreur serveur.', data: null, errors: error.message })
    }
  },

  // ── PATCH /api/trajets/:id/demarrer ──────────────────────
  async demarrer(req, res) {
    try {
      const { id } = req.params
      const trajet = await prisma.trajet.findUnique({ where: { id_trajet: id } })
      if (!trajet) return res.status(404).json({ success: false, message: 'Trajet introuvable.', data: null, errors: null })
      if (!STATUTS_DEMARRABLES.includes(trajet.statut)) {
        return res.status(400).json({ success: false, message: `Impossible de démarrer un trajet "${trajet.statut}".`, data: null, errors: null })
      }
      const updated = await prisma.trajet.update({
        where: { id_trajet: id },
        data: { statut: 'en_cours', date_heure_debut: new Date() }
      })
      return res.status(200).json({ success: true, message: 'Trajet démarré.', data: updated, errors: null })
    } catch (error) {
      console.error('[trajet.demarrer]', error)
      return res.status(500).json({ success: false, message: 'Erreur serveur.', data: null, errors: error.message })
    }
  },

  // ── PATCH /api/trajets/:id/terminer ──────────────────────
  async terminer(req, res) {
    try {
      const { id } = req.params
      const { tarif_final, polyline_trajet } = req.body
      const trajet = await prisma.trajet.findUnique({ where: { id_trajet: id } })
      if (!trajet) return res.status(404).json({ success: false, message: 'Trajet introuvable.', data: null, errors: null })
      if (trajet.statut !== 'en_cours') {
        return res.status(400).json({ success: false, message: `Impossible de terminer un trajet "${trajet.statut}".`, data: null, errors: null })
      }
      const updated = await prisma.$transaction(async (tx) => {
        const t = await tx.trajet.update({
          where: { id_trajet: id },
          data: {
            statut: 'termine',
            date_heure_fin: new Date(),
            tarif_final: tarif_final ? parseFloat(tarif_final) : trajet.tarif_final,
            polyline_trajet: polyline_trajet ?? trajet.polyline_trajet,
          }
        })
        const affectation = await tx.affectation_vehicule.findUnique({ where: { id_affectation: trajet.id_affectation } })
        if (affectation) {
          await tx.chauffeur.update({ where: { id_chauffeur: affectation.id_chauffeur }, data: { nb_courses_effectuees: { increment: 1 } } })
          await tx.passager.updateMany({
            where: { reservation: { some: { id_trajet: id, statut: { not: 'annule' } } } },
            data: { nb_courses_effectuees: { increment: 1 } }
          })
        }
        return t
      })
      return res.status(200).json({ success: true, message: 'Trajet terminé.', data: updated, errors: null })
    } catch (error) {
      console.error('[trajet.terminer]', error)
      return res.status(500).json({ success: false, message: 'Erreur serveur.', data: null, errors: error.message })
    }
  },

  // ── PATCH /api/trajets/:id/annuler ────────────────────────
  async annuler(req, res) {
    try {
      const { id } = req.params
      const { motif } = req.body
      const trajet = await prisma.trajet.findUnique({ where: { id_trajet: id } })
      if (!trajet) return res.status(404).json({ success: false, message: 'Trajet introuvable.', data: null, errors: null })
      if (!STATUTS_ANNULABLES.includes(trajet.statut)) {
        return res.status(400).json({ success: false, message: `Impossible d'annuler un trajet "${trajet.statut}".`, data: null, errors: null })
      }
      const updated = await prisma.$transaction(async (tx) => {
        const t = await tx.trajet.update({ where: { id_trajet: id }, data: { statut: 'annule' } })
        await tx.reservation.updateMany({ where: { id_trajet: id, statut: { not: 'annule' } }, data: { statut: 'annule' } })
        const reservations = await tx.reservation.findMany({ where: { id_trajet: id }, select: { id_passager: true } })
        if (reservations.length > 0) {
          await tx.notification.createMany({
            data: reservations.map(r => ({
              id_utilisateur: r.id_passager,
              type: 'trajet_annule',
              titre: 'Trajet annulé',
              contenu: motif ?? 'Votre trajet a été annulé.',
              id_objet_lie: id,
            }))
          })
        }
        return t
      })
      return res.status(200).json({ success: true, message: 'Trajet annulé.', data: updated, errors: null })
    } catch (error) {
      console.error('[trajet.annuler]', error)
      return res.status(500).json({ success: false, message: 'Erreur serveur.', data: null, errors: error.message })
    }
  },

  // ── POST /api/trajets/tarif ───────────────────────────────
  async calculerTarif(req, res) {
    try {
      const { id_zone, id_categorie, distance_km, duree_min, coefficient } = req.body

      if (!id_zone || !id_categorie || !distance_km || !duree_min) {
        return res.status(400).json({
          success: false,
          message: 'id_zone, id_categorie, distance_km et duree_min sont requis.',
          data: null,
          errors: null
        })
      }

      const [zone, tarif] = await Promise.all([
        prisma.zone_tarifaire.findUnique({ where: { id_zone } }),
        prisma.tarif_categorie_zone.findUnique({
          where: { id_zone_id_categorie: { id_zone, id_categorie } }
        })
      ])

      if (!zone?.actif || zone.supprime_le !== null) {
        return res.status(404).json({
          success: false,
          message: 'Zone tarifaire introuvable ou inactive.',
          data: null,
          errors: null
        })
      }

      if (!tarif?.actif) {
        return res.status(404).json({
          success: false,
          message: 'Aucun tarif configuré pour cette combinaison zone × catégorie.',
          data: null,
          errors: null
        })
      }

      const coef = Math.min(parseFloat(coefficient ?? 1), parseFloat(zone.coefficient_max))
      const tarif_ht = parseFloat(tarif.tarif_base)
        + parseFloat(tarif.tarif_km) * parseFloat(distance_km)
        + parseFloat(tarif.tarif_minute) * parseFloat(duree_min)
      const tarif_final = parseFloat((tarif_ht * coef).toFixed(2))
      const tarif_max = parseFloat((tarif_ht * parseFloat(zone.coefficient_max)).toFixed(2))

      return res.status(200).json({
        success: true,
        message: 'Tarif calculé.',
        data: {
          tarif_estime: parseFloat(tarif_ht.toFixed(2)),
          tarif_final,
          tarif_max,
          coefficient: coef,
          devise: 'XOF'
        },
        errors: null,
      })
    } catch (error) {
      console.error('[trajet.calculerTarif]', error)
      return res.status(500).json({ success: false, message: 'Erreur serveur.', data: null, errors: error.message })
    }
  },

  // ── POST /api/trajets/:id/promo ───────────────────────────
  async appliquerPromo(req, res) {
    try {
      const { id } = req.params
      const { code } = req.body
      const id_utilisateur = req.user.id_utilisateur
      if (!code) return res.status(400).json({ success: false, message: 'code requis.', data: null, errors: null })

      const trajet = await prisma.trajet.findUnique({ where: { id_trajet: id } })
      if (!trajet) return res.status(404).json({ success: false, message: 'Trajet introuvable.', data: null, errors: null })

      const promo = await prisma.code_promo.findUnique({ where: { code: code.toUpperCase() } })
      if (!promo?.actif) return res.status(404).json({ success: false, message: 'Code promo invalide.', data: null, errors: null })
      if (new Date() < new Date(promo.date_debut)) return res.status(400).json({ success: false, message: 'Code promo pas encore actif.', data: null, errors: null })
      if (promo.date_fin && new Date() > new Date(promo.date_fin)) return res.status(400).json({ success: false, message: 'Code promo expiré.', data: null, errors: null })
      if (promo.nb_utilisations_max && promo.nb_utilisations_actuel >= promo.nb_utilisations_max) return res.status(400).json({ success: false, message: 'Code promo épuisé.', data: null, errors: null })

      const dejaUtilise = await prisma.utilisation_promo.findUnique({
        where: { id_utilisateur_id_promo: { id_utilisateur, id_promo: promo.id_promo } }
      })
      if (dejaUtilise) return res.status(400).json({ success: false, message: 'Code promo déjà utilisé.', data: null, errors: null })

      await prisma.$transaction([
        prisma.utilisation_promo.create({ data: { id_utilisateur, id_promo: promo.id_promo, id_trajet: id } }),
        prisma.code_promo.update({ where: { id_promo: promo.id_promo }, data: { nb_utilisations_actuel: { increment: 1 } } })
      ])

      const reduction = trajet.tarif_final
        ? promo.type_reduction === 'pourcentage'
          ? parseFloat(trajet.tarif_final) * (parseFloat(promo.valeur) / 100)
          : Math.min(parseFloat(promo.valeur), parseFloat(trajet.tarif_final))
        : 0

      return res.status(200).json({
        success: true,
        message: 'Code promo appliqué.',
        data: { code: promo.code, type_reduction: promo.type_reduction, valeur: parseFloat(promo.valeur), reduction: parseFloat(reduction.toFixed(2)), devise: 'XOF' },
        errors: null,
      })
    } catch (error) {
      console.error('[trajet.appliquerPromo]', error)
      return res.status(500).json({ success: false, message: 'Erreur serveur.', data: null, errors: error.message })
    }
  },

  // ── PATCH /api/trajets/:id ────────────────────────────────
  async update(req, res) {
    try {
      const { id } = req.params
      const { adresse_depart, adresse_arrivee, coordonnees_depart, coordonnees_arrivee, distance_km, duree_estimee_min, polyline_trajet, id_zone, type_trajet } = req.body
      const trajet = await prisma.trajet.update({
        where: { id_trajet: id },
        data: {
          ...(adresse_depart && { adresse_depart }),
          ...(adresse_arrivee && { adresse_arrivee }),
          ...(coordonnees_depart && { coordonnees_depart }),
          ...(coordonnees_arrivee && { coordonnees_arrivee }),
          ...(distance_km && { distance_km: parseFloat(distance_km) }),
          ...(duree_estimee_min && { duree_estimee_min: parseInt(duree_estimee_min) }),
          ...(polyline_trajet && { polyline_trajet }),
          ...(id_zone && { id_zone }),
          ...(type_trajet && { type_trajet }),
        }
      })
      return res.status(200).json({ success: true, message: 'Trajet mis à jour.', data: trajet, errors: null })
    } catch (error) {
      if (error.code === 'P2025') return res.status(404).json({ success: false, message: 'Trajet introuvable.', data: null, errors: null })
      console.error('[trajet.update]', error)
      return res.status(500).json({ success: false, message: 'Erreur serveur.', data: null, errors: error.message })
    }
  },
}

module.exports = TrajetController