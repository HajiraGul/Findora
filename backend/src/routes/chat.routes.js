const express = require('express');

const {
  mine,
  show,
  messages,
  send,
  openForClaim,
} = require('../controllers/chat.controller');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(authenticate);

router.get('/', mine);
// Ensure (create-if-missing) and return the chat for an approved claim the
// caller participates in. Self-heals claims approved before chat was set up.
router.post('/claim/:claimId', openForClaim);
router.get('/:chatId', show);
router.get('/:chatId/messages', messages);
router.post('/:chatId/messages', send);

module.exports = router;
