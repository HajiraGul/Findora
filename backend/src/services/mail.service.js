const nodemailer = require('nodemailer');

let transporter;

function getSmtpConfig() {
  const host = process.env.SMTP_HOST;
  const rawPass = process.env.SMTP_PASS;
  const pass =
    host && /gmail/i.test(host) && rawPass
      ? rawPass.replace(/\s+/g, '')
      : rawPass;

  return {
    host,
    port: Number(process.env.SMTP_PORT) || 587,
    secure: process.env.SMTP_SECURE === 'true',
    user: process.env.SMTP_USER,
    pass,
    from: process.env.SMTP_FROM || process.env.SMTP_USER,
  };
}

function isSmtpConfigured() {
  const config = getSmtpConfig();
  return Boolean(config.host && config.user && config.pass && config.from);
}

function getTransporter() {
  if (transporter) return transporter;

  const config = getSmtpConfig();
  transporter = nodemailer.createTransport({
    host: config.host,
    port: config.port,
    secure: config.secure,
    auth: {
      user: config.user,
      pass: config.pass,
    },
  });

  return transporter;
}

async function sendMail({ to, subject, text, html }) {
  if (!isSmtpConfigured()) {
    if (process.env.NODE_ENV === 'production') {
      const error = new Error('SMTP email is not configured');
      error.statusCode = 500;
      throw error;
    }

    return false;
  }

  const config = getSmtpConfig();
  await getTransporter().sendMail({
    from: config.from,
    to,
    subject,
    text,
    html,
  });

  return true;
}

function otpEmailHtml({ title, otp }) {
  return `
    <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #0f172a;">
      <h2 style="margin-bottom: 8px;">${title}</h2>
      <p>Use this verification code to continue:</p>
      <p style="font-size: 28px; font-weight: 700; letter-spacing: 6px; margin: 18px 0;">${otp}</p>
      <p>This code expires soon. If you did not request it, you can ignore this email.</p>
    </div>
  `;
}

function sendVerificationOtpEmail(email, otp) {
  return sendMail({
    to: email,
    subject: 'Findora verification code',
    text: `Your Findora verification code is ${otp}.`,
    html: otpEmailHtml({
      title: 'Verify your Findora account',
      otp,
    }),
  });
}

function sendPasswordResetOtpEmail(email, otp) {
  return sendMail({
    to: email,
    subject: 'Findora password reset code',
    text: `Your Findora password reset code is ${otp}.`,
    html: otpEmailHtml({
      title: 'Reset your Findora password',
      otp,
    }),
  });
}

module.exports = {
  sendVerificationOtpEmail,
  sendPasswordResetOtpEmail,
};
