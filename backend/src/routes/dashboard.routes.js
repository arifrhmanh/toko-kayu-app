const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboard.controller');
const { authenticate } = require('../middleware/auth');
const { adminOnly } = require('../middleware/authorize');

// All routes require admin authentication
router.use(authenticate);
router.use(adminOnly);

router.get('/overview', dashboardController.getDashboardOverview);
router.get('/sales', dashboardController.getSalesSummary);
router.get('/low-stock', dashboardController.getLowStockProducts);

module.exports = router;
