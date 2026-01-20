const db = require('../config/database');
const response = require('../utils/response');
const rajaOngkirService = require('../services/rajaongkir.service');

/**
 * Get all addresses for current user
 * GET /api/alamat
 */
async function getAllAlamat(req, res) {
    try {
        const userId = req.user.id;

        const alamat = await db('alamat')
            .where('user_id', userId)
            .orderBy('is_default', 'desc')
            .orderBy('created_at', 'desc');

        return response.success(res, alamat);

    } catch (error) {
        console.error('Get all alamat error:', error);
        return response.serverError(res, 'Failed to get addresses');
    }
}

/**
 * Get address by ID
 * GET /api/alamat/:id
 */
async function getAlamatById(req, res) {
    try {
        const { id } = req.params;
        const userId = req.user.id;

        const alamat = await db('alamat')
            .where('id', id)
            .where('user_id', userId)
            .first();

        if (!alamat) {
            return response.notFound(res, 'Address not found');
        }

        return response.success(res, alamat);

    } catch (error) {
        console.error('Get alamat by id error:', error);
        return response.serverError(res, 'Failed to get address');
    }
}

/**
 * Create new address
 * POST /api/alamat
 */
async function createAlamat(req, res) {
    try {
        const userId = req.user.id;
        const {
            provinsi,
            provinsi_id,
            kota,
            kota_id,
            kecamatan,
            kecamatan_id,
            kelurahan,
            kelurahan_id,
            detail_alamat,
            is_default = false
        } = req.body;

        // Validation
        if (!kota || !kecamatan || !kelurahan) {
            return response.error(res, 'kota, kecamatan, and kelurahan are required', 400);
        }

        // If setting as default, unset other defaults first
        if (is_default) {
            await db('alamat')
                .where('user_id', userId)
                .update({ is_default: false });
        }

        // Check if this is the first address (make it default)
        const existingAddresses = await db('alamat').where('user_id', userId).count('id as count');
        const shouldBeDefault = is_default || parseInt(existingAddresses[0].count) === 0;

        // Create address
        const [alamat] = await db('alamat')
            .insert({
                user_id: userId,
                provinsi: provinsi || 'Jawa Timur',
                provinsi_id: provinsi_id || rajaOngkirService.JAWA_TIMUR_PROVINCE_ID,
                kota,
                kota_id,
                kecamatan,
                kecamatan_id,
                kelurahan,
                kelurahan_id,
                detail_alamat,
                is_default: shouldBeDefault
            })
            .returning('*');

        return response.created(res, alamat, 'Address created successfully');

    } catch (error) {
        console.error('Create alamat error:', error);
        return response.serverError(res, 'Failed to create address');
    }
}

/**
 * Update address
 * PUT /api/alamat/:id
 */
async function updateAlamat(req, res) {
    try {
        const { id } = req.params;
        const userId = req.user.id;
        const {
            provinsi,
            provinsi_id,
            kota,
            kota_id,
            kecamatan,
            kecamatan_id,
            kelurahan,
            kelurahan_id,
            detail_alamat,
            is_default
        } = req.body;

        // Check if address exists and belongs to user
        const existingAlamat = await db('alamat')
            .where('id', id)
            .where('user_id', userId)
            .first();

        if (!existingAlamat) {
            return response.notFound(res, 'Address not found');
        }

        const updates = { updated_at: new Date() };

        if (provinsi !== undefined) updates.provinsi = provinsi;
        if (provinsi_id !== undefined) updates.provinsi_id = provinsi_id;
        if (kota !== undefined) updates.kota = kota;
        if (kota_id !== undefined) updates.kota_id = kota_id;
        if (kecamatan !== undefined) updates.kecamatan = kecamatan;
        if (kecamatan_id !== undefined) updates.kecamatan_id = kecamatan_id;
        if (kelurahan !== undefined) updates.kelurahan = kelurahan;
        if (kelurahan_id !== undefined) updates.kelurahan_id = kelurahan_id;
        if (detail_alamat !== undefined) updates.detail_alamat = detail_alamat;

        // Handle is_default
        if (is_default === true) {
            // Unset other defaults
            await db('alamat')
                .where('user_id', userId)
                .whereNot('id', id)
                .update({ is_default: false });
            updates.is_default = true;
        } else if (is_default === false && existingAlamat.is_default) {
            // If trying to unset the only default, don't allow
            const otherAddresses = await db('alamat')
                .where('user_id', userId)
                .whereNot('id', id)
                .first();

            if (!otherAddresses) {
                return response.error(res, 'Cannot unset default on the only address', 400);
            }
            updates.is_default = false;
        }

        // Update address
        const [updatedAlamat] = await db('alamat')
            .where('id', id)
            .update(updates)
            .returning('*');

        return response.success(res, updatedAlamat, 'Address updated successfully');

    } catch (error) {
        console.error('Update alamat error:', error);
        return response.serverError(res, 'Failed to update address');
    }
}

