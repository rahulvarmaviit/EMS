// User Controller
// Purpose: User management operations (Admin/Lead access) using Prisma

import { Request, Response } from 'express';
import { prisma } from '../config/database';
import { logger } from '../utils/logger';
import { Role } from '@prisma/client';

/**
 * GET /api/users
 * List all users (Admin sees all, Lead sees their team)
 */
export async function listUsers(req: Request, res: Response): Promise<void> {
  try {
    const userRole = req.user?.role;
    const userId = req.user?.userId;
    const { page = 1, limit = 50, team_id, role } = req.query;

    const pageNum = Math.max(1, parseInt(page as string, 10));
    const limitNum = Math.min(100, Math.max(1, parseInt(limit as string, 10)));
    const skip = (pageNum - 1) * limitNum;

    // Build where clause
    const whereClause: any = { is_active: true };

    // Lead can only see their team members
    if (userRole === 'LEAD') {
      const leadTeam = await prisma.team.findFirst({
        where: { lead_id: userId },
      });

      if (!leadTeam) {
        // Lead without a team sees no one
        res.json({
          success: true,
          data: {
            users: [],
            pagination: { page: 1, limit: limitNum, total: 0, totalPages: 0 },
          },
        });
        return;
      }

      whereClause.team_id = leadTeam.id;
    } else if (team_id) {
      // Admin can filter by team_id
      whereClause.team_id = team_id as string;
    }

    // Filter by role
    if (role) {
      whereClause.role = role as Role;
    }

    // Get users with pagination
    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where: whereClause,
        include: {
          team: {
            select: { name: true },
          },
        },
        orderBy: { full_name: 'asc' },
        take: limitNum,
        skip,
      }),
      prisma.user.count({ where: whereClause }),
    ]);

    res.json({
      success: true,
      data: {
        users: users.map(u => ({
          id: u.id,
          mobile_number: u.mobile_number,
          full_name: u.full_name,
          role: u.role,
          team_id: u.team_id,
          team_name: u.team?.name || null,
          is_active: u.is_active,
          created_at: u.created_at,
        })),
        pagination: {
          page: pageNum,
          limit: limitNum,
          total,
          totalPages: Math.ceil(total / limitNum),
        },
      },
    });
  } catch (error) {
    logger.error('List users error', { error: (error as Error).message });
    res.status(500).json({
      success: false,
      error: 'Failed to fetch users',
    });
  }
}

/**
 * GET /api/users/:id
 * Get single user details
 */
export async function getUser(req: Request, res: Response): Promise<void> {
  try {
    const { id } = req.params;

    const user = await prisma.user.findUnique({
      where: { id },
      include: {
        team: {
          include: {
            lead: {
              select: { full_name: true },
            },
          },
        },
      },
    });

    if (!user) {
      res.status(404).json({
        success: false,
        error: 'User not found',
      });
      return;
    }

    res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          mobile_number: user.mobile_number,
          full_name: user.full_name,
          role: user.role,
          team_id: user.team_id,
          team_name: user.team?.name || null,
          team_lead_name: user.team?.lead?.full_name || null,
          is_active: user.is_active,
          created_at: user.created_at,
        },
      },
    });
  } catch (error) {
    logger.error('Get user error', { error: (error as Error).message });
    res.status(500).json({
      success: false,
      error: 'Failed to fetch user',
    });
  }
}

/**
 * PATCH /api/users/:id/assign-team
 * Assign user to a team (Admin only)
 */
export async function assignTeam(req: Request, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const { team_id, is_lead } = req.body;

    // Verify user exists
    const user = await prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      res.status(404).json({
        success: false,
        error: 'User not found',
      });
      return;
    }

    // Verify team exists (if assigning to a team)
    if (team_id) {
      const team = await prisma.team.findUnique({
        where: { id: team_id },
      });

      if (!team) {
        res.status(404).json({
          success: false,
          error: 'Team not found',
        });
        return;
      }
    }

    // Update user's team
    await prisma.user.update({
      where: { id },
      data: { team_id: team_id || null },
    });

    // If making user a lead, update team's lead_id and user's role
    if (is_lead && team_id) {
      await prisma.team.update({
        where: { id: team_id },
        data: { lead_id: id },
      });
      await prisma.user.update({
        where: { id },
        data: { role: 'LEAD' },
      });
    }

    // Fetch updated user
    const updatedUser = await prisma.user.findUnique({
      where: { id },
      include: {
        team: { select: { name: true } },
      },
    });

    logger.info('User team assignment', {
      userId: id,
      teamId: team_id,
      isLead: is_lead,
      assignedBy: req.user?.userId,
    });

    res.json({
      success: true,
      message: 'Team assignment updated',
      data: {
        user: {
          id: updatedUser!.id,
          full_name: updatedUser!.full_name,
          role: updatedUser!.role,
          team_id: updatedUser!.team_id,
          team_name: updatedUser!.team?.name || null,
        },
      },
    });
  } catch (error) {
    logger.error('Assign team error', { error: (error as Error).message });
    res.status(500).json({
      success: false,
      error: 'Failed to assign team',
    });
  }
}

/**
 * DELETE /api/users/:id
 * Soft delete a user (Admin only)
 */
export async function deleteUser(req: Request, res: Response): Promise<void> {
  try {
    const { id } = req.params;

    // Don't allow deleting yourself
    if (id === req.user?.userId) {
      res.status(400).json({
        success: false,
        error: 'You cannot delete your own account',
      });
      return;
    }

    // Soft delete - set is_active to false
    try {
      await prisma.user.update({
        where: { id },
        data: { is_active: false },
      });
    } catch (e) {
      res.status(404).json({
        success: false,
        error: 'User not found',
      });
      return;
    }

    logger.info('User deleted', {
      userId: id,
      deletedBy: req.user?.userId,
    });

    res.json({
      success: true,
      message: 'User deactivated successfully',
    });
  } catch (error) {
    logger.error('Delete user error', { error: (error as Error).message });
    res.status(500).json({
      success: false,
      error: 'Failed to delete user',
    });
  }
}

export default { listUsers, getUser, assignTeam, deleteUser };
