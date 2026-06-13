const bcrypt = require('bcryptjs');

const Claim = require('../models/claim.model');
const Item = require('../models/item.model');
const User = require('../models/user.model');

async function getProfileSummary(userId) {
  const [user, posts, claims, matches] = await Promise.all([
    getSafeUser(userId),
    Item.countDocuments({ postedBy: userId }),
    Claim.countDocuments({ claimant: userId }),
    countPotentialMatches(userId),
  ]);

  return {
    user,
    stats: {
      posts,
      claims,
      matches,
    },
  };
}

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

async function cascadeDeleteUserData(userId) {
  const items = await Item.find({ postedBy: userId }).select('_id');
  const itemIds = items.map((item) => item._id);

  await Claim.deleteMany({
    $or: [{ claimant: userId }, { item: { $in: itemIds } }],
  });
  await Item.deleteMany({ postedBy: userId });
}

async function deleteAccount(userId) {
  await cascadeDeleteUserData(userId);
  await User.findByIdAndDelete(userId);
}

async function listUsers({ page, limit, q }) {
  const query = {};
  if (q) {
    query.$or = [
      { fullName: new RegExp(escapeRegExp(q), 'i') },
      { email: new RegExp(escapeRegExp(q), 'i') },
    ];
  }
  const skip = (page - 1) * limit;
  const [users, total] = await Promise.all([
    User.find(query).sort({ createdAt: -1 }).skip(skip).limit(limit),
    User.countDocuments(query),
  ]);
  return {
    users: users.map((u) => u.toSafeObject()),
    pagination: { page, limit, total, pages: Math.ceil(total / limit) },
  };
}

async function setBannedStatus(userId, banned) {
  const user = await User.findByIdAndUpdate(
    userId,
    { banned },
    { new: true, runValidators: true }
  );
  if (!user) {
    const error = new Error('User not found');
    error.statusCode = 404;
    throw error;
  }
  return user.toSafeObject();
}

async function adminDeleteUser(userId) {
  const user = await User.findById(userId);
  if (!user) {
    const error = new Error('User not found');
    error.statusCode = 404;
    throw error;
  }

  await cascadeDeleteUserData(userId);
  await user.deleteOne();
}

async function getSafeUser(userId) {
  const user = await User.findById(userId);

  if (!user) {
    const error = new Error('User not found');
    error.statusCode = 404;
    throw error;
  }

  return user.toSafeObject();
}

async function countPotentialMatches(userId) {
  const userItems = await Item.find({
    postedBy: userId,
    isResolved: false,
  }).select('status category color');

  if (userItems.length === 0) return 0;

  const matchConditions = userItems.map((item) => {
    const condition = {
      postedBy: { $ne: userId },
      isResolved: false,
      status: item.status === 'lost' ? 'found' : 'lost',
      category: item.category,
    };

    if (item.color) {
      condition.color = new RegExp(`^${escapeRegExp(item.color)}$`, 'i');
    }

    return condition;
  });

  return Item.countDocuments({ $or: matchConditions });
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

function escapeRegExp(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

module.exports = {
  getProfileSummary,
  updateProfile,
  updateAvatar,
  updatePassword,
  updatePreferences,
  deleteAccount,
  listUsers,
  setBannedStatus,
  adminDeleteUser,
};
