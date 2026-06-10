const {
  validateClaimPayload,
  validateReviewPayload,
  validateClaimsListQuery,
} = require('../utils/claim.validators');
const {
  submitClaim,
  getMyClaims,
  listAllClaims,
  getClaimById,
  reviewClaim,
} = require('../services/claim.service');

async function store(req, res, next) {
  try {
    const { errors, data } = validateClaimPayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({ message: 'Validation failed', errors });
    }

    const claim = await submitClaim(req.user._id, data);

    return res.status(201).json({
      message: 'Claim submitted successfully',
      claim,
    });
  } catch (error) {
    return next(error);
  }
}

async function mine(req, res, next) {
  try {
    const { filters, page, limit } = validateClaimsListQuery(req.query);
    const result = await getMyClaims(req.user._id, filters);

    return res.status(200).json(result);
  } catch (error) {
    return next(error);
  }
}

async function index(req, res, next) {
  try {
    const { filters, page, limit } = validateClaimsListQuery(req.query);
    const result = await listAllClaims(filters, page, limit);

    return res.status(200).json(result);
  } catch (error) {
    return next(error);
  }
}

async function show(req, res, next) {
  try {
    const claim = await getClaimById(req.params.id, req.user);

    return res.status(200).json({ claim });
  } catch (error) {
    return next(error);
  }
}

async function approve(req, res, next) {
  try {
    const { errors, data } = validateReviewPayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({ message: 'Validation failed', errors });
    }

    const claim = await reviewClaim(req.params.id, req.user, 'approved', data.adminNote);

    return res.status(200).json({
      message: 'Claim approved successfully',
      claim,
    });
  } catch (error) {
    return next(error);
  }
}

async function reject(req, res, next) {
  try {
    const { errors, data } = validateReviewPayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({ message: 'Validation failed', errors });
    }

    const claim = await reviewClaim(req.params.id, req.user, 'rejected', data.adminNote);

    return res.status(200).json({
      message: 'Claim rejected successfully',
      claim,
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  store,
  mine,
  index,
  show,
  approve,
  reject,
};
