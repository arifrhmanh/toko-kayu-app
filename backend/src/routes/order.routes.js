const express = require('express');
const router = express.Router();
const orderController = require('../controllers/order.controller');
const { authenticate } = require('../middleware/auth');
const { adminOnly, customerOnly } = require('../middleware/authorize');

// All routes require authentication
router.use(authenticate);

// Get orders (admin: all, customer: own)
router.get('/', orderController.getAllOrders);
router.get('/:id', orderController.getOrderById);

// Customer only routes
router.post('/', customerOnly, orderController.createOrder);
router.delete('/:id', customerOnly, orderController.cancelOrder);

// Admin only routes
router.put('/:id/status', adminOnly, orderController.updateOrderStatus);

module.exports = router;
