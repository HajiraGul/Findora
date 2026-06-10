const express = require('express');

const { getStats } = require('../controllers/admin.controller');
const { authenticate, authorize } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(authenticate, authorize('admin'));

router.get('/stats', getStats);

module.exports = router;
