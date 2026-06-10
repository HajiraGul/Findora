const express = require('express');

const {
  me,
  summary,
  patchMe,
  patchAvatar,
  patchPassword,
  patchPreferences,
  deleteMe,
  adminListUsers,
  adminBanUser,
  adminUnbanUser,
  adminRemoveUser,
} = require('../controllers/user.controller');
const { authenticate, authorize } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(authenticate);

router.get('/me', me);
router.get('/me/profile-summary', summary);
router.patch('/me', patchMe);
router.patch('/me/avatar', patchAvatar);
router.patch('/me/password', patchPassword);
router.patch('/me/preferences', patchPreferences);
router.delete('/me', deleteMe);

// Admin user management
router.get('/', authorize('admin'), adminListUsers);
router.patch('/:id/ban', authorize('admin'), adminBanUser);
router.patch('/:id/unban', authorize('admin'), adminUnbanUser);
router.delete('/:id', authorize('admin'), adminRemoveUser);

module.exports = router;
