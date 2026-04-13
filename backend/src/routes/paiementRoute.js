const express                                    = require('express');
const { PaiementController, PortefeuilleController } = require('../controllers/paiementController');
const { authenticate }                           = require('../middlewares/authenticate');
const { authorize, can }                         = require('../middlewares/authorize');

const paiementRoute = express.Router();
paiementRoute.use(authenticate);

paiementRoute.get  ('/',                              authorize('admin'),        PaiementController.lister);
paiementRoute.get  ('/mes-paiements',                 can('paiement:lire'),      PaiementController.mesPaiements);
paiementRoute.post ('/',                              can('paiement:creer'),     PaiementController.creer);
paiementRoute.patch('/:id/confirmer',                 authorize('admin'),        PaiementController.confirmer);
paiementRoute.get  ('/portefeuille',                  can('portefeuille:lire'),  PortefeuilleController.monPortefeuille);
paiementRoute.get  ('/portefeuille/mouvements',       can('portefeuille:lire'),  PortefeuilleController.mouvements);
paiementRoute.patch('/portefeuille/:id/crediter',     authorize('admin'),        PortefeuilleController.crediter);
paiementRoute.patch('/portefeuille/:id/debiter',      authorize('admin'),        PortefeuilleController.debiter);

module.exports = paiementRoute;
