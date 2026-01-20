const db = require('../config/database');
const response = require('../utils/response');

/**
 * Get all kulakan records
 * GET /api/kulakan
 */
async function getAllKulakan(req, res) {
    try {
        const { page = 1, limit = 20, produk_id, start_date, end_date } = req.query;
        const offset = (parseInt(page) - 1) * parseInt(limit);

        let query = db('kulakan')
            .select(
                'kulakan.*',
                'produk.nama_produk',
                'produk.gambar_url'
            )
            .leftJoin('produk', 'kulakan.produk_id', 'produk.id')
            .orderBy('kulakan.tanggal', 'desc');

        let countQuery = db('kulakan');

        // Filter by product
        if (produk_id) {
            query = query.where('kulakan.produk_id', produk_id);
            countQuery = countQuery.where('produk_id', produk_id);
        }

        // Date range filter
        if (start_date) {
            query = query.where('kulakan.tanggal', '>=', start_date);
            countQuery = countQuery.where('tanggal', '>=', start_date);
        }

        if (end_date) {
            query = query.where('kulakan.tanggal', '<=', end_date);
            countQuery = countQuery.where('tanggal', '<=', end_date);
        }

        // Get total count
        const [{ count }] = await countQuery.count('id as count');

        // Get paginated data
        const kulakan = await query.limit(parseInt(limit)).offset(offset);

        return response.paginated(res, kulakan, {
            page: parseInt(page),
            limit: parseInt(limit),
            total: parseInt(count)
        });

    } catch (error) {
        console.error('Get all kulakan error:', error);
        return response.serverError(res, 'Failed to get kulakan records');
    }
}

/**
 * Get kulakan by ID
 * GET /api/kulakan/:id
 */
async function getKulakanById(req, res) {
    try {
        const { id } = req.params;

        const kulakan = await db('kulakan')
            .select(
                'kulakan.*',
                'produk.nama_produk',
                'produk.gambar_url'
            )
            .leftJoin('produk', 'kulakan.produk_id', 'produk.id')
            .where('kulakan.id', id)
            .first();

        if (!kulakan) {
            return response.notFound(res, 'Kulakan record not found');
        }

        return response.success(res, kulakan);

    } catch (error) {
        console.error('Get kulakan by id error:', error);
        return response.serverError(res, 'Failed to get kulakan record');
    }
}

/**
 * Create new kulakan (Admin only)
 * POST /api/kulakan
 * 
 * This will:
 * 1. Create kulakan record
 * 2. Increase product stock
 * 3. Create keuangan record (pengeluaran)
 */
async function createKulakan(req, res) {
    const trx = await db.transaction();

    try {
        const { produk_id, jumlah_karung, harga_per_karung, tanggal } = req.body;

        // Validation
        if (!produk_id || !jumlah_karung || !harga_per_karung) {
            await trx.rollback();
            return response.error(res, 'produk_id, jumlah_karung, and harga_per_karung are required', 400);
        }

        if (parseInt(jumlah_karung) <= 0) {
            await trx.rollback();
            return response.error(res, 'jumlah_karung must be greater than 0', 400);
        }

        if (parseInt(harga_per_karung) < 0) {
            await trx.rollback();
            return response.error(res, 'harga_per_karung must be a positive number', 400);
        }

        // Check if product exists
        const produk = await trx('produk').where('id', produk_id).first();
        if (!produk) {
            await trx.rollback();
            return response.notFound(res, 'Product not found');
        }

        const total_harga = parseInt(jumlah_karung) * parseInt(harga_per_karung);

        // 1. Create kulakan record
        const [kulakan] = await trx('kulakan')
            .insert({
                produk_id,
                jumlah_karung: parseInt(jumlah_karung),
                harga_per_karung: parseInt(harga_per_karung),
                total_harga,
                tanggal: tanggal ? new Date(tanggal) : new Date()
            })
            .returning('*');

        // 2. Increase product stock
        await trx('produk')
            .where('id', produk_id)
            .increment('stok', parseInt(jumlah_karung))
            .update({ updated_at: new Date() });

        // 3. Create keuangan record (pengeluaran)
        await trx('keuangan').insert({
            jenis: 'pengeluaran',
            jumlah: total_harga,
            keterangan: `Kulakan ${produk.nama_produk} - ${jumlah_karung} karung @ Rp ${parseInt(harga_per_karung).toLocaleString('id-ID')}`,
            reference_id: kulakan.id,
            reference_type: 'kulakan',
            tanggal: tanggal ? new Date(tanggal) : new Date()
        });

        await trx.commit();

        // Get updated product stock
        const updatedProduk = await db('produk').where('id', produk_id).first();

        return response.created(res, {
            kulakan: {
                ...kulakan,
                nama_produk: produk.nama_produk
            },
            new_stock: updatedProduk.stok
        }, 'Kulakan created successfully');

    } catch (error) {
        await trx.rollback();
        console.error('Create kulakan error:', error);
        return response.serverError(res, 'Failed to create kulakan record');
    }
}

/**
 * Delete kulakan (Admin only)
 * DELETE /api/kulakan/:id
 * 
 * Note: This will also reverse the stock and keuangan changes
 */
async function deleteKulakan(req, res) {
    const trx = await db.transaction();

    try {
        const { id } = req.params;

        // Get kulakan record
        const kulakan = await trx('kulakan').where('id', id).first();
        if (!kulakan) {
            await trx.rollback();
            return response.notFound(res, 'Kulakan record not found');
        }

        // Check if product still exists
        const produk = await trx('produk').where('id', kulakan.produk_id).first();

        if (produk) {
            // Decrease stock (but not below 0)
            const newStock = Math.max(0, produk.stok - kulakan.jumlah_karung);
            await trx('produk')
                .where('id', kulakan.produk_id)
                .update({ stok: newStock, updated_at: new Date() });
        }

        // Delete related keuangan record
        await trx('keuangan')
            .where('reference_id', id)
            .where('reference_type', 'kulakan')
            .del();

        // Delete kulakan
        await trx('kulakan').where('id', id).del();

        await trx.commit();

        return response.success(res, null, 'Kulakan deleted successfully');

    } catch (error) {
        await trx.rollback();
        console.error('Delete kulakan error:', error);
        return response.serverError(res, 'Failed to delete kulakan record');
    }
}

module.exports = {
    getAllKulakan,
    getKulakanById,
    createKulakan,
    deleteKulakan
};
