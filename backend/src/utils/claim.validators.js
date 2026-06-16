const mongoose = require('mongoose');

const { validateImageUrls } = require('./item.validators');

const allowedProofTypes = [
  // Ownership proof — owner claiming a FOUND item
  'Photo receipt',
  'Serial number',
  'Purchase invoice',
  'Photos of item',
  'Other documentation',
  // Possession proof — finder responding to a LOST item
  'Photo of item',
  'Found location',
  'Other',
];

const allowedStatuses = ['pending', 'approved', 'rejected'];

function validateClaimPayload(payload) {
  const errors = [];
  const data = {};

  const itemId = String(payload.itemId || '').trim();
  if (!itemId) {
    errors.push('Item id is required');
  } else if (!mongoose.Types.ObjectId.isValid(itemId)) {
    errors.push('Invalid item id');
  } else {
    data.itemId = itemId;
  }

  const rawAnswers = Array.isArray(payload.answers) ? payload.answers : [];
  if (rawAnswers.length === 0) {
    errors.push('At least one answer is required');
  } else {
    const answers = [];
    for (const ans of rawAnswers) {
      const question = String(ans.question || '').trim();
      const answer = String(ans.answer || '').trim();

      if (!question || !answer) {
        errors.push('Each answer must have a question and answer');
        break;
      }
      if (question.length > 200) {
        errors.push('Question must be at most 200 characters');
        break;
      }
      if (answer.length > 1000) {
        errors.push('Answer must be at most 1000 characters');
        break;
      }

      answers.push({ question, answer });
    }
    if (answers.length > 0) data.answers = answers;
  }

  if (Object.prototype.hasOwnProperty.call(payload, 'proofType')) {
    const proofType = String(payload.proofType || '').trim();
    if (proofType && !allowedProofTypes.includes(proofType)) {
      errors.push(`Proof type must be one of: ${allowedProofTypes.join(', ')}`);
    }
    if (proofType) data.proofType = proofType;
  }

  if (Object.prototype.hasOwnProperty.call(payload, 'proofImages')) {
    const { errors: imageErrors, images } = validateImageUrls(payload.proofImages);
    errors.push(...imageErrors);
    if (images.length > 0) data.proofImages = images;
  }

  return { errors, data };
}

function validateReviewPayload(payload) {
  const errors = [];
  const data = {};

  if (Object.prototype.hasOwnProperty.call(payload, 'adminNote')) {
    const adminNote = String(payload.adminNote || '').trim();
    if (adminNote.length > 500) {
      errors.push('Admin note must be at most 500 characters');
    }
    data.adminNote = adminNote;
  }

  return { errors, data };
}

function validateClaimsListQuery(query) {
  const filters = {};
  const page = Math.max(1, Number(query.page) || 1);
  const limit = Math.min(50, Math.max(1, Number(query.limit) || 20));

  if (query.status) {
    const status = String(query.status).toLowerCase();
    if (allowedStatuses.includes(status)) filters.status = status;
  }

  return { filters, page, limit };
}

module.exports = {
  validateClaimPayload,
  validateReviewPayload,
  validateClaimsListQuery,
};
