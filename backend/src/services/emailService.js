/**
 * EMAIL SERVICE
 * Handles transactional emails with HTML + TXT fallback
 * Uses nodemailer + handlebars templates
 */

const nodemailer = require('nodemailer');
const fs = require('fs');
const path = require('path');

// Handlebars implementation (simple)
function renderTemplate(templateString, data) {
  return templateString
    .replace(/{{#if\s+(\w+)}}([\s\S]*?){{\/if}}/g, (match, condition, content) => {
      return data[condition] ? content : '';
    })
    .replace(/{{{(\w+)}}}/g, (match, key) => data[key] || '')
    .replace(/{{(\w+)}}/g, (match, key) => data[key] || '');
}

// Initialize nodemailer transporter
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT || 587),
  secure: process.env.SMTP_PORT == 465,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

// Verify transporter on startup
transporter.verify((error, success) => {
  if (error) {
    console.error('⚠️ Email service error:', error.message);
  } else {
    console.log('✅ Email service ready');
  }
});

const EmailService = {
  /**
   * Send gestionnaire welcome email
   * @param {string} email - Recipient email
   * @param {Object} data - Template data
   *   - nom: string
   *   - prenom: string
   *   - email: string
   *   - tempPassword: string
   *   - parkings: Array<{nom, adresse}>
   */
  async sendGestionnaireWelcome(email, data) {
    try {
      // Load templates
      const txtPath = path.join(__dirname, 'emails/templates/gestionnaire-welcome.txt');
      const htmlPath = path.join(__dirname, 'emails/templates/gestionnaire-welcome.html');

      const txtTemplate = fs.readFileSync(txtPath, 'utf-8');
      const htmlTemplate = fs.readFileSync(htmlPath, 'utf-8');

      // Prepare data
      const templateData = {
        prenom: data.prenom,
        nom: data.nom,
        email: data.email,
        tempPassword: data.tempPassword,
        appUrl: process.env.APP_URL || 'http://localhost:3000',
        supportWhatsapp: process.env.SUPPORT_WHATSAPP || '+22606768989',
        supportWhatsappNumber: (process.env.SUPPORT_WHATSAPP || '+22606768989').replace(/\D/g, ''),
        parkingsList: data.parkings
          .map(p => `   • ${p.nom} (${p.adresse})`)
          .join('\n'),
      };

      // Render templates
      const textContent = renderTemplate(txtTemplate, templateData);
      const htmlContent = renderTemplate(htmlTemplate, templateData);

      // Send email
      const result = await transporter.sendMail({
        from: `N'DJIGI <${process.env.SMTP_USER}>`,
        to: email,
        subject: 'Bienvenue sur N\'DJIGI - Votre compte gestionnaire',
        text: textContent,
        html: htmlContent,
      });

      console.log(`✅ Gestionnaire welcome email sent to ${email}`);
      return result;
    } catch (error) {
      console.error('❌ Email send error:', error);
      throw new Error(`Failed to send email: ${error.message}`);
    }
  },

  /**
   * Send user invitation email (generic for all roles)
   * @param {string} email - Recipient email
   * @param {Object} data - Template data
   *   - nom: string
   *   - prenom: string
   *   - role: string
   *   - tempPassword: string
   *   - appUrl: string
   */
  async sendUserInvitation(email, data) {
    try {
      const appUrl = data.appUrl || process.env.APP_URL || 'http://localhost:3000';
      const roleLabels = {
        'admin': 'Administrateur',
        'gestionnaire': 'Gestionnaire de Parking',
        'passager': 'Passager',
        'chauffeur': 'Chauffeur',
        'proprietaire': 'Propriétaire'
      };

      const roleLabel = roleLabels[data.role] || data.role;
      const parkingInfo = data.parkingName ? `\n\nParking assigné: ${data.parkingName}` : '';

      const subject = `Invitation N'DJIGI - Compte ${roleLabel}`;

      const textContent = `
Bienvenue sur N'DJIGI!

Bonjour ${data.prenom} ${data.nom},

Votre compte ${roleLabel} a été créé avec succès.

Email: ${email}
Mot de passe temporaire: ${data.tempPassword}
Rôle: ${roleLabel}${parkingInfo}

Pour vous connecter:
1. Allez sur ${appUrl}/login
2. Entrez votre email et mot de passe temporaire
3. Changez votre mot de passe lors de la première connexion

Support: +226 67 68 98 89 (WhatsApp)

Cordialement,
L'équipe N'DJIGI
`;

      const htmlContent = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #007bff; color: white; padding: 20px; text-align: center; border-radius: 5px; }
    .content { padding: 20px; background-color: #f9f9f9; border: 1px solid #ddd; border-radius: 5px; margin-top: 20px; }
    .credentials { background-color: #fff3cd; padding: 15px; border-radius: 5px; margin: 15px 0; font-family: monospace; }
    .footer { text-align: center; margin-top: 20px; font-size: 12px; color: #666; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Bienvenue sur N'DJIGI!</h1>
    </div>
    <div class="content">
      <p>Bonjour <strong>${data.prenom} ${data.nom}</strong>,</p>
      <p>Votre compte <strong>${roleLabel}</strong> a été créé avec succès.</p>

      <div class="credentials">
        <p><strong>Email:</strong> ${email}</p>
        <p><strong>Mot de passe temporaire:</strong> ${data.tempPassword}</p>
        <p><strong>Rôle:</strong> ${roleLabel}</p>
        ${data.parkingName ? `<p><strong>Parking:</strong> ${data.parkingName}</p>` : ''}
      </div>

      <h3>Prochaines étapes:</h3>
      <ol>
        <li>Visitez <a href="${appUrl}/login">${appUrl}/login</a></li>
        <li>Connectez-vous avec votre email et mot de passe temporaire</li>
        <li>Changez votre mot de passe lors de la première connexion</li>
      </ol>

      <p><strong>Support:</strong> +226 67 68 98 89 (WhatsApp)</p>
    </div>
    <div class="footer">
      <p>© 2026 N'DJIGI. Tous droits réservés.</p>
    </div>
  </div>
</body>
</html>
`;

      const result = await transporter.sendMail({
        from: `N'DJIGI <${process.env.SMTP_USER}>`,
        to: email,
        subject: subject,
        text: textContent,
        html: htmlContent,
      });

      console.log(`✅ User invitation email sent to ${email} (${data.role})`);
      return result;
    } catch (error) {
      console.error('❌ Invitation email send error:', error);
      throw new Error(`Failed to send invitation email: ${error.message}`);
    }
  },

  /**
   * Test email sending (dev only)
   */
  async sendTest(email) {
    try {
      const result = await transporter.sendMail({
        from: `N'DJIGI <${process.env.SMTP_USER}>`,
        to: email,
        subject: 'Test Email - N\'DJIGI',
        text: 'This is a test email from N\'DJIGI platform.',
        html: '<p>This is a test email from N\'DJIGI platform.</p>',
      });
      return result;
    } catch (error) {
      throw new Error(`Failed to send test email: ${error.message}`);
    }
  },
};

module.exports = EmailService;
