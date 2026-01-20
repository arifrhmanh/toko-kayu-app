const response = require('../utils/response');

/**
 * Global error handler middleware
 */
function errorHandler(err, req, res, next) {
    console.error('Error:', err);

    // Multer errors
    if (err.code === 'LIMIT_FILE_SIZE') {
        return response.error(res, 'File too large. Maximum size is 5MB', 400);
    }

    if (err.code === 'LIMIT_UNEXPECTED_FILE') {
        return response.error(res, 'Unexpected field in form data', 400);
    }

    // Knex/PostgreSQL errors
    if (err.code === '23505') { // Unique violation
        return response.error(res, 'Duplicate entry. This record already exists', 409);
    }

    if (err.code === '23503') { // Foreign key violation
        return response.error(res, 'Referenced record not found', 400);
    }

    if (err.code === '22P02') { // Invalid UUID
        return response.error(res, 'Invalid ID format', 400);
    }

    // JSON parsing error
    if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
        return response.error(res, 'Invalid JSON format', 400);
    }

    // JWT errors
    if (err.name === 'JsonWebTokenError') {
        return response.unauthorized(res, 'Invalid token');
    }

    if (err.name === 'TokenExpiredError') {
        return response.unauthorized(res, 'Token expired');
    }

    // Default server error
    return response.serverError(res, process.env.NODE_ENV === 'development'
        ? err.message
        : 'Internal server error'
    );
}

/**
 * 404 Not Found handler
 */
function notFoundHandler(req, res) {
    return response.notFound(res, `Route ${req.method} ${req.path} not found`);
}

module.exports = {
    errorHandler,
    notFoundHandler
};
