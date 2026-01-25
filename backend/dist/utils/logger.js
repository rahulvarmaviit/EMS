"use strict";
// Logging Utility
// Purpose: Structured logging for debugging, monitoring, and auditing
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.logger = void 0;
const env_1 = __importDefault(require("../config/env"));
/**
 * Format a log entry as JSON string
 * JSON format is easier to parse by log aggregators
 */
function formatLog(level, message, data) {
    const entry = {
        timestamp: new Date().toISOString(),
        level,
        message,
        ...(data && { data }),
    };
    return JSON.stringify(entry);
}
/**
 * Logger object with methods for each log level
 */
exports.logger = {
    /**
     * Debug level - development only
     * Use for detailed debugging information
     */
    debug(message, data) {
        if (env_1.default.NODE_ENV === 'development') {
            console.log(formatLog('debug', message, data));
        }
    },
    /**
     * Info level - normal operations
     * Use for tracking normal system behavior
     */
    info(message, data) {
        console.log(formatLog('info', message, data));
    },
    /**
     * Warn level - potential issues
     * Use for non-critical issues that should be investigated
     */
    warn(message, data) {
        console.warn(formatLog('warn', message, data));
    },
    /**
     * Error level - failures
     * Use for errors that need immediate attention
     */
    error(message, data) {
        console.error(formatLog('error', message, data));
    },
    /**
     * Log HTTP request (for middleware)
     */
    request(method, path, statusCode, duration, userId) {
        this.info('HTTP Request', {
            method,
            path,
            statusCode,
            duration: `${duration}ms`,
            ...(userId && { userId }),
        });
    },
    /**
     * Log authentication events
     */
    auth(event, userId, details) {
        this.info(`Auth: ${event}`, {
            event,
            ...(userId && { userId }),
            ...details,
        });
    },
    /**
     * Log attendance events
     */
    attendance(event, userId, details) {
        this.info(`Attendance: ${event}`, {
            event,
            userId,
            ...details,
        });
    },
};
exports.default = exports.logger;
//# sourceMappingURL=logger.js.map