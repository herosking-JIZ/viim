/**
 * PHOTO CONTROLLER — Gestion des photos pour mouvements et maintenance
 */

const fs = require('fs').promises;
const path = require('path');
const { prisma } = require('../config/db');

const PhotoController = {
  // ── Upload photo pour mouvement ────────────────────────────
  async uploadPhotoMouvement(req, res) {
    try {
      const { mouvementId } = req.params;
      const file = req.file;

      if (!file) {
        return res.status(400).json({ success: false, message: 'Aucun fichier uploadé.' });
      }

      // Vérifier que le mouvement existe
      const mouvement = await prisma.journal_parking.findUnique({
        where: { id_log: mouvementId },
        select: { id_parking: true }
      });

      if (!mouvement) {
        // Supprimer le fichier physique
        await fs.unlink(file.path);
        return res.status(404).json({ success: false, message: 'Mouvement introuvable.' });
      }

      // Créer le fileKey
      const date = new Date().toISOString().split('T')[0];
      const fileKey = `${mouvement.id_parking}/mouvements/${date}/${file.filename}`;

      // Enregistrer en DB
      const photo = await prisma.mouvement_photo.create({
        data: {
          id_mouvement: mouvementId,
          filename: file.originalname,
          fileKey,
          filepath: file.path,
          mimeType: file.mimetype,
          fileSize: BigInt(file.size)
        }
      });

      return res.status(201).json({
        success: true,
        message: 'Photo uploadée.',
        data: {
          id_photo: photo.id_photo,
          fileKey: photo.fileKey,
          url: `/api/v1/photos/${photo.id_photo}`
        }
      });
    } catch (error) {
      console.error('[photo.uploadPhotoMouvement]', error);
      if (req.file) {
        await fs.unlink(req.file.path).catch(() => {});
      }
      return res.status(500).json({ success: false, message: 'Erreur upload.' });
    }
  },

  // ── Upload photo pour maintenance ──────────────────────────
  async uploadPhotoMaintenance(req, res) {
    try {
      const { maintenanceId } = req.params;
      const file = req.file;

      if (!file) {
        return res.status(400).json({ success: false, message: 'Aucun fichier uploadé.' });
      }

      // Vérifier que la maintenance existe
      const maintenance = await prisma.maintenance.findUnique({
        where: { id_maintenance: maintenanceId },
        select: { id_parking: true }
      });

      if (!maintenance) {
        await fs.unlink(file.path);
        return res.status(404).json({ success: false, message: 'Maintenance introuvable.' });
      }

      // Créer le fileKey
      const date = new Date().toISOString().split('T')[0];
      const fileKey = `${maintenance.id_parking}/maintenance/${date}/${file.filename}`;

      // Enregistrer en DB
      const photo = await prisma.mouvement_photo.create({
        data: {
          id_maintenance: maintenanceId,
          filename: file.originalname,
          fileKey,
          filepath: file.path,
          mimeType: file.mimetype,
          fileSize: BigInt(file.size)
        }
      });

      return res.status(201).json({
        success: true,
        message: 'Photo uploadée.',
        data: {
          id_photo: photo.id_photo,
          fileKey: photo.fileKey,
          url: `/api/v1/photos/${photo.id_photo}`
        }
      });
    } catch (error) {
      console.error('[photo.uploadPhotoMaintenance]', error);
      if (req.file) {
        await fs.unlink(req.file.path).catch(() => {});
      }
      return res.status(500).json({ success: false, message: 'Erreur upload.' });
    }
  },

  // ── Afficher/Télécharger une photo ────────────────────────
  async getPhoto(req, res) {
    try {
      const { photoId } = req.params;

      const photo = await prisma.mouvement_photo.findUnique({
        where: { id_photo: photoId }
      });

      if (!photo || !photo.filepath) {
        return res.status(404).json({ success: false, message: 'Photo introuvable.' });
      }

      // Vérifier que le fichier existe
      try {
        await fs.access(photo.filepath);
      } catch {
        return res.status(404).json({ success: false, message: 'Fichier introuvable.' });
      }

      // Servir le fichier
      res.setHeader('Content-Type', photo.mimeType);
      res.setHeader('Content-Disposition', `attachment; filename="${photo.filename}"`);
      res.sendFile(photo.filepath);
    } catch (error) {
      console.error('[photo.getPhoto]', error);
      return res.status(500).json({ success: false, message: 'Erreur lecture.' });
    }
  },

  // ── Supprimer une photo ────────────────────────────────────
  async deletePhoto(req, res) {
    try {
      const { photoId } = req.params;

      const photo = await prisma.mouvement_photo.findUnique({
        where: { id_photo: photoId }
      });

      if (!photo) {
        return res.status(404).json({ success: false, message: 'Photo introuvable.' });
      }

      // Supprimer le fichier physique
      if (photo.filepath) {
        await fs.unlink(photo.filepath).catch(() => {});
      }

      // Supprimer de la DB
      await prisma.mouvement_photo.delete({
        where: { id_photo: photoId }
      });

      return res.status(200).json({
        success: true,
        message: 'Photo supprimée.'
      });
    } catch (error) {
      console.error('[photo.deletePhoto]', error);
      return res.status(500).json({ success: false, message: 'Erreur suppression.' });
    }
  }
};

module.exports = PhotoController;
