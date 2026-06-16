const {
  validateRegisterPayload,
  validateLoginPayload,
  validateEmailPayload,
  validateOtpPayload,
  validateResetPasswordPayload,
} = require('../utils/validators');
const {
  registerUser,
  loginUser,
  googleSignIn,
  logoutUser,
  requestPasswordReset,
  resetPassword,
  verifyEmailOtp,
  resendEmailOtp,
} = require('../services/auth.service');

async function register(req, res, next) {
  try {
    const { errors, data } = validateRegisterPayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({
        message: 'Validation failed',
        errors,
      });
    }

    const result = await registerUser(data);

    return res.status(201).json({
      message: 'Account created successfully',
      ...result,
    });
  } catch (error) {
    return next(error);
  }
}

async function login(req, res, next) {
  try {
    const { errors, data } = validateLoginPayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({
        message: 'Validation failed',
        errors,
      });
    }

    const result = await loginUser(data);

    return res.status(200).json({
      message: 'Login successful',
      ...result,
    });
  } catch (error) {
    return next(error);
  }
}

async function googleAuth(req, res, next) {
  try {
    const result = await googleSignIn(req.body);

    return res.status(200).json({
      message: 'Login successful',
      ...result,
    });
  } catch (error) {
    return next(error);
  }
}

async function me(req, res) {
  return res.status(200).json({
    user: req.user.toSafeObject(),
  });
}

async function logout(req, res, next) {
  try {
    await logoutUser(req.user._id);

    return res.status(200).json({
      message: 'Logout successful',
    });
  } catch (error) {
    return next(error);
  }
}

async function forgotPassword(req, res, next) {
  try {
    const { errors, data } = validateEmailPayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({
        message: 'Validation failed',
        errors,
      });
    }

    const result = await requestPasswordReset(data);

    return res.status(200).json(result);
  } catch (error) {
    return next(error);
  }
}

async function resetPasswordHandler(req, res, next) {
  try {
    const { errors, data } = validateResetPasswordPayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({
        message: 'Validation failed',
        errors,
      });
    }

    const result = await resetPassword(data);

    return res.status(200).json(result);
  } catch (error) {
    return next(error);
  }
}

async function verifyOtp(req, res, next) {
  try {
    const { errors, data } = validateOtpPayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({
        message: 'Validation failed',
        errors,
      });
    }

    const result = await verifyEmailOtp(data);

    return res.status(200).json(result);
  } catch (error) {
    return next(error);
  }
}

async function resendOtp(req, res, next) {
  try {
    const { errors, data } = validateEmailPayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({
        message: 'Validation failed',
        errors,
      });
    }

    const result = await resendEmailOtp(data);

    return res.status(200).json(result);
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  register,
  login,
  googleAuth,
  me,
  logout,
  forgotPassword,
  resetPassword: resetPasswordHandler,
  verifyOtp,
  resendOtp,
};
