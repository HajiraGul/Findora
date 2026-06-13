const express = require('express');

const { mine, show, messages, send } = require('../controllers/chat.controller');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(authenticate);

router.get('/', mine);
router.get('/:chatId', show);
router.get('/:chatId/messages', messages);
router.post('/:chatId/messages', send);

module.exports = router;
