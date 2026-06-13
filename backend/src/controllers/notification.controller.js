const {
  listNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
} = require('../services/notification.service');

function parsePagination(query) {
  const page = Math.max(1, parseInt(query.page, 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit, 10) || 30));
  return { page, limit };
}

async function index(req, res, next) {
  try {
    const result = await listNotifications(req.user._id, parsePagination(req.query));
    return res.status(200).json(result);
  } catch (error) {
    return next(error);
  }
}

async function unreadCount(req, res, next) {
  try {
    const result = await getUnreadCount(req.user._id);
    return res.status(200).json(result);
  } catch (error) {
    return next(error);
  }
}

async function read(req, res, next) {
  try {
    const notification = await markAsRead(req.user._id, req.params.id);
    return res.status(200).json({ notification });
  } catch (error) {
    return next(error);
  }
}

async function readAll(req, res, next) {
  try {
    const result = await markAllAsRead(req.user._id);
    return res.status(200).json(result);
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  index,
  unreadCount,
  read,
  readAll,
};
