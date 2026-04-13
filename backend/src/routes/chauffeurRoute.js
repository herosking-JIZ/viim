const express              = require('express');
const ChauffeurController  = require('../controllers/chauffeurController');
const { authenticate }     = require('../middlewares/authenticate');
const { authorize, can }   = require('../middlewares/authorize');

const chauffeurRoute = express.Router();

chauffeurRoute.use(authenticate);

chauffeurRoute.get ('/',           can('profil:lire'),      ChauffeurController.lister);
chauffeurRoute.patch('/:id/valider', authorize('admin'),    ChauffeurController.valider);
chauffeurRoute.get ('/:id',                 can('chauffeur:lire'),       ChauffeurController.findOne);
chauffeurRoute.patch('/:id',                can('chauffeur:modifier'),   ChauffeurController.update);
chauffeurRoute.patch('/:id/suspendre',      authorize('admin'),          ChauffeurController.suspendre);
chauffeurRoute.patch('/disponibilite', can('disponibilite:modifier'), ChauffeurController.changerDisponibilite);
chauffeurRoute.get ('/:id/statistiques',    can('chauffeur:lire'),       ChauffeurController.statistiques);



module.exports =  chauffeurRoute ;