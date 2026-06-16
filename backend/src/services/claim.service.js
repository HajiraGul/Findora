const mongoose = require('mongoose');

const Claim = require('../models/claim.model');
const Item = require('../models/item.model');
const { ensureChatForClaim } = require('./chat.service');
const { notifyClaimReviewed } = require('./notification.service');
const { uploadClaimImages } = require('./image.service');

async function submitClaim(userId, payload) {
  validateObjectId(payload.itemId, 'item');

  const item = await Item.findById(payload.itemId);
  if (!item) {
    const error = new Error('Item not found');
    error.statusCode = 404;
    throw error;
  }
  if (item.postedBy.toString() === userId.toString()) {
    const error = new Error('You cannot claim your own item');
    error.statusCode = 400;
    throw error;
  }
  if (item.isResolved) {
    const error = new Error('This item has already been resolved');
    error.statusCode = 400;
    throw error;
  }

  const existingClaim = await Claim.findOne({ item: payload.itemId, claimant: userId });
  if (existingClaim) {
    const error = new Error('You have already submitted a claim for this item');
    error.statusCode = 409;
    throw error;
  }

  let proofImages = [];
  if (Array.isArray(payload.proofImages) && payload.proofImages.length > 0) {
    const uploaded = await uploadClaimImages(payload.proofImages);
    proofImages = uploaded.urls;
  }

  const claim = await Claim.create({
    item: payload.itemId,
    claimant: userId,
    answers: payload.answers,
    proofType: payload.proofType,
    proofImages,
  });
  await claim.populate('item', 'title category');
  await claim.populate('claimant', 'fullName');

  return claim.toSafeObject();
}

async function getMyClaims(userId, filters) {
  const query = { claimant: userId };
  if (filters.status) query.status = filters.status;

  const [claims, total] = await Promise.all([
    Claim.find(query)
      .populate('item', 'title category')
      .populate('claimant', 'fullName')
      .sort({ createdAt: -1 }),
    Claim.countDocuments(query),
  ]);

  return {
    claims: claims.map((c) => c.toSafeObject()),
    total,
  };
}

async function listAllClaims(filters, page, limit) {
  const query = {};
  if (filters.status) query.status = filters.status;

  const skip = (page - 1) * limit;
  const [claims, total] = await Promise.all([
    Claim.find(query)
      .populate('item', 'title category')
      .populate('claimant', 'fullName')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    Claim.countDocuments(query),
  ]);

  return {
    claims: claims.map((c) => c.toSafeObject()),
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit),
    },
  };
}

async function getClaimById(claimId, user) {
  validateObjectId(claimId, 'claim');

  const claim = await Claim.findById(claimId)
    .populate('item', 'title category')
    .populate('claimant', 'fullName');

  if (!claim) {
    const error = new Error('Claim not found');
    error.statusCode = 404;
    throw error;
  }

  const isOwner = claim.claimant._id.toString() === user._id.toString();
  const isAdmin = user.role === 'admin';

  if (!isOwner && !isAdmin) {
    const error = new Error('Access denied');
    error.statusCode = 403;
    throw error;
  }

  return claim.toSafeObject();
}

async function reviewClaim(claimId, adminUser, newStatus, adminNote) {
  validateObjectId(claimId, 'claim');

  const claim = await Claim.findById(claimId)
    .populate('item', 'title category')
    .populate('claimant', 'fullName');

  if (!claim) {
    const error = new Error('Claim not found');
    error.statusCode = 404;
    throw error;
  }
  if (claim.status !== 'pending') {
    const error = new Error('Claim has already been reviewed');
    error.statusCode = 400;
    throw error;
  }

  claim.status = newStatus;
  claim.adminNote = adminNote !== undefined ? adminNote : '';
  claim.reviewedBy = adminUser._id;
  claim.reviewedAt = new Date();
  await claim.save();

  if (newStatus === 'approved') {
    // Approving a claim is the admin allowing the claimant and the item
    // poster to talk; a failed Firestore write must not undo the approval.
    try {
      await ensureChatForClaim(claim._id.toString());
    } catch (chatError) {
      console.error(`Chat unlock skipped for claim ${claim._id}: ${chatError.message}`);
    }
  }

  // Let the claimant know the outcome (approval unlocks chat; rejection carries
  // the reason). Fire-and-forget so it never blocks or undoes the review.
  notifyClaimReviewed(claim).catch(() => {});

  return claim.toSafeObject();
}

function validateObjectId(id, label = 'id') {
  if (!mongoose.Types.ObjectId.isValid(id)) {
    const error = new Error(`Invalid ${label} id`);
    error.statusCode = 400;
    throw error;
  }
}

module.exports = {
  submitClaim,
  getMyClaims,
  listAllClaims,
  getClaimById,
  reviewClaim,
};
