const express = require('express');
const router = express.Router();
const keuanganController = require('../controllers/keuangan.controller');
const { authenticate } = require('../middleware/auth');
const { adminOnly } = require('../middleware/authorize');

// All routes require admin authentication
router.use(authenticate);
router.use(adminOnly);

router.get('/', keuanganController.getAllKeuangan);
router.get('/summary', keuanganController.getKeuanganSummary);
router.post('/', keuanganController.createKeuangan);
router.put('/:id', keuanganController.updateKeuangan);
router.delete('/:id', keuanganController.deleteKeuangan);

module.exports = router;
