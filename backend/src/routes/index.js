const express = require('express');
const keycloakAuthRoutes = require('./keycloakAuthRoutes');
const trajetRoute = require('./trajetRoute');
const vehiculeRoute = require('./vehiculeRoute');
const parkingRoute = require('./parkingRoute');
const chauffeurRoute = require('./chauffeurRoute');
const affectationRoute = require('./affectationRoute');
const avisRoute = require('./avisRoute');
const notificationRoute = require('./notificationRoute');
const paiementRoute = require('./paiementRoute');
const passagerRoute = require('./passagerRoute');
const promoRoute = require('./promoRoute');
const proprietaireRoute = require('./proprietaireRoute');
const reservationRoute = require('./reservationRoute');
const utilisateurRoute = require('./utilisateurRoute');
const zoneTarifaireRoute = require('./zoneTarifaireRoute');
const dashboardRoute = require('./dashboardRoute');
const documentRoute = require('./documentRoute');
const supportRoutes = require('./supportRoute');
const financesRoutes = require('./financesRoute');

const zoneRoutes = require('./zoneTarifaireRoute');
const categorieRoutes = require('./categorieVehiculeRoute');
const tarifRoutes = require('./tarifCategorieZoneRoute');

const { authenticateKeycloak } = require('../middlewares/authenticateKeycloak');

console.log('Chargement des routes...');

const router = express.Router();

// ✨ Phase 4: Routes Keycloak uniquement
// Enregistrées en PREMIER pour authentification
router.use('/auth', keycloakAuthRoutes);

// Appliquer l'authentification Keycloak à toutes les autres routes
router.use(authenticateKeycloak);

router.use('/trajets', trajetRoute);
router.use('/vehicules', vehiculeRoute);
router.use('/chauffeurs', chauffeurRoute);
router.use('/affectation', affectationRoute);
router.use('/avis', avisRoute);
router.use('/notification', notificationRoute);
router.use('/paiement', paiementRoute);
router.use('/parkings', parkingRoute);
router.use('/pasager', passagerRoute);
router.use('/code-promo', promoRoute);
router.use('/proprietaire', proprietaireRoute);
router.use('/reservation', reservationRoute);
router.use('/utilisateurs', utilisateurRoute);
router.use('/vehicule', vehiculeRoute);
router.use('/zone-tarifaire', zoneTarifaireRoute);
router.use('/dashboard', dashboardRoute);
router.use('/documents', documentRoute);
router.use('/config/zones', zoneRoutes);
router.use('/config/categories', categorieRoutes);
router.use('/config/tarifs', tarifRoutes);
router.use('/support/tickets', supportRoutes);
router.use('/finances', financesRoutes);






module.exports = router;