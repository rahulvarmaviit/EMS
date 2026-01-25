"use strict";
// Environment Configuration
// Purpose: Centralized environment variable management with validation
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.config = void 0;
exports.validateEnv = validateEnv;
const dotenv_1 = __importDefault(require("dotenv"));
// Load .env file in development
dotenv_1.default.config();
// Environment configuration with defaults
exports.config = {
    // Server settings
    PORT: parseInt(process.env.PORT || '5000', 10),
    NODE_ENV: process.env.NODE_ENV || 'development',
    // Database (required - will fail if not set)
    DATABASE_URL: process.env.DATABASE_URL || '',
    // JWT settings (required - must be set via environment variable)
    JWT_SECRET: process.env.JWT_SECRET || '',
    JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '7d', // 7 days for mobile-friendly sessions
    // Business rules
    LATE_THRESHOLD_MINUTES: parseInt(process.env.LATE_THRESHOLD_MINUTES || '15', 10), // 15 min grace period
    HALF_DAY_HOURS: parseInt(process.env.HALF_DAY_HOURS || '4', 10), // Less than 4 hours = half day
    // Rate limiting
    RATE_LIMIT_WINDOW_MS: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000', 10), // 15 minutes
    RATE_LIMIT_MAX_REQUESTS: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100', 10), // 100 requests per window
};
/**
 * Validate required environment variables
 * Call this at startup to fail fast if config is missing
 */
function validateEnv() {
    const required = ['DATABASE_URL', 'JWT_SECRET'];
    const missing = required.filter(key => !process.env[key]);
    if (missing.length > 0) {
        throw new Error(`Missing required environment variables: ${missing.join(', ')}. Please set them before starting the server.`);
    }
    // Validate JWT_SECRET strength
    if (exports.config.JWT_SECRET.length < 32) {
        throw new Error('JWT_SECRET must be at least 32 characters for security');
    }
}
exports.default = exports.config;
//# sourceMappingURL=env.js.map