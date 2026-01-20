const bcrypt = require('bcryptjs');
const db = require('../config/database');
const response = require('../utils/response');
const {
    generateAccessToken,
    generateRefreshToken,
    verifyRefreshToken,
    saveRefreshToken,
    findRefreshToken,
    deleteRefreshToken,
    deleteAllUserRefreshTokens,
    ACCESS_EXPIRES_IN,
    REFRESH_EXPIRES_IN
} = require('../utils/jwt');

/**
 * Register new customer
 * POST /api/auth/register
 */
async function register(req, res) {
    try {
        const { username, password, nama_lengkap, no_hp } = req.body;

        // Validation
        if (!username || !password || !nama_lengkap) {
            return response.error(res, 'Username, password, and nama_lengkap are required', 400);
        }

        if (username.length < 4) {
            return response.error(res, 'Username must be at least 4 characters', 400);
        }

        if (password.length < 6) {
            return response.error(res, 'Password must be at least 6 characters', 400);
        }

        // Check if username exists
        const existingUser = await db('users').where('username', username).first();
        if (existingUser) {
            return response.error(res, 'Username already exists', 409);
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Create user
        const [user] = await db('users')
            .insert({
                username,
                password: hashedPassword,
                role: 'customer',
                nama_lengkap,
                no_hp: no_hp || null
            })
            .returning(['id', 'username', 'role', 'nama_lengkap', 'no_hp', 'created_at']);

        // Generate tokens
        const tokenPayload = { id: user.id, username: user.username, role: user.role };
        const accessToken = generateAccessToken(tokenPayload);
        const refreshToken = generateRefreshToken(tokenPayload);

        // Save refresh token
        await saveRefreshToken(user.id, refreshToken);

        return response.created(res, {
            user,
            tokens: {
                access_token: accessToken,
                refresh_token: refreshToken,
                access_expires_in: ACCESS_EXPIRES_IN,
                refresh_expires_in: REFRESH_EXPIRES_IN
            }
        }, 'Registration successful');

    } catch (error) {
        console.error('Register error:', error);
        return response.serverError(res, 'Registration failed');
    }
}

/**
 * Login user
 * POST /api/auth/login
 */
async function login(req, res) {
    try {
        const { username, password } = req.body;

        // Validation
        if (!username || !password) {
            return response.error(res, 'Username and password are required', 400);
        }

        // Find user
        const user = await db('users').where('username', username).first();
        if (!user) {
            return response.error(res, 'Invalid username or password', 401);
        }

        // Check password
        const isValidPassword = await bcrypt.compare(password, user.password);
        if (!isValidPassword) {
            return response.error(res, 'Invalid username or password', 401);
        }

        // Generate tokens
        const tokenPayload = { id: user.id, username: user.username, role: user.role };
        const accessToken = generateAccessToken(tokenPayload);
        const refreshToken = generateRefreshToken(tokenPayload);

        // Save refresh token
        await saveRefreshToken(user.id, refreshToken);

        // Remove password from response
        const { password: _, ...userWithoutPassword } = user;

        return response.success(res, {
            user: userWithoutPassword,
            tokens: {
                access_token: accessToken,
                refresh_token: refreshToken,
                access_expires_in: ACCESS_EXPIRES_IN,
                refresh_expires_in: REFRESH_EXPIRES_IN
            }
        }, 'Login successful');

    } catch (error) {
        console.error('Login error:', error);
        return response.serverError(res, 'Login failed');
    }
}

/**
 * Refresh access token
 * POST /api/auth/refresh
 */
async function refreshToken(req, res) {
    try {
        const { refresh_token } = req.body;

        if (!refresh_token) {
            return response.error(res, 'Refresh token is required', 400);
        }

        // Verify refresh token
        const decoded = verifyRefreshToken(refresh_token);
        if (!decoded) {
            return response.unauthorized(res, 'Invalid or expired refresh token');
        }

        // Check if token exists in database
        const storedToken = await findRefreshToken(refresh_token);
        if (!storedToken) {
            return response.unauthorized(res, 'Refresh token not found or expired');
        }

        // Get user
        const user = await db('users')
            .where('id', decoded.id)
            .select('id', 'username', 'role', 'nama_lengkap', 'no_hp')
            .first();

        if (!user) {
            return response.unauthorized(res, 'User not found');
        }

        // Generate new access token
        const tokenPayload = { id: user.id, username: user.username, role: user.role };
        const newAccessToken = generateAccessToken(tokenPayload);

        return response.success(res, {
            access_token: newAccessToken,
            access_expires_in: ACCESS_EXPIRES_IN
        }, 'Token refreshed successfully');

    } catch (error) {
        console.error('Refresh token error:', error);
        return response.serverError(res, 'Token refresh failed');
    }
}

/**
 * Logout user
 * POST /api/auth/logout
 */
async function logout(req, res) {
    try {
        const { refresh_token } = req.body;

        if (refresh_token) {
            await deleteRefreshToken(refresh_token);
        }

        return response.success(res, null, 'Logout successful');

    } catch (error) {
        console.error('Logout error:', error);
        return response.serverError(res, 'Logout failed');
    }
}

/**
 * Get current user profile
 * GET /api/auth/profile
 */
async function getProfile(req, res) {
    try {
        return response.success(res, { user: req.user });
    } catch (error) {
        console.error('Get profile error:', error);
        return response.serverError(res, 'Failed to get profile');
    }
}

/**
 * Update user profile
 * PUT /api/auth/profile
 */
async function updateProfile(req, res) {
    try {
        const { nama_lengkap, no_hp, current_password, new_password } = req.body;
        const userId = req.user.id;

        const updates = {};

        if (nama_lengkap) {
            updates.nama_lengkap = nama_lengkap;
        }

        if (no_hp !== undefined) {
            updates.no_hp = no_hp;
        }

        // Update password if provided
        if (current_password && new_password) {
            const user = await db('users').where('id', userId).first();

            const isValidPassword = await bcrypt.compare(current_password, user.password);
            if (!isValidPassword) {
                return response.error(res, 'Current password is incorrect', 400);
            }

            if (new_password.length < 6) {
                return response.error(res, 'New password must be at least 6 characters', 400);
            }

            const salt = await bcrypt.genSalt(10);
            updates.password = await bcrypt.hash(new_password, salt);
        }

        if (Object.keys(updates).length === 0) {
            return response.error(res, 'No updates provided', 400);
        }

        updates.updated_at = new Date();

        const [updatedUser] = await db('users')
            .where('id', userId)
            .update(updates)
            .returning(['id', 'username', 'role', 'nama_lengkap', 'no_hp', 'updated_at']);

        return response.success(res, { user: updatedUser }, 'Profile updated successfully');

    } catch (error) {
        console.error('Update profile error:', error);
        return response.serverError(res, 'Failed to update profile');
    }
}

module.exports = {
    register,
    login,
    refreshToken,
    logout,
    getProfile,
    updateProfile
};
