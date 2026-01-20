const jwt = require('jsonwebtoken');
const db = require('../config/database');

const ACCESS_SECRET = process.env.JWT_ACCESS_SECRET || 'access_secret_key_default';
const REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'refresh_secret_key_default';
const ACCESS_EXPIRES_IN = process.env.JWT_ACCESS_EXPIRES_IN || '15m';
const REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || '7d';

/**
 * Generate access token
 * @param {Object} payload - User payload
 * @returns {string}
 */
function generateAccessToken(payload) {
    return jwt.sign(payload, ACCESS_SECRET, { expiresIn: ACCESS_EXPIRES_IN });
}

/**
 * Generate refresh token
 * @param {Object} payload - User payload
 * @returns {string}
 */
function generateRefreshToken(payload) {
    return jwt.sign(payload, REFRESH_SECRET, { expiresIn: REFRESH_EXPIRES_IN });
}

/**
 * Verify access token
 * @param {string} token - JWT token
 * @returns {Object | null}
 */
function verifyAccessToken(token) {
    try {
        return jwt.verify(token, ACCESS_SECRET);
    } catch (error) {
        return null;
    }
}

/**
 * Verify refresh token
 * @param {string} token - JWT token
 * @returns {Object | null}
 */
function verifyRefreshToken(token) {
    try {
        return jwt.verify(token, REFRESH_SECRET);
    } catch (error) {
        return null;
    }
}

/**
 * Save refresh token to database
 * @param {string} userId - User ID
 * @param {string} token - Refresh token
 * @returns {Promise<void>}
 */
async function saveRefreshToken(userId, token) {
    // Calculate expiration date
    const decoded = jwt.decode(token);
    const expiresAt = new Date(decoded.exp * 1000);

    await db('refresh_tokens').insert({
        user_id: userId,
        token: token,
        expires_at: expiresAt
    });
}

/**
 * Find refresh token in database
 * @param {string} token - Refresh token
 * @returns {Promise<Object | null>}
 */
async function findRefreshToken(token) {
    return db('refresh_tokens')
        .where('token', token)
        .where('expires_at', '>', new Date())
        .first();
}

/**
 * Delete refresh token from database
 * @param {string} token - Refresh token
 * @returns {Promise<void>}
 */
async function deleteRefreshToken(token) {
    await db('refresh_tokens').where('token', token).del();
}

/**
 * Delete all refresh tokens for a user
 * @param {string} userId - User ID
 * @returns {Promise<void>}
 */
async function deleteAllUserRefreshTokens(userId) {
    await db('refresh_tokens').where('user_id', userId).del();
}

/**
 * Clean expired refresh tokens
 * @returns {Promise<number>} - Number of deleted tokens
 */
async function cleanExpiredTokens() {
    return db('refresh_tokens').where('expires_at', '<', new Date()).del();
}

/**
 * Parse duration string to milliseconds
 * @param {string} duration - Duration string (e.g., '15m', '7d')
 * @returns {number}
 */
function parseDuration(duration) {
    const match = duration.match(/^(\d+)([smhd])$/);
    if (!match) return 0;

    const value = parseInt(match[1]);
    const unit = match[2];

    switch (unit) {
        case 's': return value * 1000;
        case 'm': return value * 60 * 1000;
        case 'h': return value * 60 * 60 * 1000;
        case 'd': return value * 24 * 60 * 60 * 1000;
        default: return 0;
    }
}

module.exports = {
    generateAccessToken,
    generateRefreshToken,
    verifyAccessToken,
    verifyRefreshToken,
    saveRefreshToken,
    findRefreshToken,
    deleteRefreshToken,
    deleteAllUserRefreshTokens,
    cleanExpiredTokens,
    parseDuration,
    ACCESS_EXPIRES_IN,
    REFRESH_EXPIRES_IN
};
