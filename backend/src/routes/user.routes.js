const express = require('express');

const {
  me,
  summary,
  patchMe,
  patchAvatar,
  patchPassword,
  patchPreferences,
  deleteMe,
} = require('../controllers/user.controller');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(authenticate);

router.get('/me', me);
router.get('/me/profile-summary', summary);
router.patch('/me', patchMe);
router.patch('/me/avatar', patchAvatar);
router.patch('/me/password', patchPassword);
router.patch('/me/preferences', patchPreferences);
router.delete('/me', deleteMe);

module.exports = router;
