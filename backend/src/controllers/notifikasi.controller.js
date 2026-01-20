const response = require('../utils/response');
const notificationService = require('../services/notification.service');

/**
 * Get notifications for current user
 * GET /api/notifikasi
 */
async function getNotifikasi(req, res) {
    try {
        const { limit = 50, offset = 0, unread_only = false } = req.query;
        const userId = req.user.id;

        const notifications = await notificationService.getUserNotifications(userId, {
            limit: parseInt(limit),
            offset: parseInt(offset),
            unreadOnly: unread_only === 'true'
        });

        const unreadCount = await notificationService.getUnreadCount(userId);

        return response.success(res, {
            notifications,
            unread_count: unreadCount
        });

    } catch (error) {
        console.error('Get notifikasi error:', error);
        return response.serverError(res, 'Failed to get notifications');
    }
}

/**
 * Get unread notification count
 * GET /api/notifikasi/count
 */
async function getUnreadCount(req, res) {
    try {
        const userId = req.user.id;
        const count = await notificationService.getUnreadCount(userId);

        return response.success(res, { unread_count: count });

    } catch (error) {
        console.error('Get unread count error:', error);
        return response.serverError(res, 'Failed to get unread count');
    }
}

/**
 * Mark notification as read
 * PUT /api/notifikasi/:id/read
 */
async function markAsRead(req, res) {
    try {
        const { id } = req.params;
        const userId = req.user.id;

        const notification = await notificationService.markAsRead(id, userId);

        if (!notification) {
            return response.notFound(res, 'Notification not found');
        }

        return response.success(res, notification, 'Notification marked as read');

    } catch (error) {
        console.error('Mark as read error:', error);
        return response.serverError(res, 'Failed to mark notification as read');
    }
}

/**
 * Mark all notifications as read
 * PUT /api/notifikasi/read-all
 */
async function markAllAsRead(req, res) {
    try {
        const userId = req.user.id;

        const count = await notificationService.markAllAsRead(userId);

        return response.success(res, { updated_count: count }, 'All notifications marked as read');

    } catch (error) {
        console.error('Mark all as read error:', error);
        return response.serverError(res, 'Failed to mark notifications as read');
    }
}

/**
 * Delete notification
 * DELETE /api/notifikasi/:id
 */
async function deleteNotifikasi(req, res) {
    try {
        const { id } = req.params;
        const userId = req.user.id;

        const deleted = await notificationService.deleteNotification(id, userId);

        if (!deleted) {
            return response.notFound(res, 'Notification not found');
        }

        return response.success(res, null, 'Notification deleted');

    } catch (error) {
        console.error('Delete notifikasi error:', error);
        return response.serverError(res, 'Failed to delete notification');
    }
}

module.exports = {
    getNotifikasi,
    getUnreadCount,
    markAsRead,
    markAllAsRead,
    deleteNotifikasi
};