/**
 * Delete address
 * DELETE /api/alamat/:id
 */
async function deleteAlamat(req, res) {
    try {
        const { id } = req.params;
        const userId = req.user.id;

        // Check if address exists and belongs to user
        const alamat = await db('alamat')
            .where('id', id)
            .where('user_id', userId)
            .first();

        if (!alamat) {
            return response.notFound(res, 'Address not found');
        }

        // Check if address is used in orders
        const orders = await db('orders').where('alamat_id', id).first();
        if (orders) {
            return response.error(res, 'Cannot delete address used in orders', 400);
        }

        // Delete address
        await db('alamat').where('id', id).del();

        // If deleted address was default, set another as default
        if (alamat.is_default) {
            const otherAddress = await db('alamat')
                .where('user_id', userId)
                .first();

            if (otherAddress) {
                await db('alamat')
                    .where('id', otherAddress.id)
                    .update({ is_default: true });
            }
        }

        return response.success(res, null, 'Address deleted successfully');

    } catch (error) {
        console.error('Delete alamat error:', error);
        return response.serverError(res, 'Failed to delete address');
    }
}

/**
 * Set address as default
 * PUT /api/alamat/:id/default
 */
async function setDefaultAlamat(req, res) {
    try {
        const { id } = req.params;
        const userId = req.user.id;

        // Check if address exists and belongs to user
        const alamat = await db('alamat')
            .where('id', id)
            .where('user_id', userId)
            .first();

        if (!alamat) {
            return response.notFound(res, 'Address not found');
        }

        // Unset all defaults
        await db('alamat')
            .where('user_id', userId)
            .update({ is_default: false });

        // Set this as default
        await db('alamat')
            .where('id', id)
            .update({ is_default: true });

        return response.success(res, null, 'Default address updated successfully');

    } catch (error) {
        console.error('Set default alamat error:', error);
        return response.serverError(res, 'Failed to set default address');
    }
}

// ============ Raja Ongkir API Endpoints ============

/**
 * Get cities in Jawa Timur
 * GET /api/alamat/kota
 */
async function getKota(req, res) {
    try {
        const cities = await rajaOngkirService.getKotaJawaTimur();
        return response.success(res, cities);
    } catch (error) {
        console.error('Get kota error:', error);
        return response.serverError(res, 'Failed to get cities');
    }
}

/**
 * Get kecamatan by kota ID
 * GET /api/alamat/kecamatan/:kotaId
 */
async function getKecamatan(req, res) {
    try {
        const { kotaId } = req.params;
        const kecamatan = await rajaOngkirService.getKecamatanByKota(kotaId);
        return response.success(res, kecamatan);
    } catch (error) {
        console.error('Get kecamatan error:', error);
        return response.serverError(res, 'Failed to get districts');
    }
}

/**
 * Get kelurahan by kecamatan ID
 * GET /api/alamat/kelurahan/:kecamatanId
 */
async function getKelurahan(req, res) {
    try {
        const { kecamatanId } = req.params;
        const kelurahan = await rajaOngkirService.getKelurahanByKecamatan(kecamatanId);
        return response.success(res, kelurahan);
    } catch (error) {
        console.error('Get kelurahan error:', error);
        return response.serverError(res, 'Failed to get villages');
    }
}

module.exports = {
    getAllAlamat,
    getAlamatById,
    createAlamat,
    updateAlamat,
    deleteAlamat,
    setDefaultAlamat,
    getKota,
    getKecamatan,
    getKelurahan
};
