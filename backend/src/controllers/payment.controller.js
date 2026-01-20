const response = require('../utils/response');
const midtransService = require('../services/midtrans.service');
const db = require('../config/database');

/**
 * Create payment for an order
 * POST /api/payment/create
 */
async function createPayment(req, res) {
    try {
        const { order_id } = req.body;
        const userId = req.user.id;

        if (!order_id) {
            return response.error(res, 'order_id is required', 400);
        }

        // Get order
        const order = await db('orders')
            .where('id', order_id)
            .where('user_id', userId)
            .first();

        if (!order) {
            return response.notFound(res, 'Order not found');
        }

        if (order.status !== 'pending') {
            return response.error(res, 'Order is not pending payment', 400);
        }

        // Check if already has payment token
        if (order.midtrans_token) {
            return response.success(res, {
                order_id: order.midtrans_order_id,
                token: order.midtrans_token,
                redirect_url: order.midtrans_redirect_url
            }, 'Payment token already exists');
        }

        // Get order items
        const items = await db('order_items')
            .select('order_items.*', 'produk.nama_produk')
            .leftJoin('produk', 'order_items.produk_id', 'produk.id')
            .where('order_items.order_id', order_id);

        // Create payment
        const payment = await midtransService.createOrderPayment(order, req.user, items);

        if (!payment) {
            return response.serverError(res, 'Failed to create payment');
        }

        return response.success(res, payment, 'Payment created successfully');

    } catch (error) {
        console.error('Create payment error:', error);
        return response.serverError(res, 'Failed to create payment');
    }
}

/**
 * Handle Midtrans callback/webhook
 * POST /api/payment/callback
 */
async function handleCallback(req, res) {
    try {
        const notification = req.body;

        console.log('Midtrans callback received:', notification);

        const result = await midtransService.handleNotification(notification);

        if (result.success) {
            return res.status(200).json({ status: 'ok' });
        } else {
            return res.status(400).json({ status: 'error', message: result.message });
        }

    } catch (error) {
        console.error('Payment callback error:', error);
        return res.status(500).json({ status: 'error' });
    }
}

/**
 * Check payment status
 * GET /api/payment/status/:orderId
 */
async function checkStatus(req, res) {
    try {
        const { orderId } = req.params;
        const userId = req.user.id;
        const isAdmin = req.user.role === 'admin';

        // Get order
        let query = db('orders').where('id', orderId);
        if (!isAdmin) {
            query = query.where('user_id', userId);
        }

        const order = await query.first();

        if (!order) {
            return response.notFound(res, 'Order not found');
        }

        // Check status with Midtrans if pending
        if (order.status === 'pending' && order.midtrans_order_id) {
            await midtransService.checkPaymentStatus(orderId);

            // Refresh order data
            const updatedOrder = await db('orders').where('id', orderId).first();
            return response.success(res, { status: updatedOrder.status });
        }

        return response.success(res, { status: order.status });

    } catch (error) {
        console.error('Check payment status error:', error);
        return response.serverError(res, 'Failed to check payment status');
    }
}

/**
 * Handle finished payment redirect
 * GET /api/payment/finish
 */
async function handleFinish(req, res) {
    const html = `
    <!DOCTYPE html>
    <html>
    <head>
        <title>Pembayaran Berhasil</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            body { font-family: sans-serif; text-align: center; padding: 40px; }
            .success { color: #4CAF50; }
            button { background: #4CAF50; color: white; border: none; padding: 10px 20px; border-radius: 5px; font-size: 16px; cursor: pointer; }
        </style>
    </head>
    <body>
        <h1 class="success">Pembayaran Berhasil!</h1>
        <p>Terima kasih telah melakukan pembayaran.</p>
        <p>Anda dapat menutup halaman ini dan kembali ke aplikasi.</p>
        <br>
        <button onclick="window.close()">Tutup Halaman</button>
        <script>
            // Try to close automatically after 3 seconds
            setTimeout(function() {
                window.close();
            }, 3000);
        </script>
    </body>
    </html>
    `;
    res.send(html);
}

/**
 * Handle unfinished payment redirect
 * GET /api/payment/unfinish
 */
async function handleUnfinish(req, res) {
    const html = `
    <!DOCTYPE html>
    <html>
    <head>
        <title>Pembayaran Belum Selesai</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            body { font-family: sans-serif; text-align: center; padding: 40px; }
            .pending { color: #FF9800; }
            button { background: #FF9800; color: white; border: none; padding: 10px 20px; border-radius: 5px; font-size: 16px; cursor: pointer; }
        </style>
    </head>
    <body>
        <h1 class="pending">Pembayaran Belum Selesai</h1>
        <p>Silakan selesaikan pembayaran Anda atau coba lagi nanti.</p>
        <br>
        <button onclick="window.close()">Kembali ke Aplikasi</button>
    </body>
    </html>
    `;
    res.send(html);
}

/**
 * Handle error payment redirect
 * GET /api/payment/error
 */
async function handleError(req, res) {
    const html = `
    <!DOCTYPE html>
    <html>
    <head>
        <title>Pembayaran Gagal</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            body { font-family: sans-serif; text-align: center; padding: 40px; }
            .error { color: #F44336; }
            button { background: #F44336; color: white; border: none; padding: 10px 20px; border-radius: 5px; font-size: 16px; cursor: pointer; }
        </style>
    </head>
    <body>
        <h1 class="error">Pembayaran Gagal</h1>
        <p>Terjadi kesalahan saat memproses pembayaran.</p>
        <br>
        <button onclick="window.close()">Kembali ke Aplikasi</button>
    </body>
    </html>
    `;
    res.send(html);
}

module.exports = {
    createPayment,
    handleCallback,
    checkStatus,
    handleFinish,
    handleUnfinish,
    handleError
};
