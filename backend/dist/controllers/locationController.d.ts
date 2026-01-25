import { Request, Response } from 'express';
/**
 * GET /api/locations
 * List all office locations
 */
export declare function listLocations(req: Request, res: Response): Promise<void>;
/**
 * POST /api/locations
 * Create a new office location (Admin only)
 */
export declare function createLocation(req: Request, res: Response): Promise<void>;
/**
 * PATCH /api/locations/:id
 * Update office location (Admin only)
 */
export declare function updateLocation(req: Request, res: Response): Promise<void>;
/**
 * DELETE /api/locations/:id
 * Soft delete a location (Admin only)
 */
export declare function deleteLocation(req: Request, res: Response): Promise<void>;
declare const _default: {
    listLocations: typeof listLocations;
    createLocation: typeof createLocation;
    updateLocation: typeof updateLocation;
    deleteLocation: typeof deleteLocation;
};
export default _default;
//# sourceMappingURL=locationController.d.ts.map