const express = require('express');
const router = express.Router();
const alamatController = require('../controllers/alamat.controller');
const { authenticate } = require('../middleware/auth');

// All routes require authentication
router.use(authenticate);

// Raja Ongkir API routes (must be before /:id routes)
router.get('/kota', alamatController.getKota);
router.get('/kecamatan/:kotaId', alamatController.getKecamatan);
router.get('/kelurahan/:kecamatanId', alamatController.getKelurahan);

// Address CRUD routes
router.get('/', alamatController.getAllAlamat);
router.get('/:id', alamatController.getAlamatById);
router.post('/', alamatController.createAlamat);
router.put('/:id', alamatController.updateAlamat);
router.delete('/:id', alamatController.deleteAlamat);
router.put('/:id/default', alamatController.setDefaultAlamat);

module.exports = router;
