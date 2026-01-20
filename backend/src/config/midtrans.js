const axios = require('axios');

const MIDTRANS_BASE_URL = process.env.MIDTRANS_IS_PRODUCTION === 'true'
    ? 'https://app.midtrans.com/snap/v1'
    : 'https://app.sandbox.midtrans.com/snap/v1';

const MIDTRANS_API_URL = process.env.MIDTRANS_IS_PRODUCTION === 'true'
    ? 'https://api.midtrans.com/v2'
    : 'https://api.sandbox.midtrans.com/v2';

const serverKey = process.env.MIDTRANS_SERVER_KEY;

/**
 * Create Midtrans payment token
 * @param {Object} params - Payment parameters
 * @param {string} params.orderId - Unique order ID
 * @param {number} params.grossAmount - Total amount
 * @param {Object} params.customerDetails - Customer information
 * @returns {Promise<{token: string, redirect_url: string} | null>}
 */
async function createPaymentToken(params) {
    try {
        const { orderId, grossAmount, customerDetails, itemDetails } = params;

        const payload = {
            transaction_details: {
                order_id: orderId,
                gross_amount: grossAmount
            },
            customer_details: customerDetails,
            item_details: itemDetails,
            callbacks: {
                finish: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/api/payment/finish`,
                unfinish: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/api/payment/unfinish`,
                error: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/api/payment/error`
            }
        };

        const authString = Buffer.from(`${serverKey}:`).toString('base64');

        const response = await axios.post(`${MIDTRANS_BASE_URL}/transactions`, payload, {
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': `Basic ${authString}`
            }
        });

        return {
            token: response.data.token,
            redirect_url: response.data.redirect_url
        };
    } catch (error) {
        console.error('Midtrans create token error:', error.response?.data || error.message);
        return null;
    }
}

/**
 * Get transaction status from Midtrans
 * @param {string} orderId - Order ID
 * @returns {Promise<Object | null>}
 */
async function getTransactionStatus(orderId) {
    try {
        const authString = Buffer.from(`${serverKey}:`).toString('base64');

        const response = await axios.get(`${MIDTRANS_API_URL}/${orderId}/status`, {
            headers: {
                'Accept': 'application/json',
                'Authorization': `Basic ${authString}`
            }
        });

        return response.data;
    } catch (error) {
        console.error('Midtrans get status error:', error.response?.data || error.message);
        return null;
    }
}

/**
 * Verify notification signature
 * @param {Object} notification - Notification payload
 * @returns {boolean}
 */
function verifySignature(notification) {
    const crypto = require('crypto');
    const { order_id, status_code, gross_amount, signature_key } = notification;

    const expectedSignature = crypto
        .createHash('sha512')
        .update(`${order_id}${status_code}${gross_amount}${serverKey}`)
        .digest('hex');

    return signature_key === expectedSignature;
}

/**
 * Check if transaction is success
 * @param {string} transactionStatus - Transaction status from Midtrans
 * @param {string} fraudStatus - Fraud status from Midtrans
 * @returns {boolean}
 */
function isTransactionSuccess(transactionStatus, fraudStatus) {
    return (
        transactionStatus === 'capture' && fraudStatus === 'accept'
    ) || transactionStatus === 'settlement';
}

/**
 * Check if transaction is pending
 * @param {string} transactionStatus - Transaction status
 * @returns {boolean}
 */
function isTransactionPending(transactionStatus) {
    return transactionStatus === 'pending';
}

/**
 * Check if transaction failed/expired/cancelled
 * @param {string} transactionStatus - Transaction status
 * @returns {boolean}
 */
function isTransactionFailed(transactionStatus) {
    return ['deny', 'cancel', 'expire', 'failure'].includes(transactionStatus);
}

module.exports = {
    createPaymentToken,
    getTransactionStatus,
    verifySignature,
    isTransactionSuccess,
    isTransactionPending,
    isTransactionFailed,
    MIDTRANS_CLIENT_KEY: process.env.MIDTRANS_CLIENT_KEY
};
