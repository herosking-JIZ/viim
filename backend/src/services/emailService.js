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
