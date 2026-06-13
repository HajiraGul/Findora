const express = require('express');

const {
  index,
  mine,
  nearby,
  show,
  store,
  patch,
  destroy,
  resolve,
  images,
  matches,
  notifyMatch,
} = require('../controllers/item.controller');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

router.get('/', index);
router.get('/nearby', nearby);
router.get('/me', authenticate, mine);
router.post('/', authenticate, store);
// Specific `/:id/...` routes are declared before the bare `/:id` show route.
router.get('/:id/matches', authenticate, matches);
router.post('/:id/notify-match', authenticate, notifyMatch);
router.get('/:id', show);
router.patch('/:id', authenticate, patch);
router.delete('/:id', authenticate, destroy);
router.post('/:id/resolve', authenticate, resolve);
router.post('/:id/images', authenticate, images);

module.exports = router;
