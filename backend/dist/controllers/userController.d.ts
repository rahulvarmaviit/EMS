import { Request, Response } from 'express';
/**
 * GET /api/users
 * List all users (Admin sees all, Lead sees their team)
 */
export declare function listUsers(req: Request, res: Response): Promise<void>;
/**
 * GET /api/users/:id
 * Get single user details
 */
export declare function getUser(req: Request, res: Response): Promise<void>;
/**
 * PATCH /api/users/:id/assign-team
 * Assign user to a team (Admin only)
 */
export declare function assignTeam(req: Request, res: Response): Promise<void>;
/**
 * DELETE /api/users/:id
 * Soft delete a user (Admin only)
 */
export declare function deleteUser(req: Request, res: Response): Promise<void>;
declare const _default: {
    listUsers: typeof listUsers;
    getUser: typeof getUser;
    assignTeam: typeof assignTeam;
    deleteUser: typeof deleteUser;
};
export default _default;
//# sourceMappingURL=userController.d.ts.map