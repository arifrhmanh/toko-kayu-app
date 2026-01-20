const db = require('../config/database');
const response = require('../utils/response');
const midtransService = require('../services/midtrans.service');
const notificationService = require('../services/notification.service');

/**
 * Get all orders
 * GET /api/order
 * Admin: gets all orders
 * Customer: gets their own orders only
 */
async function getAllOrders(req, res) {
    try {
        const { page = 1, limit = 20, status, start_date, end_date } = req.query;
        const offset = (parseInt(page) - 1) * parseInt(limit);
        const isAdmin = req.user.role === 'admin';

        let query = db('orders')
            .select(
                'orders.*',
                'users.username',
                'users.nama_lengkap',
                'alamat.kota',
                'alamat.kecamatan',
                'alamat.kelurahan',
                'alamat.detail_alamat'
            )
            .leftJoin('users', 'orders.user_id', 'users.id')
            .leftJoin('alamat', 'orders.alamat_id', 'alamat.id')
            .orderBy('orders.created_at', 'desc');

        let countQuery = db('orders');

        // Customer can only see their own orders
        if (!isAdmin) {
            query = query.where('orders.user_id', req.user.id);
            countQuery = countQuery.where('user_id', req.user.id);
        }

        // Filter by status
        if (status) {
            query = query.where('orders.status', status);
            countQuery = countQuery.where('status', status);
        }

        // Date range filter
        if (start_date) {
            query = query.where('orders.created_at', '>=', start_date);
            countQuery = countQuery.where('created_at', '>=', start_date);
        }

        if (end_date) {
            query = query.where('orders.created_at', '<=', end_date);
            countQuery = countQuery.where('created_at', '<=', end_date);
        }

        // Get total count
        const [{ count }] = await countQuery.count('id as count');

        // Get paginated data
        const orders = await query.limit(parseInt(limit)).offset(offset);

        // Get order items for each order
        for (let order of orders) {
            order.items = await db('order_items')
                .select(
                    'order_items.*',
                    'produk.nama_produk',
                    'produk.gambar_url'
                )
                .leftJoin('produk', 'order_items.produk_id', 'produk.id')
                .where('order_items.order_id', order.id);
        }

        return response.paginated(res, orders, {
            page: parseInt(page),
            limit: parseInt(limit),
            total: parseInt(count)
        });

    } catch (error) {
        console.error('Get all orders error:', error);
        return response.serverError(res, 'Failed to get orders');
    }
}

/**
 * Get order by ID
 * GET /api/order/:id
 */
async function getOrderById(req, res) {
    try {
        const { id } = req.params;
        const isAdmin = req.user.role === 'admin';

        let query = db('orders')
            .select(
                'orders.*',
                'users.username',
                'users.nama_lengkap',
                'users.no_hp',
                'alamat.provinsi',
                'alamat.kota',
                'alamat.kecamatan',
                'alamat.kelurahan',
                'alamat.detail_alamat'
            )
            .leftJoin('users', 'orders.user_id', 'users.id')
            .leftJoin('alamat', 'orders.alamat_id', 'alamat.id')
            .where('orders.id', id);

        // Customer can only see their own orders
        if (!isAdmin) {
            query = query.where('orders.user_id', req.user.id);
        }

        const order = await query.first();

        if (!order) {
            return response.notFound(res, 'Order not found');
        }

        // Get order items
        order.items = await db('order_items')
            .select(
                'order_items.*',
                'produk.nama_produk',
                'produk.gambar_url'
            )
            .leftJoin('produk', 'order_items.produk_id', 'produk.id')
            .where('order_items.order_id', order.id);

        return response.success(res, order);

    } catch (error) {
        console.error('Get order by id error:', error);
        return response.serverError(res, 'Failed to get order');
    }
}

/**
 * Create new order (Customer only)
 * POST /api/order
 */
