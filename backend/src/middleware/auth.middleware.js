const User = require('../models/user.model');
const { verifyToken } = require('../utils/jwt');

async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization || '';
    const [scheme, token] = authHeader.split(' ');

    if (scheme !== 'Bearer' || !token) {
      return res.status(401).json({ message: 'Authentication token required' });
    }

    const payload = verifyToken(token);
    const user = await User.findById(payload.sub).select('+tokenVersion');

    if (!user) {
      return res.status(401).json({ message: 'User no longer exists' });
    }

    if ((payload.tokenVersion || 0) !== (user.tokenVersion || 0)) {
      return res.status(401).json({ message: 'Token has been revoked' });
    }

    req.user = user;
    req.token = token;
    return next();
  } catch (error) {
    error.statusCode = 401;
    error.message = 'Invalid or expired token';
    return next(error);
  }
}

function authorize(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Access denied' });
    }

    return next();
  };
}

module.exports = {
  authenticate,
  authorize,
};
