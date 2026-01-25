"use strict";
// Main Application Entry Point
// Purpose: Initialize Express server with all configurations
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const env_1 = __importStar(require("./config/env"));
const database_1 = require("./config/database");
const logger_1 = require("./utils/logger");
const requestLogger_1 = require("./middlewares/requestLogger");
const routes_1 = __importDefault(require("./routes"));
// Validate environment variables early
(0, env_1.validateEnv)();
// Create Express app
const app = (0, express_1.default)();
// ============================================
// MIDDLEWARE SETUP
// ============================================
// Enable CORS for mobile app access
app.use((0, cors_1.default)({
    origin: '*', // Allow all origins for mobile app
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
}));
// Parse JSON bodies
app.use(express_1.default.json({ limit: '10mb' }));
// Log all requests
app.use(requestLogger_1.requestLogger);
// ============================================
// HEALTH CHECK ENDPOINT
// ============================================
/**
 * GET /health
 * Health check endpoint for monitoring and load balancers
 * Returns database connection status
 */
app.get('/health', async (req, res) => {
    const dbHealthy = await (0, database_1.checkConnection)();
    const status = {
        status: dbHealthy ? 'healthy' : 'unhealthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        database: dbHealthy ? 'connected' : 'disconnected',
    };
    res.status(dbHealthy ? 200 : 503).json(status);
});
// ============================================
// API ROUTES
// ============================================
// Mount all API routes under /api prefix
app.use('/api', routes_1.default);
// ============================================
// ERROR HANDLING
// ============================================
// 404 handler for unknown routes
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: `Route ${req.method} ${req.path} not found`,
    });
});
// Global error handler
app.use((err, req, res, next) => {
    logger_1.logger.error('Unhandled error', {
        error: err.message,
        stack: err.stack,
        path: req.path,
        method: req.method,
    });
    res.status(500).json({
        success: false,
        error: 'Internal server error. Please try again later.',
    });
});
// ============================================
// SERVER STARTUP
// ============================================
async function startServer() {
    try {
        // Run database migrations
        logger_1.logger.info('Running database migrations...');
        await (0, database_1.runMigrations)();
        logger_1.logger.info('Migrations completed successfully');
        // Verify database connection
        const dbConnected = await (0, database_1.checkConnection)();
        if (!dbConnected) {
            throw new Error('Failed to connect to database');
        }
        logger_1.logger.info('Database connection verified');
        // Start HTTP server
        app.listen(env_1.default.PORT, '0.0.0.0', () => {
            logger_1.logger.info(`Server started`, {
                port: env_1.default.PORT,
                environment: env_1.default.NODE_ENV,
                url: `http://0.0.0.0:${env_1.default.PORT}`,
            });
            console.log(`
========================================
  EMS Backend Server Running
========================================
  URL: http://0.0.0.0:${env_1.default.PORT}
  Health: http://0.0.0.0:${env_1.default.PORT}/health
  API: http://0.0.0.0:${env_1.default.PORT}/api
  Environment: ${env_1.default.NODE_ENV}
========================================
      `);
        });
    }
    catch (error) {
        logger_1.logger.error('Server startup failed', { error: error.message });
        process.exit(1);
    }
}
// Handle graceful shutdown
process.on('SIGTERM', async () => {
    logger_1.logger.info('Received SIGTERM, shutting down gracefully');
    const { closePool } = await Promise.resolve().then(() => __importStar(require('./config/database')));
    await closePool();
    process.exit(0);
});
process.on('SIGINT', async () => {
    logger_1.logger.info('Received SIGINT, shutting down gracefully');
    const { closePool } = await Promise.resolve().then(() => __importStar(require('./config/database')));
    await closePool();
    process.exit(0);
});
// Start the server
startServer();
//# sourceMappingURL=index.js.map