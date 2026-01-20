const express = require('express');
const router = express.Router();
const produkController = require('../controllers/produk.controller');
const { authenticate } = require('../middleware/auth');
const { adminOnly } = require('../middleware/authorize');
const { uploadSingle } = require('../middleware/upload');

// All routes require authentication
router.use(authenticate);

// Get all products (all authenticated users)
router.get('/', produkController.getAllProduk);
router.get('/:id', produkController.getProdukById);

// Admin only routes
router.post('/', adminOnly, uploadSingle, produkController.createProduk);
router.put('/:id', adminOnly, uploadSingle, produkController.updateProduk);
router.delete('/:id', adminOnly, produkController.deleteProduk);

module.exports = router;
