/**
 * Standard API response formatter
 */

/**
 * Success response
 * @param {Object} res - Express response object
 * @param {Object} data - Response data
 * @param {string} message - Success message
 * @param {number} statusCode - HTTP status code
 */
function success(res, data = null, message = 'Success', statusCode = 200) {
    return res.status(statusCode).json({
        success: true,
        message,
        data
    });
}

/**
 * Error response
 * @param {Object} res - Express response object
 * @param {string} message - Error message
 * @param {number} statusCode - HTTP status code
 * @param {Object} errors - Validation errors
 */
function error(res, message = 'Error', statusCode = 400, errors = null) {
    const response = {
        success: false,
        message
    };

    if (errors) {
        response.errors = errors;
    }

    return res.status(statusCode).json(response);
}

/**
 * Paginated response
 * @param {Object} res - Express response object
 * @param {Array} data - Data array
 * @param {Object} pagination - Pagination info
 * @param {string} message - Success message
 */
function paginated(res, data, pagination, message = 'Success') {
    return res.status(200).json({
        success: true,
        message,
        data,
        pagination: {
            page: pagination.page,
            limit: pagination.limit,
            total: pagination.total,
            totalPages: Math.ceil(pagination.total / pagination.limit)
        }
    });
}

/**
 * Created response (201)
 * @param {Object} res - Express response object
 * @param {Object} data - Created data
 * @param {string} message - Success message
 */
function created(res, data, message = 'Created successfully') {
    return success(res, data, message, 201);
}

/**
 * No content response (204)
 * @param {Object} res - Express response object
 */
function noContent(res) {
    return res.status(204).send();
}

/**
 * Unauthorized response (401)
 * @param {Object} res - Express response object
 * @param {string} message - Error message
 */
function unauthorized(res, message = 'Unauthorized') {
    return error(res, message, 401);
}

/**
 * Forbidden response (403)
 * @param {Object} res - Express response object
 * @param {string} message - Error message
 */
function forbidden(res, message = 'Forbidden') {
    return error(res, message, 403);
}

/**
 * Not found response (404)
 * @param {Object} res - Express response object
 * @param {string} message - Error message
 */
function notFound(res, message = 'Not found') {
    return error(res, message, 404);
}

/**
 * Server error response (500)
 * @param {Object} res - Express response object
 * @param {string} message - Error message
 */
function serverError(res, message = 'Internal server error') {
    return error(res, message, 500);
}

module.exports = {
    success,
    error,
    paginated,
    created,
    noContent,
    unauthorized,
    forbidden,
    notFound,
    serverError
};
