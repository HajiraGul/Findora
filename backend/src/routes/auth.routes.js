const express = require('express');

const {
  register,
  login,
  googleAuth,
  me,
  logout,
  forgotPassword,
  resetPassword,
  verifyOtp,
  resendOtp,
} = require('../controllers/auth.controller');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.post('/google', googleAuth);
router.post('/logout', authenticate, logout);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.post('/verify-otp', verifyOtp);
router.post('/resend-otp', resendOtp);
router.get('/me', authenticate, me);

module.exports = router;
