const response = require('../utils/response');

/**
 * Role-based authorization middleware factory
 * @param {...string} allowedRoles - Roles that are allowed to access the route
 * @returns {Function} Express middleware function
 */
function authorize(...allowedRoles) {
    return (req, res, next) => {
        // Check if user is authenticated
        if (!req.user) {
            return response.unauthorized(res, 'Authentication required');
        }

        // Check if user role is in allowed roles
        if (!allowedRoles.includes(req.user.role)) {
            return response.forbidden(res, 'You do not have permission to access this resource');
        }

        next();
    };
}

/**
 * Admin only middleware
 */
const adminOnly = authorize('admin');

/**
 * Customer only middleware
 */
const customerOnly = authorize('customer');

/**
 * Both admin and customer
 */
const authenticated = authorize('admin', 'customer');

module.exports = {
    authorize,
    adminOnly,
    customerOnly,
    authenticated
};
