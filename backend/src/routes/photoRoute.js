/**
 * ROUTES/PHOTOROUT.JS
 * Photo upload, gallery, and management routes
 */

const express = require('express');
const photoController = require('../controllers/photoController');
const { uploadPhoto } = require('../middlewares/photoUpload.middleware');
const uploadRateLimiter = require('../middlewares/uploadRateLimit');
const joiValidate = require('../middlewares/validate.middleware');
const { photoUploadSchema, photoMetadataSchema } = require('../validators/photo.validator');

const router = express.Router();


// ─── Upload photo(s) ────────────────────────────────────────────
// POST /photos
// Body: ownerType, ownerId?, isPrincipale?, ordre?, legende?
// Files: photo (single) or photos (multiple)
router.post(
  '/',
  uploadRateLimiter,
  uploadPhoto.array('photos', 10), // Allow up to 10 files
  joiValidate({ body: photoUploadSchema }),
  photoController.uploadPhoto
);

// ─── Get gallery for owner ──────────────────────────────────────
// GET /photos/:ownerType/:ownerId?page=1&limit=20

router.get(
  '/:ownerType/:ownerId',
  photoController.getGallery
);

// ─── Get photo metadata ─────────────────────────────────────────
// GET /photos/:photoId/metadata
router.get(
  '/:photoId/metadata',
  photoController.getPhotoMetadata
);

// ─── Serve photo file ──────────────────────────────────────────
// GET /photos/:photoId/file?inline=true
router.get(
  '/:photoId/file',
  photoController.servePhoto
);

// ─── Update photo metadata ─────────────────────────────────────
// PATCH /photos/:photoId
// Body: { legende?, ordre?, is_principale? }
router.patch(
  '/:photoId',
  joiValidate({ body: photoMetadataSchema }),
  photoController.updatePhotoMetadata
);

// ─── Soft delete photo ──────────────────────────────────────────
// DELETE /photos/:photoId
router.delete(
  '/:photoId',
  photoController.deletePhoto
);

// ─── Hard delete photo (permanent) ──────────────────────────────
// DELETE /photos/:photoId/permanent
router.delete(
  '/:photoId/permanent',
  photoController.deletePhotoPermanent
);

module.exports = router;
