"use strict";
// Request Logging Middleware
// Purpose: Log all HTTP requests for monitoring and debugging
Object.defineProperty(exports, "__esModule", { value: true });
exports.requestLogger = requestLogger;
const logger_1 = require("../utils/logger");
/**
 * Middleware to log all incoming HTTP requests
 * Captures method, path, status code, and response time
 */
function requestLogger(req, res, next) {
    const startTime = Date.now();
    // Log after response is finished
    res.on('finish', () => {
        const duration = Date.now() - startTime;
        const userId = req.user?.userId;
        // Skip logging health check to reduce noise
        if (req.path === '/health') {
            return;
        }
        logger_1.logger.request(req.method, req.path, res.statusCode, duration, userId);
    });
    next();
}
exports.default = requestLogger;
//# sourceMappingURL=requestLogger.js.map