const bcrypt = require('bcryptjs');

const User = require('../models/user.model');

async function updateProfile(userId, payload) {
  await ensureUniqueProfileFields(userId, payload);

  const user = await User.findByIdAndUpdate(userId, payload, {
    new: true,
    runValidators: true,
  });

  return user.toSafeObject();
}

async function updateAvatar(userId, payload) {
  const user = await User.findByIdAndUpdate(
    userId,
    { avatarUrl: payload.avatarUrl },
    { new: true, runValidators: true }
  );

  return user.toSafeObject();
}

async function updatePassword(userId, payload) {
  const user = await User.findById(userId).select('+password +tokenVersion');

  if (!user) {
    const error = new Error('User not found');
    error.statusCode = 404;
    throw error;
  }

  const passwordMatches = await bcrypt.compare(
    payload.currentPassword,
    user.password
  );

  if (!passwordMatches) {
    const error = new Error('Current password is incorrect');
    error.statusCode = 400;
    throw error;
  }

  user.password = await bcrypt.hash(payload.newPassword, 12);
  user.tokenVersion += 1;
  await user.save();

  return { message: 'Password updated successfully' };
}

async function updatePreferences(userId, payload) {
  const set = {};

  for (const [key, value] of Object.entries(payload)) {
    set[`preferences.${key}`] = value;
  }

  const user = await User.findByIdAndUpdate(
    userId,
    { $set: set },
    { new: true, runValidators: true }
  );

  return user.toSafeObject();
}

async function deleteAccount(userId) {
  await User.findByIdAndDelete(userId);
}

async function ensureUniqueProfileFields(userId, payload) {
  const conditions = [];

  if (payload.email) conditions.push({ email: payload.email });
  if (payload.phone) conditions.push({ phone: payload.phone });

  if (conditions.length === 0) return;

  const existingUser = await User.findOne({
    _id: { $ne: userId },
    $or: conditions,
  });

  if (!existingUser) return;

  const field = existingUser.email === payload.email ? 'email' : 'phone';
  const error = new Error(`An account with this ${field} already exists`);
  error.statusCode = 409;
  throw error;
}

module.exports = {
  updateProfile,
  updateAvatar,
  updatePassword,
  updatePreferences,
  deleteAccount,
};
