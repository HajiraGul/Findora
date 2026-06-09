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
} = require('../controllers/item.controller');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

router.get('/', index);
router.get('/nearby', nearby);
router.get('/me', authenticate, mine);
router.post('/', authenticate, store);
router.get('/:id', show);
router.patch('/:id', authenticate, patch);
router.delete('/:id', authenticate, destroy);
router.post('/:id/resolve', authenticate, resolve);
router.post('/:id/images', authenticate, images);

module.exports = router;
