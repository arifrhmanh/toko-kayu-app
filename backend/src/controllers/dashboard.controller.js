const db = require('../config/database');
const response = require('../utils/response');

/**
 * Get sales summary with filter
 * GET /api/dashboard/sales
 */
async function getSalesSummary(req, res) {
    try {
        const { filter = 'day', date } = req.query;

        // Determine date range based on filter
        let startDate, endDate;
        const baseDate = date ? new Date(date) : new Date();

        switch (filter) {
            case 'day':
                startDate = new Date(baseDate.setHours(0, 0, 0, 0));
                endDate = new Date(baseDate.setHours(23, 59, 59, 999));
                break;
            case 'month':
                startDate = new Date(baseDate.getFullYear(), baseDate.getMonth(), 1);
                endDate = new Date(baseDate.getFullYear(), baseDate.getMonth() + 1, 0, 23, 59, 59, 999);
                break;
            case 'year':
                startDate = new Date(baseDate.getFullYear(), 0, 1);
                endDate = new Date(baseDate.getFullYear(), 11, 31, 23, 59, 59, 999);
                break;
            default:
                startDate = new Date(new Date().setHours(0, 0, 0, 0));
                endDate = new Date(new Date().setHours(23, 59, 59, 999));
        }

        // Get total sales (orders with status >= dibayar)
        const salesQuery = await db('orders')
            .whereIn('status', ['dibayar', 'dikemas', 'dikirim', 'selesai'])
            .where('created_at', '>=', startDate)
            .where('created_at', '<=', endDate)
            .select(
                db.raw('COUNT(*) as total_orders'),
                db.raw('COALESCE(SUM(total_harga), 0) as total_sales')
            )
            .first();

        // Get daily breakdown for chart (last 7 days for day, last 12 months for year, etc.)
        let chartData = [];

        if (filter === 'day') {
            // Hourly breakdown for current day
            const hourlyData = await db('orders')
                .whereIn('status', ['dibayar', 'dikemas', 'dikirim', 'selesai'])
                .where('created_at', '>=', startDate)
                .where('created_at', '<=', endDate)
                .select(
                    db.raw("EXTRACT(HOUR FROM created_at) as hour"),
                    db.raw('COUNT(*) as orders'),
                    db.raw('COALESCE(SUM(total_harga), 0) as sales')
                )
                .groupByRaw("EXTRACT(HOUR FROM created_at)")
                .orderByRaw("EXTRACT(HOUR FROM created_at)");

            chartData = hourlyData.map(d => ({
                label: `${d.hour}:00`,
                orders: parseInt(d.orders),
                sales: parseInt(d.sales)
            }));

        } else if (filter === 'month') {
            // Daily breakdown for current month
            const dailyData = await db('orders')
                .whereIn('status', ['dibayar', 'dikemas', 'dikirim', 'selesai'])
                .where('created_at', '>=', startDate)
                .where('created_at', '<=', endDate)
                .select(
                    db.raw("EXTRACT(DAY FROM created_at) as day"),
                    db.raw('COUNT(*) as orders'),
                    db.raw('COALESCE(SUM(total_harga), 0) as sales')
                )
                .groupByRaw("EXTRACT(DAY FROM created_at)")
                .orderByRaw("EXTRACT(DAY FROM created_at)");

            chartData = dailyData.map(d => ({
                label: `${d.day}`,
                orders: parseInt(d.orders),
                sales: parseInt(d.sales)
            }));

        } else if (filter === 'year') {
            // Monthly breakdown for current year
            const monthlyData = await db('orders')
                .whereIn('status', ['dibayar', 'dikemas', 'dikirim', 'selesai'])
                .where('created_at', '>=', startDate)
                .where('created_at', '<=', endDate)
                .select(
                    db.raw("EXTRACT(MONTH FROM created_at) as month"),
                    db.raw('COUNT(*) as orders'),
                    db.raw('COALESCE(SUM(total_harga), 0) as sales')
                )
                .groupByRaw("EXTRACT(MONTH FROM created_at)")
                .orderByRaw("EXTRACT(MONTH FROM created_at)");

            const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
            chartData = monthlyData.map(d => ({
                label: monthNames[parseInt(d.month) - 1],
                orders: parseInt(d.orders),
                sales: parseInt(d.sales)
            }));
        }

        return response.success(res, {
            filter,
            start_date: startDate,
            end_date: endDate,
            summary: {
                total_orders: parseInt(salesQuery.total_orders),
                total_sales: parseInt(salesQuery.total_sales)
            },
            chart: chartData
        });

    } catch (error) {
        console.error('Get sales summary error:', error);
        return response.serverError(res, 'Failed to get sales summary');
    }
}

/**
 * Get low stock products
 * GET /api/dashboard/low-stock
 */
async function getLowStockProducts(req, res) {
    try {
        const { limit = 10 } = req.query;

        const products = await db('produk')
            .whereRaw('stok < stok_minimum')
            .orderBy('stok', 'asc')
            .limit(parseInt(limit));

        return response.success(res, products);

    } catch (error) {
        console.error('Get low stock products error:', error);
        return response.serverError(res, 'Failed to get low stock products');
    }
}

/**
 * Get dashboard overview
 * GET /api/dashboard/overview
 */
async function getDashboardOverview(req, res) {
    try {
        // Get counts
        const [productCount] = await db('produk').count('id as count');
        const [orderCount] = await db('orders')
            .whereIn('status', ['dibayar', 'dikemas', 'dikirim'])
            .count('id as count');
        const [customerCount] = await db('users')
            .where('role', 'customer')
            .count('id as count');
        const [lowStockCount] = await db('produk')
            .whereRaw('stok < stok_minimum')
            .count('id as count');

        // Get today's sales
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        const [todaySales] = await db('orders')
            .whereIn('status', ['dibayar', 'dikemas', 'dikirim', 'selesai'])
            .where('created_at', '>=', today)
            .where('created_at', '<', tomorrow)
            .select(
                db.raw('COUNT(*) as orders'),
                db.raw('COALESCE(SUM(total_harga), 0) as sales')
            );

        // Get Finance Summary
        const [totalPemasukan] = await db('keuangan')
            .where('jenis', 'pemasukan')
            .sum('jumlah as total');

        const [totalPengeluaran] = await db('keuangan')
            .where('jenis', 'pengeluaran')
            .sum('jumlah as total');

        const pemasukan = parseInt(totalPemasukan.total) || 0;
        const pengeluaran = parseInt(totalPengeluaran.total) || 0;
        const saldo = pemasukan - pengeluaran;

        // Get pending orders count
        const [pendingOrders] = await db('orders')
            .where('status', 'dibayar')
            .count('id as count');

        return response.success(res, {
            products: parseInt(productCount.count),
            active_orders: parseInt(orderCount.count),
            customers: parseInt(customerCount.count),
            low_stock: parseInt(lowStockCount.count),
            today: {
                orders: parseInt(todaySales.orders),
                sales: parseInt(todaySales.sales)
            },
            pending_orders: parseInt(pendingOrders.count),
            saldo: saldo,
            total_pemasukan: pemasukan,
            total_pengeluaran: pengeluaran
        });

    } catch (error) {
        console.error('Get dashboard overview error:', error);
        return response.serverError(res, 'Failed to get dashboard overview');
    }
}

module.exports = {
    getSalesSummary,
    getLowStockProducts,
    getDashboardOverview
};
