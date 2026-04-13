const {prisma }= require('../config/db');

const dashboardController = {
    
    // GET /api/v1/dashboard/kpis
    async getKpis(req, res) {
        try {
            const startOfDay = new Date();
            startOfDay.setHours(0, 0, 0, 0);

            const [totalUsers,coursesToday] = await Promise.all([
                prisma.utilisateur.count({ where: { supprime_le: null } }),
                prisma.trajet.count({
                    where: {
                        date_heure_debut: { gte: startOfDay }
                    }
                }),
            ]);

            return res.status(200).json({
                success: true,
                message : " doonnes envi-]] ",
                data: {
                    total_utilisateurs: totalUsers,
                    courses_aujourd_hui: coursesToday,
                    revenus_commission_jour: 500000,
                    satisfaction_moyenne: 4.5, // à calculer plus tard
                    tendance_utilisateurs: 12, // idem
                    tendance_courses: 8        // idem
                },
                errors : null

            });
        } catch (err) {
            return res.status(500).json({
                success: false,
                message: err.message,
                data : null,
                errors : null
            });
        }
    },

    // GET /api/v1/dashboard/top-chauffeurs
  async getTopChauffeurs(req, res) {
    try {
        // Requête SQL pour récupérer les 5 meilleurs chauffeurs selon note_chauffeur,
        // avec leur chiffre d'affaires total (somme des tarifs des trajets terminés)
        const result = await prisma.$queryRaw`
            SELECT
                u.nom,
                u.prenom,
                c.note_chauffeur AS note,
                COALESCE(SUM(t.tarif_final), 0) AS chiffre_affaires
            FROM "chauffeur" c
            INNER JOIN "utilisateur" u ON c.id_chauffeur = u.id_utilisateur
            LEFT JOIN "affectation_vehicule" av ON av.id_chauffeur = c.id_chauffeur
            LEFT JOIN "trajet" t ON t.id_affectation = av.id_affectation
                AND t.statut = 'termine'
                AND t.date_heure_fin IS NOT NULL
            WHERE u.supprime_le IS NULL
            GROUP BY c.id_chauffeur, u.nom, u.prenom, c.note_chauffeur
            ORDER BY c.note_chauffeur DESC NULLS LAST, chiffre_affaires DESC
            LIMIT 5
        `;

        // Formatage des données avec rang et nom complet
        const topChauffeurs = result.map((row, index) => ({
            rang: index + 1,
            nom: `${row.prenom} ${row.nom}`,
            chiffre_affaires: Number(row.chiffre_affaires)
        }));

        return res.status(200).json({
            success: true,
            message: "Top 5 des chauffeurs par note moyenne",
            data: topChauffeurs,
            errors: null
        });
    } catch (err) {
        console.error("Erreur getTopChauffeurs:", err);
        return res.status(500).json({
            success: false,
            message: "Erreur lors de la récupération du classement des chauffeurs",
            errors: err.message,
            data: null
        });
    }
    },

    // GET /api/v1/dashboard/courses-semaine
    async getWeeklyStats(req, res) {
        try {
            // 1. Définir la plage de la semaine en cours (du lundi 00:00:00 au dimanche 23:59:59)
            const now = new Date();
            const dayOfWeek = now.getDay(); // 0 = dimanche, 1 = lundi, ..., 6 = samedi
            // Ajustement pour que lundi soit le premier jour (si lundi = 1, dimanche = 0 devient 7)
            const mondayOffset = dayOfWeek === 0 ? 6 : dayOfWeek - 1;

            const startOfWeek = new Date(now);
            startOfWeek.setDate(now.getDate() - mondayOffset);
            startOfWeek.setHours(0, 0, 0, 0);

            const endOfWeek = new Date(startOfWeek);
            endOfWeek.setDate(startOfWeek.getDate() + 6);
            endOfWeek.setHours(23, 59, 59, 999);

            // 2. Requête Prisma : group by jour de la semaine sur les trajets terminés dans la semaine
            // On utilise $queryRaw pour extraire le jour de la semaine (ISO : lundi=1, dimanche=7)
            const results = await prisma.$queryRaw`
                SELECT
                    EXTRACT(ISODOW FROM "date_heure_fin") AS day_of_week,
                    COUNT(*)::int AS count
                FROM "trajet"
                WHERE "date_heure_fin" >= ${startOfWeek}
                AND "date_heure_fin" <= ${endOfWeek}
                AND "statut" = 'termine' 
                GROUP BY day_of_week
                ORDER BY day_of_week`;

            // 3. Formatage des données pour correspondre aux attentes du front
            // Mapping des jours ISO (1 = lundi, ..., 7 = dimanche) vers des labels français
            const dayLabels = {
                1: 'Lundi',
                2: 'Mardi',
                3: 'Mercredi',
                4: 'Jeudi',
                5: 'Vendredi',
                6: 'Samedi',
                7: 'Dimanche'
            };

            // Construire un tableau complet avec tous les jours de la semaine
            const weeklyData = [1, 2, 3, 4, 5, 6, 7].map(day => {
                const found = results.find(r => r.day_of_week === day);
                return {
                    day: dayLabels[day],
                    count: found ? found.count : 0
                };
            });

                // 4. Réponse standardisée
            console.log("-----------------------------------------------course hebdomadaire envoyer------------------------");

            console.log(weeklyData);
            return res.status(200).json({
                success: true,
                message: `Statistiques de la semaine du ${startOfWeek.toLocaleDateString('fr-FR')} au ${endOfWeek.toLocaleDateString('fr-FR')}`,
                data: weeklyData,
                errors: null
            });

        } catch (err) {
            console.error('Erreur getWeeklyStats:', err);
            return res.status(500).json({
                success: false,
                message: 'Erreur lors de la récupération des statistiques hebdomadaires',
                errors: err.message,
                data: null
            });
        }
},

    // GET /api/v1/dashboard/moyens-paiement
  // GET /api/v1/dashboard/moyens-paiement
async getPaymentMethodsStats(req, res) {
    try {
        const startOfDay = new Date();
        startOfDay.setHours(0, 0, 0, 0);

        const endOfDay = new Date();
        endOfDay.setHours(23, 59, 59, 999);

        // 1. Définir le dictionnaire de correspondance (facile à modifier ou étendre)
        const METHOD_LABELS = {
            'ORANGE_MONEY': 'Mobile Money',
            'WAVE':         'Mobile Money',
            'MOOV_MONEY':   'Mobile Money',
            'ESPECES':      'Espèces',
            'CARTE_VISA':   'Carte Visa',
            // Tout nouveau moyen ajouté en DB sera géré par le fallback plus bas
        };

        // 2. Agrégation Prisma
        const stats = await prisma.paiement.groupBy({
            by: ['methode'],
            where: {
                date_paiement: { gte: startOfDay, lte: endOfDay },
                statut: 'complete'
            },
            _count: { methode: true },
        });

        // 3. Transformation dynamique
        const dataMap = {};

        stats.forEach(item => {
            // On récupère le nom propre via le dictionnaire, 
            // sinon on transforme le code brute (ex: "MA_NOUVELLE_METHODE" -> "Ma Nouvelle Methode")
            const name = METHOD_LABELS[item.methode] || 
                         item.methode.toLowerCase().replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
            
            const count = item._count.methode;

            // On cumule les valeurs (utile si Orange Money et Wave pointent tous deux vers "Mobile Money")
            if (dataMap[name]) {
                dataMap[name] += count;
            } else {
                dataMap[name] = count;
            }
        });

        // 4. Conversion de l'objet en tableau pour le format final
        const formattedData = Object.keys(dataMap).map(name => ({
            name: name,
            value: dataMap[name]
        }));

        return res.status(200).json({
            success: true,
            data: formattedData,
            message: "Répartition dynamique des paiements du jour",
            errors: null
        });

    } catch (err) {
        return res.status(500).json({
            success: false,
            message: err.message,
            data: null,
            errors: null
        });
        }
    },
    // GET /api/v1/dashboard/evolution-mensuelle
async getEvolutionMensuelle(req, res) {
  try {
    // 7 derniers mois
    const mois = []
    const now = new Date()
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1)
      mois.push({
        debut: new Date(d.getFullYear(), d.getMonth(), 1),
        fin:   new Date(d.getFullYear(), d.getMonth() + 1, 0, 23, 59, 59),
        label: d.toLocaleDateString('fr-FR', { month: 'short' }),
      })
    }

    const counts = await Promise.all(
      mois.map(({ debut, fin }) =>
        prisma.trajet.count({
          where: {
            statut: 'termine',
            date_heure_debut: { gte: debut, lte: fin },
          },
        })
      )
    )

    const dataq = mois.map(({ label }, i) => ({
      label: label.charAt(0).toUpperCase() + label.slice(1, 3), // "Oct", "Nov"…
      value: counts[i],
    }))

    return res.status(200).json(
        { 
            success: true, 
            data: dataq,
            message:"evolution mensuelle",
            errors: null
        }
    )
  } catch (err) {
    return res.status(500).json(
        { 
            success: false, 
            message: err.message,
            errors : null,
            data : null
        }
    )
  }
}
};

module.exports = dashboardController;