import { Request, Response } from 'express';
/**
 * GET /api/teams
 * List all teams with lead info
 */
export declare function listTeams(req: Request, res: Response): Promise<void>;
/**
 * POST /api/teams
 * Create a new team (Admin only)
 */
export declare function createTeam(req: Request, res: Response): Promise<void>;
/**
 * GET /api/teams/:id
 * Get single team with members
 */
export declare function getTeam(req: Request, res: Response): Promise<void>;
/**
 * PATCH /api/teams/:id
 * Update team (Admin only)
 */
export declare function updateTeam(req: Request, res: Response): Promise<void>;
/**
 * DELETE /api/teams/:id
 * Soft delete a team (Admin only)
 */
export declare function deleteTeam(req: Request, res: Response): Promise<void>;
declare const _default: {
    listTeams: typeof listTeams;
    createTeam: typeof createTeam;
    getTeam: typeof getTeam;
    updateTeam: typeof updateTeam;
    deleteTeam: typeof deleteTeam;
};
export default _default;
//# sourceMappingURL=teamController.d.ts.map