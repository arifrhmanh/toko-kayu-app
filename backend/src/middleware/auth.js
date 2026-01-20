const { verifyAccessToken } = require('../utils/jwt');
const response = require('../utils/response');
const db = require('../config/database');

/**
 * Authentication middleware
 * Verifies JWT access token and attaches user to request
 */
async function authenticate(req, res, next) {
    try {
        // Get token from header
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return response.unauthorized(res, 'Access token required');
        }

        const token = authHeader.split(' ')[1];

        // Verify token
        const decoded = verifyAccessToken(token);

        if (!decoded) {
            return response.unauthorized(res, 'Invalid or expired access token');
        }

        // Get user from database
        const user = await db('users')
            .where('id', decoded.id)
            .select('id', 'username', 'role', 'nama_lengkap', 'no_hp')
            .first();

        if (!user) {
            return response.unauthorized(res, 'User not found');
        }

        // Attach user to request
        req.user = user;
        next();
    } catch (error) {
        console.error('Auth middleware error:', error);
        return response.serverError(res, 'Authentication failed');
    }
}

/**
 * Optional authentication middleware
 * If token is present, verifies it and attaches user
 * If no token, continues without user
 */
async function optionalAuth(req, res, next) {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return next();
        }

        const token = authHeader.split(' ')[1];
        const decoded = verifyAccessToken(token);

        if (decoded) {
            const user = await db('users')
                .where('id', decoded.id)
                .select('id', 'username', 'role', 'nama_lengkap', 'no_hp')
                .first();

            if (user) {
                req.user = user;
            }
        }

        next();
    } catch (error) {
        next();
    }
}

module.exports = {
    authenticate,
    optionalAuth
};
