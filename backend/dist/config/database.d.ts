import { PoolClient } from 'pg';
/**
 * Execute a SQL query with parameters
 * @param text - SQL query string with $1, $2 placeholders
 * @param params - Array of parameter values
 * @returns Query result
 */
export declare function query(text: string, params?: any[]): Promise<import("pg").QueryResult<any>>;
/**
 * Get a client from the pool for transaction support
 * Remember to release the client after use!
 */
export declare function getClient(): Promise<PoolClient>;
/**
 * Run database migrations
 * Reads and executes SQL migration files
 */
export declare function runMigrations(): Promise<void>;
/**
 * Check database connection health
 * Used by health check endpoint
 */
export declare function checkConnection(): Promise<boolean>;
/**
 * Graceful shutdown - close all pool connections
 */
export declare function closePool(): Promise<void>;
declare const _default: {
    query: typeof query;
    getClient: typeof getClient;
    runMigrations: typeof runMigrations;
    checkConnection: typeof checkConnection;
    closePool: typeof closePool;
};
export default _default;
//# sourceMappingURL=database.d.ts.map