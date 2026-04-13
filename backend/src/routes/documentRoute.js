const express = require('express');
const documentController = require('../controllers/documentController');
const { authenticate } = require('../middlewares/authenticate');
const { can, authorize } = require('../middlewares/authorize');

const router = express.Router();

router.use(authenticate);

router.get('/', authorize('admin'), documentController.list)
router.patch('/:id/valider', authorize('admin'), documentController.valider)
router.patch('/:id/rejeter', authorize('admin'), documentController.rejeter)
router.post('/', can('profil:modifier'), documentController.uploadDocument)
router.get('/me', can('profil:lire'), documentController.mesDocuments)

module.exports = router;
