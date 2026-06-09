const bcrypt = require('bcryptjs');

const User = require('../models/user.model');
const {
  sendPasswordResetOtpEmail,
  sendVerificationOtpEmail,
} = require('./mail.service');
const { signToken } = require('../utils/jwt');

const otpTtlMinutes = Number(process.env.OTP_TTL_MINUTES) || 10;

function generateOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function getOtpExpiry() {
  return new Date(Date.now() + otpTtlMinutes * 60 * 1000);
}

function withDevelopmentOtp(response, otp) {
  if (process.env.NODE_ENV === 'production') return response;

  return {
    ...response,
    otp,
  };
}

async function registerUser(payload) {
  const existingUser = await User.findOne({
    $or: [{ email: payload.email }, { phone: payload.phone }],
  });

  if (existingUser) {
    const field = existingUser.email === payload.email ? 'email' : 'phone';
    const error = new Error(`An account with this ${field} already exists`);
    error.statusCode = 409;
    throw error;
  }

  const hashedPassword = await bcrypt.hash(payload.password, 12);
  const emailOtp = generateOtp();
  const emailVerificationOtpHash = await bcrypt.hash(emailOtp, 12);
  const user = await User.create({
    ...payload,
    password: hashedPassword,
    emailVerificationOtpHash,
    emailVerificationOtpExpiresAt: getOtpExpiry(),
  });
  const safeUser = user.toSafeObject();
  await sendVerificationOtpEmail(user.email, emailOtp);

  return withDevelopmentOtp({
    token: signToken(user),
    user: safeUser,
  }, emailOtp);
}

async function loginUser(payload) {
  const user = await User.findOne({ email: payload.email }).select(
    '+password +tokenVersion'
  );

  if (!user) {
    const error = new Error('Invalid email or password');
    error.statusCode = 401;
    throw error;
  }

  const passwordMatches = await bcrypt.compare(payload.password, user.password);

  if (!passwordMatches) {
    const error = new Error('Invalid email or password');
    error.statusCode = 401;
    throw error;
  }

  const safeUser = user.toSafeObject();

  return {
    token: signToken(user),
    user: safeUser,
  };
}

async function logoutUser(userId) {
  await User.findByIdAndUpdate(userId, { $inc: { tokenVersion: 1 } });
}

async function requestPasswordReset(payload) {
  const user = await User.findOne({ email: payload.email }).select(
    '+passwordResetOtpHash +passwordResetOtpExpiresAt'
  );

  if (!user) {
    return {
      message: 'If this email exists, a password reset code has been sent',
    };
  }

  const otp = generateOtp();
  user.passwordResetOtpHash = await bcrypt.hash(otp, 12);
  user.passwordResetOtpExpiresAt = getOtpExpiry();
  await user.save();
  await sendPasswordResetOtpEmail(user.email, otp);

  return withDevelopmentOtp({
    message: 'If this email exists, a password reset code has been sent',
  }, otp);
}

async function resetPassword(payload) {
  const user = await User.findOne({ email: payload.email }).select(
    '+password +passwordResetOtpHash +passwordResetOtpExpiresAt +tokenVersion'
  );

  if (!user || !user.passwordResetOtpHash || !user.passwordResetOtpExpiresAt) {
    const error = new Error('Invalid or expired reset code');
    error.statusCode = 400;
    throw error;
  }

  if (user.passwordResetOtpExpiresAt.getTime() < Date.now()) {
    const error = new Error('Invalid or expired reset code');
    error.statusCode = 400;
    throw error;
  }

  const otpMatches = await bcrypt.compare(payload.otp, user.passwordResetOtpHash);

  if (!otpMatches) {
    const error = new Error('Invalid or expired reset code');
    error.statusCode = 400;
    throw error;
  }

  user.password = await bcrypt.hash(payload.password, 12);
  user.passwordResetOtpHash = undefined;
  user.passwordResetOtpExpiresAt = undefined;
  user.tokenVersion += 1;
  await user.save();

  return {
    message: 'Password reset successfully',
  };
}

async function verifyEmailOtp(payload) {
  const user = await User.findOne({ email: payload.email }).select(
    '+emailVerificationOtpHash +emailVerificationOtpExpiresAt'
  );

  if (!user || !user.emailVerificationOtpHash || !user.emailVerificationOtpExpiresAt) {
    const error = new Error('Invalid or expired verification code');
    error.statusCode = 400;
    throw error;
  }

  if (user.emailVerificationOtpExpiresAt.getTime() < Date.now()) {
    const error = new Error('Invalid or expired verification code');
    error.statusCode = 400;
    throw error;
  }

  const otpMatches = await bcrypt.compare(
    payload.otp,
    user.emailVerificationOtpHash
  );

  if (!otpMatches) {
    const error = new Error('Invalid or expired verification code');
    error.statusCode = 400;
    throw error;
  }

  user.isEmailVerified = true;
  user.emailVerificationOtpHash = undefined;
  user.emailVerificationOtpExpiresAt = undefined;
  await user.save();

  return {
    message: 'Email verified successfully',
    user: user.toSafeObject(),
  };
}

async function resendEmailOtp(payload) {
  const user = await User.findOne({ email: payload.email }).select(
    '+emailVerificationOtpHash +emailVerificationOtpExpiresAt'
  );

  if (!user) {
    const error = new Error('Account not found');
    error.statusCode = 404;
    throw error;
  }

  if (user.isEmailVerified) {
    return {
      message: 'Email is already verified',
    };
  }

  const otp = generateOtp();
  user.emailVerificationOtpHash = await bcrypt.hash(otp, 12);
  user.emailVerificationOtpExpiresAt = getOtpExpiry();
  await user.save();
  await sendVerificationOtpEmail(user.email, otp);

  return withDevelopmentOtp({
    message: 'Verification code sent',
  }, otp);
}

module.exports = {
  registerUser,
  loginUser,
  logoutUser,
  requestPasswordReset,
  resetPassword,
  verifyEmailOtp,
  resendEmailOtp,
};
