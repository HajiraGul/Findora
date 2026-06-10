const mongoose = require('mongoose');

const {
  validateUpdateProfilePayload,
  validateAvatarPayload,
  validatePasswordChangePayload,
  validatePreferencesPayload,
} = require('../utils/validators');
const {
  getProfileSummary,
  updateProfile,
  updateAvatar,
  updatePassword,
  updatePreferences,
  deleteAccount,
  listUsers,
  setBannedStatus,
  adminDeleteUser,
} = require('../services/user.service');

function me(req, res) {
  return res.status(200).json({
    user: req.user.toSafeObject(),
  });
}

async function summary(req, res, next) {
  try {
    const result = await getProfileSummary(req.user._id);

    return res.status(200).json(result);
  } catch (error) {
    return next(error);
  }
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

async function adminListUsers(req, res, next) {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 20));
    const q = req.query.q ? String(req.query.q).trim() : undefined;
    const result = await listUsers({ page, limit, q });

    return res.status(200).json(result);
  } catch (error) {
    return next(error);
  }
}

async function adminBanUser(req, res, next) {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid user id' });
    }
    const user = await setBannedStatus(req.params.id, true);

    return res.status(200).json({ message: 'User banned successfully', user });
  } catch (error) {
    return next(error);
  }
}

async function adminUnbanUser(req, res, next) {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid user id' });
    }
    const user = await setBannedStatus(req.params.id, false);

    return res.status(200).json({ message: 'User unbanned successfully', user });
  } catch (error) {
    return next(error);
  }
}

async function adminRemoveUser(req, res, next) {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid user id' });
    }
    await adminDeleteUser(req.params.id);

    return res.status(200).json({ message: 'User deleted successfully' });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  me,
  summary,
  patchMe,
  patchAvatar,
  patchPassword,
  patchPreferences,
  deleteMe,
  adminListUsers,
  adminBanUser,
  adminUnbanUser,
  adminRemoveUser,
};
