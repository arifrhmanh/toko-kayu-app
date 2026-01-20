const db = require('../config/database');
const response = require('../utils/response');

/**
 * Get all keuangan records
 * GET /api/keuangan
 */
async function getAllKeuangan(req, res) {
    try {
        const { page = 1, limit = 50, jenis, start_date, end_date } = req.query;
        const offset = (parseInt(page) - 1) * parseInt(limit);

        let query = db('keuangan').orderBy('tanggal', 'desc');
        let countQuery = db('keuangan');

        // Filter by type
        if (jenis && ['pemasukan', 'pengeluaran'].includes(jenis)) {
            query = query.where('jenis', jenis);
            countQuery = countQuery.where('jenis', jenis);
        }

        // Date range filter
        if (start_date) {
            query = query.where('tanggal', '>=', start_date);
            countQuery = countQuery.where('tanggal', '>=', start_date);
        }

        if (end_date) {
            query = query.where('tanggal', '<=', end_date);
            countQuery = countQuery.where('tanggal', '<=', end_date);
        }

        // Get total count
        const [{ count }] = await countQuery.count('id as count');

        // Get paginated data
        const keuangan = await query.limit(parseInt(limit)).offset(offset);

        return response.paginated(res, keuangan, {
            page: parseInt(page),
            limit: parseInt(limit),
            total: parseInt(count)
        });

    } catch (error) {
        console.error('Get all keuangan error:', error);
        return response.serverError(res, 'Failed to get finance records');
    }
}

/**
 * Get keuangan summary (saldo, pemasukan, pengeluaran, profit)
 * GET /api/keuangan/summary
 */
async function getKeuanganSummary(req, res) {
    try {
        const { start_date, end_date } = req.query;

        // Base queries
        let pemasukanQuery = db('keuangan').where('jenis', 'pemasukan');
        let pengeluaranQuery = db('keuangan').where('jenis', 'pengeluaran');

        // Date range filter
        if (start_date) {
            pemasukanQuery = pemasukanQuery.where('tanggal', '>=', start_date);
            pengeluaranQuery = pengeluaranQuery.where('tanggal', '>=', start_date);
        }

        if (end_date) {
            pemasukanQuery = pemasukanQuery.where('tanggal', '<=', end_date);
            pengeluaranQuery = pengeluaranQuery.where('tanggal', '<=', end_date);
        }

        // Get sums
        const [pemasukan] = await pemasukanQuery.sum('jumlah as total');
        const [pengeluaran] = await pengeluaranQuery.sum('jumlah as total');

        const totalPemasukan = parseInt(pemasukan.total) || 0;
        const totalPengeluaran = parseInt(pengeluaran.total) || 0;
        const saldo = totalPemasukan - totalPengeluaran;

        // Get profit from sales (order-related income) minus kulakan expenses
        let profitQuery = db('keuangan')
            .select(
                db.raw(`
          COALESCE(SUM(CASE WHEN jenis = 'pemasukan' AND reference_type = 'order' THEN jumlah ELSE 0 END), 0) as penjualan,
          COALESCE(SUM(CASE WHEN jenis = 'pengeluaran' AND reference_type = 'kulakan' THEN jumlah ELSE 0 END), 0) as kulakan
        `)
            );

        if (start_date) {
            profitQuery = profitQuery.where('tanggal', '>=', start_date);
        }

        if (end_date) {
            profitQuery = profitQuery.where('tanggal', '<=', end_date);
        }

        const [profitResult] = await profitQuery;
        const penjualan = parseInt(profitResult.penjualan) || 0;
        const kulakanTotal = parseInt(profitResult.kulakan) || 0;
        const profit = penjualan - kulakanTotal;

        return response.success(res, {
            pemasukan: totalPemasukan,
            pengeluaran: totalPengeluaran,
            saldo,
            penjualan,
            kulakan: kulakanTotal,
            profit
        });

    } catch (error) {
        console.error('Get keuangan summary error:', error);
        return response.serverError(res, 'Failed to get finance summary');
    }
}

/**
 * Create keuangan record (manual entry)
 * POST /api/keuangan
 */
async function createKeuangan(req, res) {
    try {
        const { jenis, jumlah, keterangan, tanggal } = req.body;

        // Validation
        if (!jenis || !['pemasukan', 'pengeluaran'].includes(jenis)) {
            return response.error(res, 'jenis must be either "pemasukan" or "pengeluaran"', 400);
        }

        if (!jumlah || parseInt(jumlah) <= 0) {
            return response.error(res, 'jumlah must be a positive number', 400);
        }

        if (!keterangan) {
            return response.error(res, 'keterangan is required', 400);
        }

        // Create record
        const [keuangan] = await db('keuangan')
            .insert({
                jenis,
                jumlah: parseInt(jumlah),
                keterangan,
                reference_type: 'manual',
                tanggal: tanggal ? new Date(tanggal) : new Date()
            })
            .returning('*');

        return response.created(res, keuangan, 'Finance record created successfully');

    } catch (error) {
        console.error('Create keuangan error:', error);
        return response.serverError(res, 'Failed to create finance record');
    }
}

/**
 * Update keuangan record (only manual entries)
 * PUT /api/keuangan/:id
 */
async function updateKeuangan(req, res) {
    try {
        const { id } = req.params;
        const { jenis, jumlah, keterangan, tanggal } = req.body;

        // Check if record exists and is manual
        const existingKeuangan = await db('keuangan').where('id', id).first();

        if (!existingKeuangan) {
            return response.notFound(res, 'Finance record not found');
        }

        if (existingKeuangan.reference_type !== 'manual') {
            return response.error(res, 'Cannot edit auto-generated finance records', 400);
        }

        const updates = { updated_at: new Date() };

        if (jenis && ['pemasukan', 'pengeluaran'].includes(jenis)) {
            updates.jenis = jenis;
        }

        if (jumlah !== undefined) {
            if (parseInt(jumlah) <= 0) {
                return response.error(res, 'jumlah must be a positive number', 400);
            }
            updates.jumlah = parseInt(jumlah);
        }

        if (keterangan) {
            updates.keterangan = keterangan;
        }

        if (tanggal) {
            updates.tanggal = new Date(tanggal);
        }

        // Update record
        const [updatedKeuangan] = await db('keuangan')
            .where('id', id)
            .update(updates)
            .returning('*');

        return response.success(res, updatedKeuangan, 'Finance record updated successfully');

    } catch (error) {
        console.error('Update keuangan error:', error);
        return response.serverError(res, 'Failed to update finance record');
    }
}

/**
 * Delete keuangan record (only manual entries)
 * DELETE /api/keuangan/:id
 */
async function deleteKeuangan(req, res) {
    try {
        const { id } = req.params;

        // Check if record exists and is manual
        const keuangan = await db('keuangan').where('id', id).first();

        if (!keuangan) {
            return response.notFound(res, 'Finance record not found');
        }

        if (keuangan.reference_type !== 'manual') {
            return response.error(res, 'Cannot delete auto-generated finance records', 400);
        }

        // Delete record
        await db('keuangan').where('id', id).del();

        return response.success(res, null, 'Finance record deleted successfully');

    } catch (error) {
        console.error('Delete keuangan error:', error);
        return response.serverError(res, 'Failed to delete finance record');
    }
}

module.exports = {
    getAllKeuangan,
    getKeuanganSummary,
    createKeuangan,
    updateKeuangan,
    deleteKeuangan
};
