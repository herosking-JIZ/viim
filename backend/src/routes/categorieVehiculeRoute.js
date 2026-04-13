const express = require('express');
const router = express.Router();

const categorieVehiculeController = require('../controllers/categorieVehiculeController');
const joiValidate = require('../middlewares/validate.middleware');
const { authenticate } = require('../middlewares/authenticate');
const { authorize } = require('../middlewares/authorize');

const {
    categorieIdParamSchema,
    categorieQuerySchema,
    createCategorieSchema,
    updateCategorieSchema,
} = require('../validators/categorieVehiculeValidator');

router.use(authenticate);

router.get('/',
    authorize('admin'),
    joiValidate({ query: categorieQuerySchema }),
    categorieVehiculeController.lister
);

router.get('/:id',
    authorize('admin'),
    joiValidate({ params: categorieIdParamSchema }),
    categorieVehiculeController.findOne
);

router.post('/',
    authorize('admin'),
    joiValidate({ body: createCategorieSchema }),
    categorieVehiculeController.create
);

router.put('/:id',
    authorize('admin'),
    joiValidate({ params: categorieIdParamSchema, body: updateCategorieSchema }),
    categorieVehiculeController.modifier
);

router.delete('/:id',
    authorize('admin'),
    joiValidate({ params: categorieIdParamSchema }),
    categorieVehiculeController.supprimer
);

module.exports = router;