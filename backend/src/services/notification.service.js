const db = require('../config/database');

/**
 * Create a notification
 * @param {Object} params - Notification parameters
 * @param {string} params.userId - User ID
 * @param {string} params.judul - Notification title
 * @param {string} params.pesan - Notification message
 * @param {string} params.type - Notification type (order_status, payment, info)
 * @param {string} params.referenceId - Reference ID (optional)
 * @returns {Promise<Object>}
 */
async function createNotification({ userId, judul, pesan, type = 'info', referenceId = null }) {
    const [notification] = await db('notifikasi')
        .insert({
            user_id: userId,
            judul,
            pesan,
            type,
            reference_id: referenceId,
            is_read: false
        })
        .returning('*');

    return notification;
}

/**
 * Get notifications for a user
 * @param {string} userId - User ID
 * @param {Object} options - Query options
 * @returns {Promise<Array>}
 */
async function getUserNotifications(userId, { limit = 50, offset = 0, unreadOnly = false } = {}) {
    let query = db('notifikasi')
        .where('user_id', userId)
        .orderBy('created_at', 'desc')
        .limit(limit)
        .offset(offset);

    if (unreadOnly) {
        query = query.where('is_read', false);
    }

    return query;
}

/**
 * Get unread notification count for a user
 * @param {string} userId - User ID
 * @returns {Promise<number>}
 */
async function getUnreadCount(userId) {
    const result = await db('notifikasi')
        .where('user_id', userId)
        .where('is_read', false)
        .count('id as count')
        .first();

    return parseInt(result.count) || 0;
}

/**
 * Mark notification as read
 * @param {string} notificationId - Notification ID
 * @param {string} userId - User ID (for authorization)
 * @returns {Promise<Object|null>}
 */
async function markAsRead(notificationId, userId) {
    const [notification] = await db('notifikasi')
        .where('id', notificationId)
        .where('user_id', userId)
        .update({
            is_read: true
        })
        .returning('*');

    return notification || null;
}

/**
 * Mark all notifications as read for a user
 * @param {string} userId - User ID
 * @returns {Promise<number>} - Number of updated notifications
 */
async function markAllAsRead(userId) {
    return db('notifikasi')
        .where('user_id', userId)
        .where('is_read', false)
        .update({
            is_read: true
        });
}

/**
 * Delete a notification
 * @param {string} notificationId - Notification ID
 * @param {string} userId - User ID (for authorization)
 * @returns {Promise<boolean>}
 */
async function deleteNotification(notificationId, userId) {
    const deleted = await db('notifikasi')
        .where('id', notificationId)
        .where('user_id', userId)
        .del();

    return deleted > 0;
}

/**
 * Notify about order status change
 * @param {Object} order - Order object
 * @param {string} oldStatus - Old status
 * @param {string} newStatus - New status
 */
async function notifyOrderStatusChange(order, oldStatus, newStatus) {
    const statusMessages = {
        'dikemas': 'Pesanan Anda sedang dikemas dan akan segera dikirim.',
        'dikirim': 'Pesanan Anda sedang dalam perjalanan pengiriman.',
        'selesai': 'Pesanan Anda telah selesai. Terima kasih telah berbelanja!'
    };

    const message = statusMessages[newStatus] || `Status pesanan berubah menjadi: ${newStatus}`;

    await createNotification({
        userId: order.user_id,
        judul: `Status Pesanan: ${newStatus.charAt(0).toUpperCase() + newStatus.slice(1)}`,
        pesan: message,
        type: 'order_status',
        referenceId: order.id
    });
}

module.exports = {
    createNotification,
    getUserNotifications,
    getUnreadCount,
    markAsRead,
    markAllAsRead,
    deleteNotification,
    notifyOrderStatusChange
};
