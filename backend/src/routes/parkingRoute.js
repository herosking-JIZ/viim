const express                                                    = require('express');
const { ParkingController, GestionnaireController, IncidentController } = require('../controllers/parkingController');
const { authenticate }                                           = require('../middlewares/authenticate');
const { authorize, can }                                         = require('../middlewares/authorize');

const parkingRoute = express.Router();
parkingRoute.use(authenticate);

parkingRoute.get  ('/',                           can('parking:lire'),     ParkingController.lister);
parkingRoute.get  ('/mouvements',                 can('parking:lire'),     ParkingController.mouvements);
parkingRoute.get  ('/:id',                        can('parking:lire'),     ParkingController.findOne);
parkingRoute.post ('/',                           authorize('admin'),       ParkingController.creer);
parkingRoute.patch('/:id',                        authorize('admin'),       ParkingController.modifier);
parkingRoute.put  ('/:id',                        authorize('admin'),       ParkingController.modifier);
parkingRoute.post ('/:id/mouvement',              can('parking:gerer'),    ParkingController.ajouterMouvement);
parkingRoute.post ('/gestionnaires',              authorize('admin'),       GestionnaireController.assigner);
parkingRoute.get  ('/:id_parking/gestionnaires',  authorize('admin'),       GestionnaireController.parParking);
parkingRoute.get  ('/incidents',                  authorize('admin'),       IncidentController.lister);
parkingRoute.get  ('/incidents/:id',              can('incident:lire'),    IncidentController.findOne);
parkingRoute.post ('/incidents',                  can('incident:declarer'), IncidentController.declarer);

module.exports = parkingRoute;
