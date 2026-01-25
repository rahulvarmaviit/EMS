export declare const config: {
    PORT: number;
    NODE_ENV: string;
    DATABASE_URL: string;
    JWT_SECRET: string;
    JWT_EXPIRES_IN: string;
    LATE_THRESHOLD_MINUTES: number;
    HALF_DAY_HOURS: number;
    RATE_LIMIT_WINDOW_MS: number;
    RATE_LIMIT_MAX_REQUESTS: number;
};
/**
 * Validate required environment variables
 * Call this at startup to fail fast if config is missing
 */
export declare function validateEnv(): void;
export default config;
//# sourceMappingURL=env.d.ts.map