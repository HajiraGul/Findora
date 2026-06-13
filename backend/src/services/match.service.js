const mongoose = require('mongoose');

const Item = require('../models/item.model');

// Scoring weights — a candidate must share the source item's category (a hard
// gate, enforced by the query) and then earns points for each additional
// signal. Max possible = 100.
const WEIGHTS = {
  category: 35, // always granted, since category is a query gate
  color: 25,
  distanceNear: 20, // within NEAR_KM
  distanceMid: 10, // within MID_KM
  keywords: 15, // scaled by overlap ratio
  recency: 5, // reported within RECENCY_DAYS of each other
};

const NEAR_KM = 1;
const MID_KM = 5;
const RECENCY_DAYS = 14;

// Confidence thresholds. Anything below MIN_SCORE is not surfaced at all, so a
// shared category alone (35) never spams the user.
const HIGH_SCORE = 70;
const MIN_SCORE = 40;

const STOP_WORDS = new Set([
  'the', 'a', 'an', 'and', 'or', 'of', 'to', 'in', 'on', 'at', 'my', 'me',
  'is', 'was', 'with', 'near', 'around', 'lost', 'found', 'item', 'items',
  'please', 'contact', 'has', 'have', 'for', 'this', 'that', 'it', 'i',
]);

function ownerIdOf(item) {
  return item.postedBy && item.postedBy._id ? item.postedBy._id : item.postedBy;
}

function hasCoords(item) {
  return (
    item.location &&
    typeof item.location.latitude === 'number' &&
    typeof item.location.longitude === 'number'
  );
}

function tokenize(text) {
  return new Set(
    String(text || '')
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, ' ')
      .split(/\s+/)
      .filter((word) => word.length > 2 && !STOP_WORDS.has(word))
  );
}

// Overlap ratio (0..1) between the two items' title+description keywords,
// normalised by the smaller set so a short post isn't penalised.
function keywordOverlap(source, candidate) {
  const a = tokenize(`${source.title} ${source.description}`);
  const b = tokenize(`${candidate.title} ${candidate.description}`);
  if (a.size === 0 || b.size === 0) return 0;

  let shared = 0;
  a.forEach((word) => {
    if (b.has(word)) shared += 1;
  });

  return shared / Math.min(a.size, b.size);
}

function scoreMatch(source, candidate) {
  let score = WEIGHTS.category;
  const reasons = [candidate.category];

  const sourceColor = (source.color || '').trim().toLowerCase();
  const candidateColor = (candidate.color || '').trim().toLowerCase();
  if (sourceColor && candidateColor && sourceColor === candidateColor) {
    score += WEIGHTS.color;
    reasons.push(candidate.color);
  }

  let distanceKm = null;
  if (hasCoords(source) && hasCoords(candidate)) {
    distanceKm = calculateDistanceKm(
      source.location.latitude,
      source.location.longitude,
      candidate.location.latitude,
      candidate.location.longitude
    );
    if (distanceKm <= NEAR_KM) {
      score += WEIGHTS.distanceNear;
      reasons.push(`${distanceKm.toFixed(1)} km away`);
    } else if (distanceKm <= MID_KM) {
      score += WEIGHTS.distanceMid;
      reasons.push(`${distanceKm.toFixed(1)} km away`);
    }
  }

  const overlap = keywordOverlap(source, candidate);
  if (overlap > 0) {
    score += Math.round(WEIGHTS.keywords * overlap);
  }

  const daysApart =
    Math.abs(new Date(source.createdAt) - new Date(candidate.createdAt)) /
    (1000 * 60 * 60 * 24);
  if (daysApart <= RECENCY_DAYS) {
    score += WEIGHTS.recency;
  }

  score = Math.min(100, Math.round(score));

  return { score, distanceKm, reasons };
}

async function getCandidates(sourceItem) {
  const oppositeStatus = sourceItem.status === 'lost' ? 'found' : 'lost';

  return Item.find({
    _id: { $ne: sourceItem._id },
    status: oppositeStatus,
    category: sourceItem.category,
    isResolved: false,
    postedBy: { $ne: ownerIdOf(sourceItem) },
  })
    .populate('postedBy', 'fullName')
    .limit(100);
}

// Returns scored, ranked match suggestions for one source item. Each entry is
// { item: safeObject, score, confidence, reasons } above the MIN_SCORE floor.
async function findMatchesForItem(sourceItem) {
  const candidates = await getCandidates(sourceItem);

  return candidates
    .map((candidate) => ({ candidate, ...scoreMatch(sourceItem, candidate) }))
    .filter(({ score }) => score >= MIN_SCORE)
    .sort((a, b) => b.score - a.score)
    .map(({ candidate, score, distanceKm, reasons }) => ({
      item: candidate.toSafeObject(
        distanceKm != null ? Number(distanceKm.toFixed(2)) : undefined
      ),
      score,
      confidence: score >= HIGH_SCORE ? 'high' : 'possible',
      reasons,
    }));
}

// Endpoint-facing: matches for one of the caller's own posts (admins may view
// any). Returns the source item too so the client can render the header and
// pick the right call-to-action based on its lost/found status.
async function getMatchesForItem(itemId, user) {
  validateObjectId(itemId);
  const item = await Item.findById(itemId).populate('postedBy', 'fullName');

  if (!item) {
    const error = new Error('Item not found');
    error.statusCode = 404;
    throw error;
  }

  const isOwner = ownerIdOf(item).toString() === user._id.toString();
  if (!isOwner && user.role !== 'admin') {
    const error = new Error('You can only view matches for your own posts');
    error.statusCode = 403;
    throw error;
  }

  const matches = await findMatchesForItem(item);

  return {
    sourceItem: item.toSafeObject(),
    matches,
    total: matches.length,
  };
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

module.exports = {
  findMatchesForItem,
  getMatchesForItem,
};
