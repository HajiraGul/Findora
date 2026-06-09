function notFound(req, res, next) {
  const error = new Error(`Route not found: ${req.originalUrl}`);
  error.statusCode = 404;
  next(error);
}

function errorHandler(error, req, res, next) {
  if (error.code === 11000) {
    const field = Object.keys(error.keyValue || {})[0] || 'field';

    return res.status(409).json({
      message: `An account with this ${field} already exists`,
    });
  }

  const statusCode = error.statusCode || 500;

  res.status(statusCode).json({
    message: error.message || 'Internal server error',
    stack: process.env.NODE_ENV === 'production' ? undefined : error.stack,
  });
}

module.exports = {
  notFound,
  errorHandler,
};
