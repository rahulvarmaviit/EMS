import { Request, Response, NextFunction } from 'express';
export interface JwtPayload {
    userId: string;
    mobile_number: string;
    role: 'ADMIN' | 'LEAD' | 'EMPLOYEE';
    iat?: number;
    exp?: number;
}
declare global {
    namespace Express {
        interface Request {
            user?: JwtPayload;
        }
    }
}
/**
 * Verify JWT token and attach user to request
 * Use this middleware on all protected routes
 */
export declare function authenticate(req: Request, res: Response, next: NextFunction): void;
/**
 * Role-based access control middleware factory
 * Use: authorize('ADMIN') or authorize('ADMIN', 'LEAD')
 * @param allowedRoles - Roles that can access this route
 */
export declare function authorize(...allowedRoles: ('ADMIN' | 'LEAD' | 'EMPLOYEE')[]): (req: Request, res: Response, next: NextFunction) => void;
/**
 * Generate JWT token for a user
 * @param payload - User data to encode in token
 * @returns Signed JWT token string
 */
export declare function generateToken(payload: Omit<JwtPayload, 'iat' | 'exp'>): string;
declare const _default: {
    authenticate: typeof authenticate;
    authorize: typeof authorize;
    generateToken: typeof generateToken;
};
export default _default;
//# sourceMappingURL=auth.d.ts.map