const express = require('express')
const { authorize, can} = require('../middlewares/authorize');
const {authenticate} = require('../middlewares/authenticate');
const supportController = require('../controllers/supportController')
const joiValidate = require('../middlewares/validate.middleware');
const {
    createTicketSchema,
    updateStatutSchema,
    getOneTicketSchema,
} = require('../validators/supportValidation');

const router = express.Router()
router.use(authenticate)

router.post('/', supportController.create);

// ── Agent / Admin uniquement ──────────────────────────────────
router.get(  '/',                can('support:lire_ticket'), supportController.list)
router.get(  '/:id',             can('support:lire_ticket'), joiValidate({query : getOneTicketSchema}), supportController.getOne)
router.patch('/:id/statut',      can('support:mise_a_jour_statut'), joiValidate({query : updateStatutSchema}), supportController.updateStatut)
module.exports = router ;