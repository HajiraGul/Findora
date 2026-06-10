const express = require('express');

const { store, mine, index, show, approve, reject } = require('../controllers/claim.controller');
const { authenticate, authorize } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(authenticate);

router.post('/', store);
router.get('/me', mine);
router.get('/', authorize('admin'), index);
router.get('/:id', show);
router.patch('/:id/approve', authorize('admin'), approve);
router.patch('/:id/reject', authorize('admin'), reject);

module.exports = router;
