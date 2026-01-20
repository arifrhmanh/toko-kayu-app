const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/payment.controller');
const { authenticate } = require('../middleware/auth');

// Callback doesn't need auth (called by Midtrans)
router.post('/callback', paymentController.handleCallback);

// Redirect handlers (don't need auth)
router.get('/finish', paymentController.handleFinish);
router.get('/unfinish', paymentController.handleUnfinish);
router.get('/error', paymentController.handleError);

// Protected routes
router.post('/create', authenticate, paymentController.createPayment);
router.get('/status/:orderId', authenticate, paymentController.checkStatus);

module.exports = router;
