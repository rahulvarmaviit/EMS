import { Request, Response } from 'express';
/**
 * POST /api/auth/login
 * Authenticate user with mobile number and password
 * Returns JWT token and user info on success
 */
export declare function login(req: Request, res: Response): Promise<void>;
/**
 * POST /api/auth/register
 * Register a new user (Admin only)
 * Creates user with hashed password
 */
export declare function register(req: Request, res: Response): Promise<void>;
/**
 * GET /api/auth/me
 * Get current authenticated user's profile
 */
export declare function getProfile(req: Request, res: Response): Promise<void>;
declare const _default: {
    login: typeof login;
    register: typeof register;
    getProfile: typeof getProfile;
};
export default _default;
//# sourceMappingURL=authController.d.ts.map