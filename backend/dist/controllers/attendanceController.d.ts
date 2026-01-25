import { Request, Response } from 'express';
/**
 * POST /api/attendance/check-in
 * Record user check-in with GPS validation
 */
export declare function checkIn(req: Request, res: Response): Promise<void>;
/**
 * POST /api/attendance/check-out
 * Record user check-out with GPS validation
 */
export declare function checkOut(req: Request, res: Response): Promise<void>;
/**
 * GET /api/attendance/self
 * Get current user's attendance history
 */
export declare function getSelfAttendance(req: Request, res: Response): Promise<void>;
/**
 * GET /api/attendance/team/:teamId
 * Get team attendance (Lead/Admin only)
 */
export declare function getTeamAttendance(req: Request, res: Response): Promise<void>;
declare const _default: {
    checkIn: typeof checkIn;
    checkOut: typeof checkOut;
    getSelfAttendance: typeof getSelfAttendance;
    getTeamAttendance: typeof getTeamAttendance;
};
export default _default;
//# sourceMappingURL=attendanceController.d.ts.map