async function createOrder(req, res) {
    const trx = await db.transaction();

    try {
        const { alamat_id, items } = req.body;
        const userId = req.user.id;

        // Validation
        if (!alamat_id) {
            await trx.rollback();
            return response.error(res, 'alamat_id is required', 400);
        }

        if (!items || !Array.isArray(items) || items.length === 0) {
            await trx.rollback();
            return response.error(res, 'items array is required and must not be empty', 400);
        }

        // Verify alamat belongs to user
        const alamat = await trx('alamat')
            .where('id', alamat_id)
            .where('user_id', userId)
            .first();

        if (!alamat) {
            await trx.rollback();
            return response.error(res, 'Invalid address', 400);
        }

        // Validate and calculate items
        let totalHarga = 0;
        const orderItems = [];

        for (const item of items) {
            if (!item.produk_id || !item.jumlah || item.jumlah <= 0) {
                await trx.rollback();
                return response.error(res, 'Each item must have produk_id and jumlah > 0', 400);
            }

            const produk = await trx('produk').where('id', item.produk_id).first();

            if (!produk) {
                await trx.rollback();
                return response.error(res, `Product ${item.produk_id} not found`, 400);
            }

            if (produk.stok < item.jumlah) {
                await trx.rollback();
                return response.error(res, `Insufficient stock for ${produk.nama_produk}. Available: ${produk.stok}`, 400);
            }

            const subtotal = produk.harga_jual * item.jumlah;
            totalHarga += subtotal;

            orderItems.push({
                produk_id: item.produk_id,
                jumlah: item.jumlah,
                harga_satuan: produk.harga_jual,
                subtotal,
                nama_produk: produk.nama_produk
            });
        }

        // Create order
        const [order] = await trx('orders')
            .insert({
                user_id: userId,
                alamat_id,
                status: 'pending',
                total_harga: totalHarga
            })
            .returning('*');

        // Create order items
        for (const item of orderItems) {
            await trx('order_items').insert({
                order_id: order.id,
                produk_id: item.produk_id,
                jumlah: item.jumlah,
                harga_satuan: item.harga_satuan,
                subtotal: item.subtotal
            });
        }

        await trx.commit();

        // Create Midtrans payment
        const payment = await midtransService.createOrderPayment(
            order,
            req.user,
            orderItems
        );

        // Get complete order data
        const completeOrder = await db('orders')
            .where('id', order.id)
            .first();

        completeOrder.items = orderItems;
        completeOrder.payment = payment;

        return response.created(res, completeOrder, 'Order created successfully');

    } catch (error) {
        await trx.rollback();
        console.error('Create order error:', error);
        return response.serverError(res, 'Failed to create order');
    }
}

/**
 * Update order status (Admin only)
 * PUT /api/order/:id/status
 * 
 * Status flow: pending → dibayar → dikemas → dikirim → selesai
 * - When status changes to "dikirim": decrease product stock
 */
async function updateOrderStatus(req, res) {
    const trx = await db.transaction();

    try {
        const { id } = req.params;
        const { status } = req.body;

        const validStatuses = ['pending', 'dibayar', 'dikemas', 'dikirim', 'selesai'];

        if (!status || !validStatuses.includes(status)) {
            await trx.rollback();
            return response.error(res, `Invalid status. Must be one of: ${validStatuses.join(', ')}`, 400);
        }

        // Get order
        const order = await trx('orders').where('id', id).first();

        if (!order) {
            await trx.rollback();
            return response.notFound(res, 'Order not found');
        }

        const oldStatus = order.status;

        // Validate status flow
        const statusOrder = ['pending', 'dibayar', 'dikemas', 'dikirim', 'selesai'];
        const currentIndex = statusOrder.indexOf(oldStatus);
        const newIndex = statusOrder.indexOf(status);

        if (newIndex < currentIndex) {
            await trx.rollback();
            return response.error(res, `Cannot change status from ${oldStatus} to ${status}`, 400);
        }

        // When changing to "dikirim", decrease stock
        if (status === 'dikirim' && oldStatus !== 'dikirim') {
            const orderItems = await trx('order_items').where('order_id', id);

            for (const item of orderItems) {
                const produk = await trx('produk').where('id', item.produk_id).first();

                if (produk.stok < item.jumlah) {
                    await trx.rollback();
                    return response.error(res, `Insufficient stock for product. Please update stock first.`, 400);
                }

                await trx('produk')
                    .where('id', item.produk_id)
                    .decrement('stok', item.jumlah)
                    .update({ updated_at: new Date() });
            }
        }

        // Update order status
        const [updatedOrder] = await trx('orders')
            .where('id', id)
            .update({
                status,
                updated_at: new Date()
            })
            .returning('*');

        await trx.commit();

        // Send notification to customer
        if (oldStatus !== status) {
            await notificationService.notifyOrderStatusChange(order, oldStatus, status);
        }

        return response.success(res, updatedOrder, 'Order status updated successfully');

    } catch (error) {
        await trx.rollback();
        console.error('Update order status error:', error);
        return response.serverError(res, 'Failed to update order status');
    }
}

/**
 * Cancel order (Customer only, only for pending orders)
 * DELETE /api/order/:id
 */
async function cancelOrder(req, res) {
    try {
        const { id } = req.params;
        const userId = req.user.id;

        const order = await db('orders')
            .where('id', id)
            .where('user_id', userId)
            .first();

        if (!order) {
            return response.notFound(res, 'Order not found');
        }

        if (order.status !== 'pending') {
            return response.error(res, 'Only pending orders can be cancelled', 400);
        }

        // Delete order items
        await db('order_items').where('order_id', id).del();

        // Delete order
        await db('orders').where('id', id).del();

        return response.success(res, null, 'Order cancelled successfully');

    } catch (error) {
        console.error('Cancel order error:', error);
        return response.serverError(res, 'Failed to cancel order');
    }
}

module.exports = {
    getAllOrders,
    getOrderById,
    createOrder,
    updateOrderStatus,
    cancelOrder
};
