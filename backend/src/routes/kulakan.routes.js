const express = require('express');
const router = express.Router();
const kulakanController = require('../controllers/kulakan.controller');
const { authenticate } = require('../middleware/auth');
const { adminOnly } = require('../middleware/authorize');

// All routes require admin authentication
router.use(authenticate);
router.use(adminOnly);

router.get('/', kulakanController.getAllKulakan);
router.get('/:id', kulakanController.getKulakanById);
router.post('/', kulakanController.createKulakan);
router.delete('/:id', kulakanController.deleteKulakan);

module.exports = router;
