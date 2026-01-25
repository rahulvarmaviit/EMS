// Database Configuration
// Purpose: PostgreSQL connection pool with proper error handling

import { Pool, PoolClient } from 'pg';
import { logger } from '../utils/logger';

// Connection pool for efficient database access
// Pool maintains multiple connections and reuses them
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20, // Maximum connections in pool
  idleTimeoutMillis: 30000, // Close idle connections after 30s
  connectionTimeoutMillis: 2000, // Fail fast if can't connect in 2s
});

// Log pool errors (connection issues, etc.)
pool.on('error', (err: Error) => {
  logger.error('Unexpected database pool error', { error: err.message });
});

// Log when connections are acquired (useful for debugging)
pool.on('connect', () => {
  logger.debug('New database connection established');
});

/**
 * Execute a SQL query with parameters
 * @param text - SQL query string with $1, $2 placeholders
 * @param params - Array of parameter values
 * @returns Query result
 */
export async function query(text: string, params?: any[]) {
  const start = Date.now();
  try {
    const result = await pool.query(text, params);
    const duration = Date.now() - start;
    
    // Log slow queries (> 100ms) for optimization
    if (duration > 100) {
      logger.warn('Slow query detected', { 
        query: text.substring(0, 100), 
        duration: `${duration}ms`,
        rows: result.rowCount 
      });
    }
    
    return result;
  } catch (error) {
    logger.error('Database query failed', { 
      query: text.substring(0, 100), 
      error: (error as Error).message 
    });
    throw error;
  }
}

/**
 * Get a client from the pool for transaction support
 * Remember to release the client after use!
 */
export async function getClient(): Promise<PoolClient> {
  const client = await pool.connect();
  return client;
}

/**
 * Run database migrations
 * Reads and executes SQL migration files
 */
export async function runMigrations(): Promise<void> {
  const fs = await import('fs');
  const path = await import('path');
  
  const migrationsDir = path.join(__dirname, '../migrations');
  
  try {
    // Check if migrations directory exists
    if (!fs.existsSync(migrationsDir)) {
      logger.warn('No migrations directory found');
      return;
    }
    
    // Get all SQL files sorted by name
    const files = fs.readdirSync(migrationsDir)
      .filter(f => f.endsWith('.sql'))
      .sort();
    
    for (const file of files) {
      const filePath = path.join(migrationsDir, file);
      const sql = fs.readFileSync(filePath, 'utf8');
      
      logger.info(`Running migration: ${file}`);
      await pool.query(sql);
      logger.info(`Migration complete: ${file}`);
    }
  } catch (error) {
    logger.error('Migration failed', { error: (error as Error).message });
    throw error;
  }
}

/**
 * Check database connection health
 * Used by health check endpoint
 */
export async function checkConnection(): Promise<boolean> {
  try {
    await pool.query('SELECT 1');
    return true;
  } catch {
    return false;
  }
}

/**
 * Graceful shutdown - close all pool connections
 */
export async function closePool(): Promise<void> {
  await pool.end();
  logger.info('Database pool closed');
}

export default { query, getClient, runMigrations, checkConnection, closePool };
