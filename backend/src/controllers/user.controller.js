const {
  validateUpdateProfilePayload,
  validateAvatarPayload,
  validatePasswordChangePayload,
  validatePreferencesPayload,
} = require('../utils/validators');
const {
  updateProfile,
  updateAvatar,
  updatePassword,
  updatePreferences,
  deleteAccount,
} = require('../services/user.service');

function me(req, res) {
  return res.status(200).json({
    user: req.user.toSafeObject(),
  });
}

async function patchMe(req, res, next) {
  try {
    const { errors, data } = validateUpdateProfilePayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({
        message: 'Validation failed',
        errors,
      });
    }

    const user = await updateProfile(req.user._id, data);

    return res.status(200).json({
      message: 'Profile updated successfully',
      user,
    });
  } catch (error) {
    return next(error);
  }
}

async function patchAvatar(req, res, next) {
  try {
    const { errors, data } = validateAvatarPayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({
        message: 'Validation failed',
        errors,
      });
    }

    const user = await updateAvatar(req.user._id, data);

    return res.status(200).json({
      message: 'Avatar updated successfully',
      user,
    });
  } catch (error) {
    return next(error);
  }
}

async function patchPassword(req, res, next) {
  try {
    const { errors, data } = validatePasswordChangePayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({
        message: 'Validation failed',
        errors,
      });
    }

    const result = await updatePassword(req.user._id, data);

    return res.status(200).json(result);
  } catch (error) {
    return next(error);
  }
}

async function patchPreferences(req, res, next) {
  try {
    const { errors, data } = validatePreferencesPayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({
        message: 'Validation failed',
        errors,
      });
    }

    const user = await updatePreferences(req.user._id, data);

    return res.status(200).json({
      message: 'Preferences updated successfully',
      user,
    });
  } catch (error) {
    return next(error);
  }
}

async function deleteMe(req, res, next) {
  try {
    await deleteAccount(req.user._id);

    return res.status(200).json({
      message: 'Account deleted successfully',
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  me,
  patchMe,
  patchAvatar,
  patchPassword,
  patchPreferences,
  deleteMe,
};
