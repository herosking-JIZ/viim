/**
 * CONTROLLERS/AUTHCONTROLLER.JS — Logique d'authentification N'DJIGI
 */

const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { prisma } = require('../config/db');
const { getPermissions } = require('../config/roles');
const { sendResetPasswordEmail } = require('../utils/email');

const { generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
  getRefreshTokenExpiry } = require('../utils/jwt');

// ─────────────────────────────────────────
// Helpers internes
// ─────────────────────────────────────────

function sanitizeUser(user) {
  const {
    mot_de_passe_hash,
    reset_token,
    reset_token_expire,
    ...userSafe
  } = user;
  return userSafe;
}

function extractRoles(user) {
  if (!user.utilisateur_role) return [];
  return user.utilisateur_role
    .filter(r => r.actif)
    .map(r => r.role);
}

const AuthController = {

  // ─────────────────────────────────────────
  // POST /api/auth/register
  // ─────────────────────────────────────────
  async register(req, res) {
    try {
      const { nom, prenom, email, mot_de_passe, role, numero_telephone, adresse, parking_id } = req.body;
      const password = mot_de_passe;
      console.log('------------------------------------------------je suis au register-------------------------------');

      // Vérification unicité email
      const existingUser = await prisma.utilisateur.findUnique({
        where: { email }
      });
      if (existingUser) {
        return res.status(409).json({
          success: false,
          message: 'Un compte avec cet email existe déjà.',
          data: null,
          errors: { field: 'email', code: 'DUPLICATE_EMAIL' }
        });
      }

      // Vérification unicité téléphone
      const existingPhone = await prisma.utilisateur.findUnique({
        where: { numero_telephone }
      });
      if (existingPhone) {
        return res.status(409).json({
          success: false,
          message: 'Un compte avec ce numéro de téléphone existe déjà.',
          data: null,
          errors: { field: 'numero_telephone', code: 'DUPLICATE_PHONE' }
        });
      }

      const mot_de_passe_hash = await bcrypt.hash(password, 12);

      const user = await prisma.$transaction(async (tx) => {
        const newUser = await tx.utilisateur.create({
          data: {
            nom,
            prenom,
            email,
            mot_de_passe_hash,
            numero_telephone,
            utilisateur_role: {
              create: {
                role: role || 'passager',
                actif: true
              }
            }
          },
          include: {
            utilisateur_role: { where: { actif: true } }
          }
        });
        return newUser;
      });

      const accessToken = generateAccessToken(user);
      const refreshToken = generateRefreshToken(user);

      await prisma.session.create({
        data: {
          id_utilisateur: user.id_utilisateur,
          refresh_token: refreshToken,
          date_expiration: getRefreshTokenExpiry(),
          est_valide: true
        }
      });

      return res.status(201).json({
        success: true,
        message: 'Compte créé avec succès.',
        data: {
          user: sanitizeUser(user),
          tokens: { accessToken, refreshToken }
        },
        errors: null
      });

    } catch (error) {
      console.error('[register]', error);
      return res.status(500).json({
        success: false,
        message: "Erreur serveur lors de l'inscription.",
        data: null,
        errors: error.message
      });
    }
  },

  // ─────────────────────────────────────────
  // POST /api/auth/login
  // ─────────────────────────────────────────
  async login(req, res) {
    try {
      const { email, mot_de_passe } = req.body;
      const password = mot_de_passe;

      const user = await prisma.utilisateur.findUnique({
        where: { email },
        include: { utilisateur_role: { where: { actif: true } } }
      });

      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Email ou mot de passe incorrect.',
          data: null,
          errors: { code: 'INVALID_CREDENTIALS' }
        });
      }

      if (user.statut_compte !== 'actif') {
        return res.status(403).json({
          success: false,
          message: 'Compte désactivé. Contactez l\'administrateur.',
          data: null,
          errors: { code: 'ACCOUNT_DISABLED' }
        });
      }

      if (user.bloque_jusqu_au && user.bloque_jusqu_au > new Date()) {
        const remaining = Math.ceil((new Date(user.bloque_jusqu_au) - Date.now()) / 60000);
        return res.status(423).json({
          success: false,
          message: `Compte temporairement bloqué. Réessayez dans ${remaining} minute(s).`,
          data: null,
          errors: { code: 'ACCOUNT_LOCKED', unlockAt: user.bloque_jusqu_au }
        });
      }

      const isPasswordValid = await bcrypt.compare(password, user.mot_de_passe_hash);

      if (!isPasswordValid) {
        const tentatives = user.tentatives_connexion + 1;
        const bloque_jusqu_au = tentatives >= 5 ? new Date(Date.now() + 15 * 60 * 1000) : null;

        await prisma.utilisateur.update({
          where: { id_utilisateur: user.id_utilisateur },
          data: { tentatives_connexion: tentatives, bloque_jusqu_au }
        });

        const restantes = 5 - tentatives;
        const message = restantes > 0
          ? `Email ou mot de passe incorrect. (${restantes} tentative(s) restante(s))`
          : 'Compte bloqué 15 minutes suite à trop de tentatives.';

        return res.status(401).json({
          success: false,
          message,
          data: null,
          errors: { code: 'AUTH_FAILED', attemptsRemaining: restantes }
        });
      }

      await prisma.utilisateur.update({
        where: { id_utilisateur: user.id_utilisateur },
        data: { tentatives_connexion: 0, bloque_jusqu_au: null }
      });

      const accessToken = generateAccessToken(user);
      const refreshToken = generateRefreshToken(user);

      await prisma.session.create({
        data: {
          id_utilisateur: user.id_utilisateur,
          refresh_token: refreshToken,
          date_expiration: getRefreshTokenExpiry(),
          est_valide: true
        }
      });

      const roles = extractRoles(user);

      return res.status(200).json({
        success: true,
        message: 'Connexion réussie.',
        data: {
          user: sanitizeUser(user),
          permissions: getPermissions(roles),
          tokens: { accessToken, refreshToken }
        },
        errors: null
      });

    } catch (error) {
      console.error('[login]', error);
      return res.status(500).json({
        success: false,
        message: 'Erreur serveur lors de la connexion.',
        data: null,
        errors: error.message
      });
    }
  },

  // ─────────────────────────────────────────
  // POST /api/auth/refresh
  // ─────────────────────────────────────────
  async refresh(req, res) {
    try {
      const { refreshToken } = req.body;

      if (!refreshToken) {
        return res.status(400).json({
          success: false,
          message: 'Refresh token manquant.',
          data: null,
          errors: { code: 'MISSING_TOKEN' }
        });
      }

      const session = await prisma.session.findUnique({
        where: { refresh_token: refreshToken }
      });

      if (!session || !session.est_valide) {
        return res.status(401).json({
          success: false,
          message: 'Refresh token invalide ou révoqué.',
          data: null,
          errors: { code: 'INVALID_TOKEN' }
        });
      }

      if (session.date_expiration < new Date()) {
        await prisma.session.update({
          where: { refresh_token: refreshToken },
          data: { est_valide: false }
        });
        return res.status(401).json({
          success: false,
          message: 'Refresh token expiré. Reconnectez-vous.',
          data: null,
          errors: { code: 'REFRESH_EXPIRED' }
        });
      }

      const decoded = verifyRefreshToken(refreshToken);

      if (decoded.type !== 'refresh') {
        return res.status(401).json({
          success: false,
          message: 'Type de token invalide.',
          data: null,
          errors: { code: 'WRONG_TOKEN_TYPE' }
        });
      }

      const user = await prisma.utilisateur.findUnique({
        where: { id_utilisateur: decoded.sub },
        include: { utilisateur_role: { where: { actif: true } } }
      });

      if (!user || user.statut_compte !== 'actif') {
        return res.status(401).json({
          success: false,
          message: 'Utilisateur introuvable ou inactif.',
          data: null,
          errors: { code: 'USER_INACTIVE' }
        });
      }

      await prisma.session.update({
        where: { refresh_token: refreshToken },
        data: { est_valide: false }
      });

      const newAccessToken = generateAccessToken(user);
      const newRefreshToken = generateRefreshToken(user);

      await prisma.session.create({
        data: {
          id_utilisateur: user.id_utilisateur,
          refresh_token: newRefreshToken,
          date_expiration: getRefreshTokenExpiry(),
          est_valide: true
        }
      });

      return res.status(200).json({
        success: true,
        message: 'Tokens renouvelés avec succès.',
        data: {
          tokens: {
            accessToken: newAccessToken,
            refreshToken: newRefreshToken
          }
        },
        errors: null
      });

    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        return res.status(401).json({
          success: false,
          message: 'Refresh token expiré. Reconnectez-vous.',
          data: null,
          errors: { code: 'REFRESH_EXPIRED' }
        });
      }
      return res.status(500).json({
        success: false,
        message: 'Erreur lors du renouvellement du token.',
        data: null,
        errors: error.message
      });
    }
  },

  // ─────────────────────────────────────────
  // POST /api/auth/logout
  // ─────────────────────────────────────────
  async logout(req, res) {
    try {
      const { refreshToken } = req.body;

      if (refreshToken) {
        await prisma.session.updateMany({
          where: {
            refresh_token: refreshToken,
            id_utilisateur: req.user.id_utilisateur
          },
          data: { est_valide: false }
        });
      }

      return res.status(200).json({
        success: true,
        message: 'Déconnexion réussie.',
        data: null,
        errors: null
      });

    } catch (error) {
      return res.status(500).json({
        success: false,
        message: 'Erreur lors de la déconnexion.',
        data: null,
        errors: error.message
      });
    }
  },

  // ─────────────────────────────────────────
  // POST /api/auth/logout-all
  // ─────────────────────────────────────────
  async logoutAll(req, res) {
    try {
      await prisma.session.updateMany({
        where: { id_utilisateur: req.user.id_utilisateur },
        data: { est_valide: false }
      });

      return res.status(200).json({
        success: true,
        message: 'Déconnecté de toutes les sessions.',
        data: null,
        errors: null
      });

    } catch (error) {
      return res.status(500).json({
        success: false,
        message: 'Erreur lors de la déconnexion globale.',
        data: null,
        errors: error.message
      });
    }
  },

  // ─────────────────────────────────────────
  // GET /api/auth/me
  // ─────────────────────────────────────────
  async me(req, res) {
    const roles = extractRoles(req.user);
    return res.status(200).json({
      success: true,
      message: 'Profil récupéré.',
      data: {
        user: req.user,
        permissions: getPermissions(roles)
      },
      errors: null
    });
  },

  // ─────────────────────────────────────────
  // POST /api/auth/forgot-password
  // ─────────────────────────────────────────
  async forgotPassword(req, res) {
    try {
      const { email } = req.body;

      const successResponse = () => res.status(200).json({
        success: true,
        message: 'Si cet email existe, un lien de réinitialisation a été envoyé.',
        data: null,
        errors: null
      });

      const user = await prisma.utilisateur.findUnique({
        where: { email }
      });

      if (!user || user.statut_compte !== 'actif') {
        return successResponse();
      }

      const reset_token = crypto.randomUUID();
      const reset_token_expire = new Date(Date.now() + 15 * 60 * 1000);

      await prisma.utilisateur.update({
        where: { email },
        data: { reset_token, reset_token_expire }
      });

      await sendResetPasswordEmail(email, user.prenom, reset_token);
      return successResponse();

    } catch (error) {
      return res.status(500).json({
        success: false,
        message: "Erreur serveur lors de la demande de réinitialisation.",
        data: null,
        errors: error.message
      });
    }
  },

  // ─────────────────────────────────────────
  // POST /api/auth/reset-password
  // ─────────────────────────────────────────
  async resetPassword(req, res) {
    try {
      const { token, newPassword } = req.body;

      const user = await prisma.utilisateur.findFirst({
        where: {
          reset_token: token,
          reset_token_expire: { gt: new Date() }
        }
      });

      if (!user) {
        return res.status(400).json({
          success: false,
          message: 'Lien invalide ou expiré. Faites une nouvelle demande.',
          data: null,
          errors: { code: 'INVALID_RESET_TOKEN' }
        });
      }

      const mot_de_passe_hash = await bcrypt.hash(newPassword, 12);

      await prisma.$transaction([
        prisma.utilisateur.update({
          where: { id_utilisateur: user.id_utilisateur },
          data: {
            mot_de_passe_hash,
            reset_token: null,
            reset_token_expire: null,
            tentatives_connexion: 0,
            bloque_jusqu_au: null
          }
        }),
        prisma.session.updateMany({
          where: { id_utilisateur: user.id_utilisateur },
          data: { est_valide: false }
        })
      ]);

      return res.status(200).json({
        success: true,
        message: 'Mot de passe réinitialisé avec succès. Vous pouvez vous connecter.',
        data: null,
        errors: null
      });

    } catch (error) {
      return res.status(500).json({
        success: false,
        message: 'Erreur serveur lors de la réinitialisation.',
        data: null,
        errors: error.message
      });
    }
  },



  // creation par l'admin


  async createUserByAdmin(req, res) {
    try {
      const { nom, prenom, email, mot_de_passe, role, numero_telephone, adresse, parking_id } = req.body;

      // Vérifications d'unicité
      const existingEmail = await prisma.utilisateur.findUnique({ where: { email } });
      if (existingEmail) {
        return res.status(409).json({
          success: false,
          message: 'Un compte avec cet email existe déjà.',
          errors: { field: 'email', code: 'DUPLICATE_EMAIL' }
        });
      }

      const existingPhone = await prisma.utilisateur.findUnique({ where: { numero_telephone } });
      if (existingPhone) {
        return res.status(409).json({
          success: false,
          message: 'Ce numéro de téléphone est déjà utilisé.',
          errors: { field: 'numero_telephone', code: 'DUPLICATE_PHONE' }
        });
      }

      const mot_de_passe_hash = await bcrypt.hash(mot_de_passe, 12);

      const newUser = await prisma.$transaction(async (tx) => {
        // 1. Création de l'utilisateur
        const user = await tx.utilisateur.create({
          data: {
            nom,
            prenom,
            email,
            mot_de_passe_hash,
            numero_telephone,
            adresse,
            utilisateur_role: {
              create: { role, actif: true }
            }
          }
        });

        // 2. Création des entités satellites selon le rôle
        if (role === 'passager') {
          await tx.passager.create({ data: { id_passager: user.id_utilisateur } });
        }
        if (role === 'chauffeur') {
          await tx.chauffeur.create({
            data: {
              id_chauffeur: user.id_utilisateur,
              type_service: 'vtc', // ou 'moto' selon votre besoin
              statut_validation: 'valide' // à adapter
            }
          });
        }
        if (role === 'proprietaire') {
          await tx.proprietaire.create({ data: { id_proprietaire: user.id_utilisateur } });
        }
        if (role === 'gestionnaire') {
          if (!parking_id) {
            throw new Error('Un parking doit être associé au gestionnaire.');
          }
          await tx.gestionnaire_parking.create({
            data: {
              id_gestionnaire: user.id_utilisateur,
              id_parking: parking_id
            }
          });
        }

        // 3. Création du portefeuille (tous les utilisateurs en ont un)
        await tx.portefeuille.create({
          data: { id_utilisateur: user.id_utilisateur }
        });

        return user;
      });

      // Récupération avec les relations pour le retour
      const createdUser = await prisma.utilisateur.findUnique({
        where: { id_utilisateur: newUser.id_utilisateur },
        include: {
          utilisateur_role: { where: { actif: true } },
          gestionnaire: true
        }
      });

      const formattedUser = {
        id_utilisateur: createdUser.id_utilisateur,
        nom: createdUser.nom,
        prenom: createdUser.prenom,
        email: createdUser.email,
        numero_telephone: createdUser.numero_telephone,
        adresse: createdUser.adresse,
        statut_compte: createdUser.statut_compte,
        date_inscription: createdUser.date_inscription,
        photo_profil: createdUser.photo_profil,
        note_moyenne: createdUser.note_moyenne,
        role: createdUser.utilisateur_role.map(r => r.role),
        parking_id: createdUser.gestionnaire?.id_parking || null
      };

      return res.status(201).json({
        success: true,
        message: 'Utilisateur créé avec succès.',
        data: formattedUser,
        errors: null
      });

    } catch (error) {
      console.error('[admin.createUser]', error);
      return res.status(500).json({
        success: false,
        message: error.message || 'Erreur serveur lors de la création.',
        errors: error.message
      });
    }
  }
};

module.exports = AuthController;