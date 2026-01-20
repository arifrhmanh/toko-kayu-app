const express = require('express');
const router = express.Router();
const notifikasiController = require('../controllers/notifikasi.controller');
const { authenticate } = require('../middleware/auth');

// All routes require authentication
router.use(authenticate);

router.get('/', notifikasiController.getNotifikasi);
router.get('/count', notifikasiController.getUnreadCount);
router.put('/read-all', notifikasiController.markAllAsRead);
router.put('/:id/read', notifikasiController.markAsRead);
router.delete('/:id', notifikasiController.deleteNotifikasi);

module.exports = router;
