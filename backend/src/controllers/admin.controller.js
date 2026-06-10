const Claim = require('../models/claim.model');
const Item = require('../models/item.model');
const User = require('../models/user.model');

async function getStats(req, res, next) {
  try {
    const [pendingClaims, activePosts, totalUsers, totalClaims] =
      await Promise.all([
        Claim.countDocuments({ status: 'pending' }),
        Item.countDocuments({ isResolved: false }),
        User.countDocuments(),
        Claim.countDocuments(),
      ]);

    return res.status(200).json({
      stats: {
        pendingClaims,
        activePosts,
        totalUsers,
        totalClaims,
      },
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = { getStats };
