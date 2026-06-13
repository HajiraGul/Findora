const express = require('express');

const {
  index,
  unreadCount,
  read,
  readAll,
} = require('../controllers/notification.controller');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(authenticate);

router.get('/', index);
router.get('/unread-count', unreadCount);
// `read-all` is declared before `:id/read` so it isn't swallowed as an id.
router.patch('/read-all', readAll);
router.patch('/:id/read', read);

module.exports = router;
