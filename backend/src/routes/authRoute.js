const express        =require('express');
const rateLimit      =require('express-rate-limit');
const AuthController =require('../controllers/authController');
const { authenticate }        = require('../middlewares/authenticate');
const {
  registerRules,
  loginRules,
  forgotPasswordRules,
  resetPasswordRules
} = require('../validators/authValidator');

const { authorize, can } = require('../middlewares/authorize');


const authRoute = express.Router();

// ---- Rate limiting : protection contre le brute-force ----
// Maximum 10 tentatives de connexion par IP sur 15 minutes
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max:      10,
  message:  { success: false, message: 'Trop de tentatives. Réessayez dans 15 minutes.' },
  standardHeaders: true,
  legacyHeaders:   false
});

// Maximum 5 inscriptions par IP sur 1 heure
const registerLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max:      5,
  message:  { success: false, message: 'Trop d\'inscriptions. Réessayez dans 1 heure.' }
});

const forgotPasswordLimiter = rateLimit({
  windowMs : 60 * 60 * 1000,
  max : 5,
  message : {
    success : false,
    message : 'Trop de demande.Réessayez dans 1 heure. '
  },
  standardHeaders : true,
  legacyHeaders : false
});
// ---- Définition des routes ----

// Inscription : validation + rate limit
authRoute.post('/register', registerLimiter, registerRules, AuthController.register);

// Connexion : validation + rate limit
authRoute.post('/login', loginLimiter, loginRules, AuthController.login);

// Renouvellement de token (pas de rate limit agressif car refresh tokens sont déjà sécurisés)
authRoute.post('/refresh', AuthController.refresh);

// Déconnexion (pas besoin d'être authentifié, on révoque juste le token)
authRoute.post('/logout',authenticate, AuthController.logout);

// Déconnexion totale (requiert d'être authentifié)
authRoute.post('/logout-all',authenticate, AuthController.logoutAll);

// Profil courant (requiert authentification)
authRoute.get('/me',authenticate, AuthController.me);

authRoute.post('/forgot-password', forgotPasswordLimiter, forgotPasswordRules, AuthController.forgotPassword);   // demande de reset
authRoute.post('/reset-password', resetPasswordRules, AuthController.resetPassword);    // nouveau mot de passe

authRoute.post('/admin/users', AuthController.createUserByAdmin);



module.exports =  authRoute ;


