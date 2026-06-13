const express = require('express');

const { getStats } = require('../controllers/admin.controller');
const {
  adminIndex,
  adminSetStatus,
  adminUnlockForClaim,
} = require('../controllers/chat.controller');
const { authenticate, authorize } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(authenticate, authorize('admin'));

router.get('/stats', getStats);
router.get('/chats', adminIndex);
router.patch('/chats/:chatId/status', adminSetStatus);
router.post('/chats/claim/:claimId', adminUnlockForClaim);

module.exports = router;
