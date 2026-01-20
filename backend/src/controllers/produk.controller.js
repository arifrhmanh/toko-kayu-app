const db = require('../config/database');
const response = require('../utils/response');
const { uploadFile, deleteFile, getFilePathFromUrl } = require('../config/storage');

/**
 * Get all products
 * GET /api/produk
 */
async function getAllProduk(req, res) {
    try {
        const { page = 1, limit = 20, search, low_stock } = req.query;
        const offset = (parseInt(page) - 1) * parseInt(limit);

        let query = db('produk').orderBy('created_at', 'desc');
        let countQuery = db('produk');

        // Search filter
        if (search) {
            query = query.where('nama_produk', 'ilike', `%${search}%`);
            countQuery = countQuery.where('nama_produk', 'ilike', `%${search}%`);
        }

        // Low stock filter
        if (low_stock === 'true') {
            query = query.whereRaw('stok < stok_minimum');
            countQuery = countQuery.whereRaw('stok < stok_minimum');
        }

        // Get total count
        const [{ count }] = await countQuery.count('id as count');

        // Get paginated data
        const produk = await query.limit(parseInt(limit)).offset(offset);

        return response.paginated(res, produk, {
            page: parseInt(page),
            limit: parseInt(limit),
            total: parseInt(count)
        });

    } catch (error) {
        console.error('Get all produk error:', error);
        return response.serverError(res, 'Failed to get products');
    }
}

/**
 * Get product by ID
 * GET /api/produk/:id
 */
async function getProdukById(req, res) {
    try {
        const { id } = req.params;

        const produk = await db('produk').where('id', id).first();

        if (!produk) {
            return response.notFound(res, 'Product not found');
        }

        return response.success(res, produk);

    } catch (error) {
        console.error('Get produk by id error:', error);
        return response.serverError(res, 'Failed to get product');
    }
}

/**
 * Create new product (Admin only)
 * POST /api/produk
 */
async function createProduk(req, res) {
    try {
        const { nama_produk, harga_jual, stok = 0, stok_minimum = 10 } = req.body;

        // Validation
        if (!nama_produk || harga_jual === undefined) {
            return response.error(res, 'nama_produk and harga_jual are required', 400);
        }

        if (parseInt(harga_jual) < 0) {
            return response.error(res, 'harga_jual must be a positive number', 400);
        }

        let gambar_url = null;

        // Upload image if provided
        if (req.file) {
            const uploaded = await uploadFile(
                req.file.buffer,
                req.file.originalname,
                req.file.mimetype
            );

            if (uploaded) {
                gambar_url = uploaded.url;
            }
        }

        // Create product
        const [produk] = await db('produk')
            .insert({
                nama_produk,
                harga_jual: parseInt(harga_jual),
                gambar_url,
                stok: parseInt(stok),
                stok_minimum: parseInt(stok_minimum)
            })
            .returning('*');

        return response.created(res, produk, 'Product created successfully');

    } catch (error) {
        console.error('Create produk error:', error);
        return response.serverError(res, 'Failed to create product');
    }
}

/**
 * Update product (Admin only)
 * PUT /api/produk/:id
 */
async function updateProduk(req, res) {
    try {
        const { id } = req.params;
        const { nama_produk, harga_jual, stok, stok_minimum } = req.body;

        // Check if product exists
        const existingProduk = await db('produk').where('id', id).first();
        if (!existingProduk) {
            return response.notFound(res, 'Product not found');
        }

        const updates = { updated_at: new Date() };

        if (nama_produk) updates.nama_produk = nama_produk;
        if (harga_jual !== undefined) updates.harga_jual = parseInt(harga_jual);
        if (stok !== undefined) updates.stok = parseInt(stok);
        if (stok_minimum !== undefined) updates.stok_minimum = parseInt(stok_minimum);

        // Handle image upload
        if (req.file) {
            // Delete old image
            if (existingProduk.gambar_url) {
                const oldPath = getFilePathFromUrl(existingProduk.gambar_url);
                if (oldPath) {
                    await deleteFile(oldPath);
                }
            }

            // Upload new image
            const uploaded = await uploadFile(
                req.file.buffer,
                req.file.originalname,
                req.file.mimetype
            );

            if (uploaded) {
                updates.gambar_url = uploaded.url;
            }
        }

        // Update product
        const [updatedProduk] = await db('produk')
            .where('id', id)
            .update(updates)
            .returning('*');

        return response.success(res, updatedProduk, 'Product updated successfully');

    } catch (error) {
        console.error('Update produk error:', error);
        return response.serverError(res, 'Failed to update product');
    }
}

/**
 * Delete product (Admin only)
 * DELETE /api/produk/:id
 */
async function deleteProduk(req, res) {
    try {
        const { id } = req.params;

        // Check if product exists
        const produk = await db('produk').where('id', id).first();
        if (!produk) {
            return response.notFound(res, 'Product not found');
        }

        // Check if product has orders
        const orderItems = await db('order_items').where('produk_id', id).first();
        if (orderItems) {
            return response.error(res, 'Cannot delete product with existing orders', 400);
        }

        // Delete image from storage
        if (produk.gambar_url) {
            const filePath = getFilePathFromUrl(produk.gambar_url);
            if (filePath) {
                await deleteFile(filePath);
            }
        }

        // Delete product
        await db('produk').where('id', id).del();

        return response.success(res, null, 'Product deleted successfully');

    } catch (error) {
        console.error('Delete produk error:', error);
        return response.serverError(res, 'Failed to delete product');
    }
}

module.exports = {
    getAllProduk,
    getProdukById,
    createProduk,
    updateProduk,
    deleteProduk
};
