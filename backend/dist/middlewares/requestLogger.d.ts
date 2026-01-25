import { Request, Response, NextFunction } from 'express';
/**
 * Middleware to log all incoming HTTP requests
 * Captures method, path, status code, and response time
 */
export declare function requestLogger(req: Request, res: Response, next: NextFunction): void;
export default requestLogger;
//# sourceMappingURL=requestLogger.d.ts.map