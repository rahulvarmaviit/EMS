/**
 * Logger object with methods for each log level
 */
export declare const logger: {
    /**
     * Debug level - development only
     * Use for detailed debugging information
     */
    debug(message: string, data?: Record<string, any>): void;
    /**
     * Info level - normal operations
     * Use for tracking normal system behavior
     */
    info(message: string, data?: Record<string, any>): void;
    /**
     * Warn level - potential issues
     * Use for non-critical issues that should be investigated
     */
    warn(message: string, data?: Record<string, any>): void;
    /**
     * Error level - failures
     * Use for errors that need immediate attention
     */
    error(message: string, data?: Record<string, any>): void;
    /**
     * Log HTTP request (for middleware)
     */
    request(method: string, path: string, statusCode: number, duration: number, userId?: string): void;
    /**
     * Log authentication events
     */
    auth(event: "login" | "logout" | "register" | "failed_login", userId?: string, details?: Record<string, any>): void;
    /**
     * Log attendance events
     */
    attendance(event: "check_in" | "check_out" | "geo_rejected", userId: string, details?: Record<string, any>): void;
};
export default logger;
//# sourceMappingURL=logger.d.ts.map