const {
    createPaymentToken,
    getTransactionStatus,
    verifySignature,
    isTransactionSuccess,
    isTransactionPending,
    isTransactionFailed
} = require('../config/midtrans');
const db = require('../config/database');
const notificationService = require('./notification.service');

/**
 * Create payment for an order
 * @param {Object} order - Order object
 * @param {Object} user - User object
 * @param {Array} items - Order items
 * @returns {Promise<Object>}
 */
async function createOrderPayment(order, user, items) {
    const orderId = `ORDER-${order.id.substring(0, 8)}-${Date.now()}`;

    const customerDetails = {
        first_name: user.nama_lengkap,
        phone: user.no_hp || '',
        customer_id: user.id
    };

    const itemDetails = items.map(item => ({
        id: item.produk_id,
        price: item.harga_satuan,
        quantity: item.jumlah,
        name: item.nama_produk?.substring(0, 50) || 'Product'
    }));

    const result = await createPaymentToken({
        orderId,
        grossAmount: order.total_harga,
        customerDetails,
        itemDetails
    });

    if (result) {
        // Update order with Midtrans info
        await db('orders')
            .where('id', order.id)
            .update({
                midtrans_order_id: orderId,
                midtrans_token: result.token,
                midtrans_redirect_url: result.redirect_url,
                updated_at: new Date()
            });

        return {
            order_id: orderId,
            token: result.token,
            redirect_url: result.redirect_url
        };
    }

    return null;
}

/**
 * Handle Midtrans notification/callback
 * @param {Object} notification - Notification payload
 * @returns {Promise<Object>}
 */
async function handleNotification(notification) {
    const {
        order_id,
        transaction_status,
        fraud_status,
        gross_amount
    } = notification;

    // Verify signature
    if (!verifySignature(notification)) {
        console.warn('Invalid signature for order:', order_id);
        // Continue anyway for sandbox testing
    }

    // Find order by Midtrans order ID
    const order = await db('orders')
        .where('midtrans_order_id', order_id)
        .first();

    if (!order) {
        return { success: false, message: 'Order not found' };
    }

    let newStatus = order.status;

    if (isTransactionSuccess(transaction_status, fraud_status)) {
        newStatus = 'dibayar';

        // Add to keuangan (income)
        await db('keuangan').insert({
            jenis: 'pemasukan',
            jumlah: order.total_harga,
            keterangan: `Pembayaran order #${order_id}`,
            reference_id: order.id,
            reference_type: 'order',
            tanggal: new Date()
        });

        // Notify admin about new paid order
        const admins = await db('users').where('role', 'admin').select('id');
        for (const admin of admins) {
            await notificationService.createNotification({
                userId: admin.id,
                judul: 'Pesanan Baru Dibayar',
                pesan: `Pesanan #${order_id} telah dibayar. Total: Rp ${order.total_harga.toLocaleString('id-ID')}`,
                type: 'payment',
                referenceId: order.id
            });
        }

        // Notify customer
        await notificationService.createNotification({
            userId: order.user_id,
            judul: 'Pembayaran Berhasil',
            pesan: `Pembayaran untuk pesanan #${order_id} berhasil. Pesanan Anda sedang diproses.`,
            type: 'order_status',
            referenceId: order.id
        });

    } else if (isTransactionPending(transaction_status)) {
        newStatus = 'pending';
    } else if (isTransactionFailed(transaction_status)) {
        if (transaction_status === 'expire') {
            newStatus = 'expired';
        } else if (transaction_status === 'cancel' || transaction_status === 'deny') {
            newStatus = 'batal';
        }
        console.log(`Order ${order_id} status updated to: ${newStatus}`);
    }

    // Update order status
    if (newStatus !== order.status) {
        await db('orders')
            .where('id', order.id)
            .update({
                status: newStatus,
                updated_at: new Date()
            });
    }

    return { success: true, status: newStatus };
}

/**
 * Check and update order payment status
 * @param {string} orderId - Order ID
 * @returns {Promise<Object>}
 */
async function checkPaymentStatus(orderId) {
    if (!orderId) {
        return null;
    }

    const order = await db('orders')
        .where('id', orderId)
        .first();

    if (!order || !order.midtrans_order_id) {
        return null;
    }

    const status = await getTransactionStatus(order.midtrans_order_id);

    if (status) {
        return handleNotification(status);
    }

    return null;
}

module.exports = {
    createOrderPayment,
    handleNotification,
    checkPaymentStatus
};
