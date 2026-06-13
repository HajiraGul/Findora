const mongoose = require('mongoose');

const Claim = require('../models/claim.model');
const Item = require('../models/item.model');
const { uploadItemImages } = require('./image.service');

function buildItemQuery(filters = {}) {
  const query = {};

  if (filters.status) query.status = filters.status;
  if (filters.category && filters.category !== 'All') query.category = filters.category;
  if (filters.color && filters.color !== 'Any') {
    query.color = new RegExp(`^${escapeRegExp(filters.color)}$`, 'i');
  }
  if (typeof filters.isResolved === 'boolean') query.isResolved = filters.isResolved;
  if (filters.q) {
    query.$or = [
      { title: new RegExp(escapeRegExp(filters.q), 'i') },
      { description: new RegExp(escapeRegExp(filters.q), 'i') },
      { category: new RegExp(escapeRegExp(filters.q), 'i') },
      { 'location.address': new RegExp(escapeRegExp(filters.q), 'i') },
    ];
  }
  if (isValidDate(filters.fromDate) || isValidDate(filters.toDate)) {
    query.createdAt = {};
    if (isValidDate(filters.fromDate)) query.createdAt.$gte = filters.fromDate;
    if (isValidDate(filters.toDate)) query.createdAt.$lte = filters.toDate;
  }

  return query;
}

async function listItems({ filters, page, limit, sort }) {
  const query = buildItemQuery(filters);
  const skip = (page - 1) * limit;
  const sortOption = sort === 'oldest' ? { createdAt: 1 } : { createdAt: -1 };

  const [items, total] = await Promise.all([
    Item.find(query)
      .populate('postedBy', 'fullName')
      .sort(sortOption)
      .skip(skip)
      .limit(limit),
    Item.countDocuments(query),
  ]);

  return {
    items: items.map((item) => item.toSafeObject()),
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit),
    },
  };
}

async function listMyItems(userId, options) {
  const query = {
    ...buildItemQuery(options.filters),
    postedBy: userId,
  };
  const skip = (options.page - 1) * options.limit;

  const [items, total] = await Promise.all([
    Item.find(query)
      .populate('postedBy', 'fullName')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(options.limit),
    Item.countDocuments(query),
  ]);

  return {
    items: items.map((item) => item.toSafeObject()),
    pagination: {
      page: options.page,
      limit: options.limit,
      total,
      pages: Math.ceil(total / options.limit),
    },
  };
}

async function getItemById(itemId) {
  validateObjectId(itemId);
  const item = await Item.findById(itemId).populate('postedBy', 'fullName');

  if (!item) {
    const error = new Error('Item not found');
    error.statusCode = 404;
    throw error;
  }

  return item.toSafeObject();
}

async function createItem(userId, payload) {
  const data = { ...payload };
  if (Array.isArray(data.images) && data.images.length > 0) {
    const uploaded = await uploadItemImages(data.images);
    data.images = uploaded.urls;
    data.imagePublicIds = uploaded.publicIds;
  }

  const item = await Item.create({
    ...data,
    postedBy: userId,
  });
  await item.populate('postedBy', 'fullName');

  return item.toSafeObject();
}

async function updateItem(itemId, user, payload) {
  const item = await findOwnedItem(itemId, user);
  const data = { ...payload };
  if (Array.isArray(data.images)) {
    const uploaded = await uploadItemImages(data.images);
    data.images = uploaded.urls;
    data.imagePublicIds = uploaded.publicIds;
  }

  Object.assign(item, data);
  await item.save();
  await item.populate('postedBy', 'fullName');

  return item.toSafeObject();
}

async function deleteItem(itemId, user) {
  const item = await findOwnedItem(itemId, user);
  // Remove claims against this item so they don't become orphaned references.
  await Claim.deleteMany({ item: item._id });
  await item.deleteOne();
}

async function resolveItem(itemId, user) {
  const item = await findOwnedItem(itemId, user);
  item.isResolved = true;
  item.resolvedAt = new Date();
  await item.save();
  await item.populate('postedBy', 'fullName');

  return item.toSafeObject();
}

async function addItemImages(itemId, user, images) {
  const item = await findOwnedItem(itemId, user);
  const uploaded = await uploadItemImages(images);
  const merged = [...new Set([...item.images, ...uploaded.urls])].slice(0, 4);
  const mergedPublicIds = [
    ...new Set([...item.imagePublicIds, ...uploaded.publicIds]),
  ].slice(0, 4);
  item.images = merged;
  item.imagePublicIds = mergedPublicIds;
  await item.save();
  await item.populate('postedBy', 'fullName');

  return item.toSafeObject();
}

async function listNearbyItems(payload) {
  const query = buildItemQuery({
    status: payload.status,
    category: payload.category,
    isResolved: false,
  });
  query['location.latitude'] = { $exists: true };
  query['location.longitude'] = { $exists: true };

  const items = await Item.find(query)
    .populate('postedBy', 'fullName')
    .sort({ createdAt: -1 })
    .limit(200);
  const nearbyItems = items
    .map((item) => ({
      item,
      distanceKm: calculateDistanceKm(
        payload.latitude,
        payload.longitude,
        item.location.latitude,
        item.location.longitude
      ),
    }))
    .filter(({ distanceKm }) => distanceKm <= payload.radiusKm);

  if (payload.sort === 'newest') {
    nearbyItems.sort((a, b) => b.item.createdAt - a.item.createdAt);
  } else {
    nearbyItems.sort((a, b) => a.distanceKm - b.distanceKm);
  }

  return {
    items: nearbyItems.map(({ item, distanceKm }) =>
      item.toSafeObject(Number(distanceKm.toFixed(2)))
    ),
    radiusKm: payload.radiusKm,
  };
}

async function findOwnedItem(itemId, user) {
  validateObjectId(itemId);
  const item = await Item.findById(itemId);

  if (!item) {
    const error = new Error('Item not found');
    error.statusCode = 404;
    throw error;
  }

  const isOwner = item.postedBy.toString() === user._id.toString();
  const isAdmin = user.role === 'admin';

  if (!isOwner && !isAdmin) {
    const error = new Error('You do not have permission to modify this item');
    error.statusCode = 403;
    throw error;
  }

  return item;
}

function validateObjectId(id) {
  if (!mongoose.Types.ObjectId.isValid(id)) {
    const error = new Error('Invalid item id');
    error.statusCode = 400;
    throw error;
  }
}

function calculateDistanceKm(lat1, lon1, lat2, lon2) {
  const radius = 6371;
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return radius * c;
}

function toRadians(value) {
  return (value * Math.PI) / 180;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function isValidDate(value) {
  return value instanceof Date && !Number.isNaN(value.getTime());
}

module.exports = {
  listItems,
  listMyItems,
  getItemById,
  createItem,
  updateItem,
  deleteItem,
  resolveItem,
  addItemImages,
  listNearbyItems,
};
