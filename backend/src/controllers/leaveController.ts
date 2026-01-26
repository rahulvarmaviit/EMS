
import { Request, Response } from 'express';
import { prisma } from '../config/database';
import { logger } from '../utils/logger';

/**
 * POST /api/leaves
 * Apply for a new leave
 */
export async function createLeaveRequest(req: Request, res: Response): Promise<void> {
    try {
        const userId = req.user?.userId;
        const { start_date, end_date, reason } = req.body;

        if (!start_date || !end_date || !reason) {
            res.status(400).json({
                success: false,
                error: 'Start date, end date, and reason are required',
            });
            return;
        }

        const startDate = new Date(start_date);
        const endDate = new Date(end_date);

        if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
            res.status(400).json({
                success: false,
                error: 'Invalid date format',
            });
            return;
        }

        if (endDate < startDate) {
            res.status(400).json({
                success: false,
                error: 'End date cannot be before start date',
            });
            return;
        }

        // Check for overlapping leaves
        const overlapping = await prisma.leaveRequest.findFirst({
            where: {
                user_id: userId,
                OR: [
                    {
                        start_date: { lte: endDate },
                        end_date: { gte: startDate },
                    },
                ],
                status: { not: 'REJECTED' },
            },
        });

        if (overlapping) {
            res.status(400).json({
                success: false,
                error: 'You already have a leave request for this period',
            });
            return;
        }

        const leave = await prisma.leaveRequest.create({
            data: {
                user_id: userId!,
                start_date: startDate,
                end_date: endDate,
                reason,
                status: 'PENDING',
            },
        });

        res.status(201).json({
            success: true,
            message: 'Leave request submitted successfully',
            data: leave,
        });
    } catch (error) {
        logger.error('Create leave error', { error: (error as Error).message });
        res.status(500).json({
            success: false,
            error: 'Failed to submit leave request',
        });
    }
}

/**
 * GET /api/leaves/self
 * Get current user's leave history
 */
export async function getMyLeaves(req: Request, res: Response): Promise<void> {
    try {
        const userId = req.user?.userId;
        const { page = 1, limit = 20 } = req.query;

        const pageNum = Math.max(1, parseInt(page as string, 10));
        const limitNum = Math.min(100, Math.max(1, parseInt(limit as string, 10)));
        const skip = (pageNum - 1) * limitNum;

        const [leaves, total] = await Promise.all([
            prisma.leaveRequest.findMany({
                where: { user_id: userId },
                orderBy: { created_at: 'desc' },
                take: limitNum,
                skip,
            }),
            prisma.leaveRequest.count({
                where: { user_id: userId },
            }),
        ]);

        res.json({
            success: true,
            data: {
                leaves,
                pagination: {
                    page: pageNum,
                    limit: limitNum,
                    total,
                    totalPages: Math.ceil(total / limitNum),
                },
            },
        });
    } catch (error) {
        logger.error('Get my leaves error', { error: (error as Error).message });
        res.status(500).json({
            success: false,
            error: 'Failed to fetch leave history',
        });
    }
}

/**
 * GET /api/leaves/team
 * Get team members' leave requests (Lead/Admin only)
 */
export async function getTeamLeaves(req: Request, res: Response): Promise<void> {
    try {
        const userId = req.user?.userId;
        const userRole = req.user?.role;
        const { status, page = 1, limit = 20 } = req.query;

        // Verify role
        if (userRole === 'EMPLOYEE') {
            res.status(403).json({
                success: false,
                error: 'Unauthorized access',
            });
            return;
        }

        // If Lead, find their team
        let teamId: string | undefined;
        if (userRole === 'LEAD') {
            const team = await prisma.team.findFirst({
                where: { lead_id: userId },
            });

            if (!team) {
                res.status(400).json({
                    success: false,
                    error: 'You are not assigned as a lead to any team',
                });
                return;
            }
            teamId = team.id;
        }

        // Build filter
        const whereClause: any = {};

        // For leads, filter by team
        if (teamId) {
            whereClause.user = { team_id: teamId };
        }

        if (status) {
            whereClause.status = status;
        }

        const pageNum = Math.max(1, parseInt(page as string, 10));
        const limitNum = Math.min(100, Math.max(1, parseInt(limit as string, 10)));
        const skip = (pageNum - 1) * limitNum;

        const [leaves, total] = await Promise.all([
            prisma.leaveRequest.findMany({
                where: whereClause,
                include: {
                    user: {
                        select: {
                            id: true,
                            full_name: true,
                            mobile_number: true,
                            team: { select: { name: true } }
                        }
                    }
                },
                orderBy: { created_at: 'desc' },
                take: limitNum,
                skip,
            }),
            prisma.leaveRequest.count({ where: whereClause }),
        ]);

        res.json({
            success: true,
            data: {
                leaves,
                pagination: {
                    page: pageNum,
                    limit: limitNum,
                    total,
                    totalPages: Math.ceil(total / limitNum),
                },
            },
        });

    } catch (error) {
        logger.error('Get team leaves error', { error: (error as Error).message });
        res.status(500).json({
            success: false,
            error: 'Failed to fetch team leaves',
        });
    }
}

export default { createLeaveRequest, getMyLeaves, getTeamLeaves };
