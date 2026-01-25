"use strict";
// Database Configuration
// Purpose: PostgreSQL connection pool with proper error handling
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.query = query;
exports.getClient = getClient;
exports.runMigrations = runMigrations;
exports.checkConnection = checkConnection;
exports.closePool = closePool;
const pg_1 = require("pg");
const logger_1 = require("../utils/logger");
// Connection pool for efficient database access
// Pool maintains multiple connections and reuses them
const pool = new pg_1.Pool({
    connectionString: process.env.DATABASE_URL,
    max: 20, // Maximum connections in pool
    idleTimeoutMillis: 30000, // Close idle connections after 30s
    connectionTimeoutMillis: 2000, // Fail fast if can't connect in 2s
});
// Log pool errors (connection issues, etc.)
pool.on('error', (err) => {
    logger_1.logger.error('Unexpected database pool error', { error: err.message });
});
// Log when connections are acquired (useful for debugging)
pool.on('connect', () => {
    logger_1.logger.debug('New database connection established');
});
/**
 * Execute a SQL query with parameters
 * @param text - SQL query string with $1, $2 placeholders
 * @param params - Array of parameter values
 * @returns Query result
 */
async function query(text, params) {
    const start = Date.now();
    try {
        const result = await pool.query(text, params);
        const duration = Date.now() - start;
        // Log slow queries (> 100ms) for optimization
        if (duration > 100) {
            logger_1.logger.warn('Slow query detected', {
                query: text.substring(0, 100),
                duration: `${duration}ms`,
                rows: result.rowCount
            });
        }
        return result;
    }
    catch (error) {
        logger_1.logger.error('Database query failed', {
            query: text.substring(0, 100),
            error: error.message
        });
        throw error;
    }
}
/**
 * Get a client from the pool for transaction support
 * Remember to release the client after use!
 */
async function getClient() {
    const client = await pool.connect();
    return client;
}
/**
 * Run database migrations
 * Reads and executes SQL migration files
 */
async function runMigrations() {
    const fs = await Promise.resolve().then(() => __importStar(require('fs')));
    const path = await Promise.resolve().then(() => __importStar(require('path')));
    const migrationsDir = path.join(__dirname, '../migrations');
    try {
        // Check if migrations directory exists
        if (!fs.existsSync(migrationsDir)) {
            logger_1.logger.warn('No migrations directory found');
            return;
        }
        // Get all SQL files sorted by name
        const files = fs.readdirSync(migrationsDir)
            .filter(f => f.endsWith('.sql'))
            .sort();
        for (const file of files) {
            const filePath = path.join(migrationsDir, file);
            const sql = fs.readFileSync(filePath, 'utf8');
            logger_1.logger.info(`Running migration: ${file}`);
            await pool.query(sql);
            logger_1.logger.info(`Migration complete: ${file}`);
        }
    }
    catch (error) {
        logger_1.logger.error('Migration failed', { error: error.message });
        throw error;
    }
}
/**
 * Check database connection health
 * Used by health check endpoint
 */
async function checkConnection() {
    try {
        await pool.query('SELECT 1');
        return true;
    }
    catch {
        return false;
    }
}
/**
 * Graceful shutdown - close all pool connections
 */
async function closePool() {
    await pool.end();
    logger_1.logger.info('Database pool closed');
}
exports.default = { query, getClient, runMigrations, checkConnection, closePool };
//# sourceMappingURL=database.js.map