// User Controller
// Purpose: User management operations (Admin/Lead access)

import { Request, Response } from 'express';
import { query } from '../config/database';
import { logger } from '../utils/logger';

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
    const offset = (pageNum - 1) * limitNum;
    
    let queryText = `
      SELECT u.id, u.mobile_number, u.full_name, u.role, u.team_id, u.is_active, u.created_at,
             t.name as team_name
      FROM users u
      LEFT JOIN teams t ON u.team_id = t.id
      WHERE u.is_active = true
    `;
    const queryParams: any[] = [];
    let paramIndex = 1;
    
    // Lead can only see their team members
    if (userRole === 'LEAD') {
      const teamResult = await query(
        'SELECT id FROM teams WHERE lead_id = $1',
        [userId]
      );
      
      if (teamResult.rows.length > 0) {
        queryText += ` AND u.team_id = $${paramIndex}`;
        queryParams.push(teamResult.rows[0].id);
        paramIndex++;
      } else {
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
    } else {
      // Admin can filter by team_id
      if (team_id) {
        queryText += ` AND u.team_id = $${paramIndex}`;
        queryParams.push(team_id);
        paramIndex++;
      }
    }
    
    // Filter by role
    if (role) {
      queryText += ` AND u.role = $${paramIndex}`;
      queryParams.push(role);
      paramIndex++;
    }
    
    // Build separate count query with proper parameters
    let countQueryText = `
      SELECT COUNT(*) 
      FROM users u
      LEFT JOIN teams t ON u.team_id = t.id
      WHERE u.is_active = true
    `;
    const countParams: any[] = [];
    let countParamIndex = 1;
    
    // Apply same filters for count
    if (userRole === 'LEAD') {
      const teamResult = await query('SELECT id FROM teams WHERE lead_id = $1', [userId]);
      if (teamResult.rows.length > 0) {
        countQueryText += ` AND u.team_id = $${countParamIndex}`;
        countParams.push(teamResult.rows[0].id);
        countParamIndex++;
      }
    } else if (team_id) {
      countQueryText += ` AND u.team_id = $${countParamIndex}`;
      countParams.push(team_id);
      countParamIndex++;
    }
    
    if (role) {
      countQueryText += ` AND u.role = $${countParamIndex}`;
      countParams.push(role);
    }
    
    // Add ordering and pagination to main query
    queryText += ` ORDER BY u.full_name LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    queryParams.push(limitNum, offset);
    
    const result = await query(queryText, queryParams);
    
    // Get count with proper separate query
    const countResult = await query(countQueryText, countParams);
    const total = parseInt(countResult.rows[0].count, 10);
    
    res.json({
      success: true,
      data: {
        users: result.rows,
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
    
    const result = await query(
      `SELECT u.id, u.mobile_number, u.full_name, u.role, u.team_id, u.is_active, u.created_at,
              t.name as team_name,
              lead.full_name as team_lead_name
       FROM users u
       LEFT JOIN teams t ON u.team_id = t.id
       LEFT JOIN users lead ON t.lead_id = lead.id
       WHERE u.id = $1`,
      [id]
    );
    
    if (result.rows.length === 0) {
      res.status(404).json({
        success: false,
        error: 'User not found',
      });
      return;
    }
    
    res.json({
      success: true,
      data: {
        user: result.rows[0],
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
    const userResult = await query(
      'SELECT id, role FROM users WHERE id = $1',
      [id]
    );
    
    if (userResult.rows.length === 0) {
      res.status(404).json({
        success: false,
        error: 'User not found',
      });
      return;
    }
    
    // Verify team exists (if assigning to a team)
    if (team_id) {
      const teamResult = await query(
        'SELECT id FROM teams WHERE id = $1',
        [team_id]
      );
      
      if (teamResult.rows.length === 0) {
        res.status(404).json({
          success: false,
          error: 'Team not found',
        });
        return;
      }
    }
    
    // Update user's team
    await query(
      'UPDATE users SET team_id = $1 WHERE id = $2',
      [team_id || null, id]
    );
    
    // If making user a lead, update team's lead_id and user's role
    if (is_lead && team_id) {
      await query('UPDATE teams SET lead_id = $1 WHERE id = $2', [id, team_id]);
      await query('UPDATE users SET role = $1 WHERE id = $2', ['LEAD', id]);
    }
    
    // Fetch updated user
    const result = await query(
      `SELECT u.id, u.full_name, u.role, u.team_id, t.name as team_name
       FROM users u
       LEFT JOIN teams t ON u.team_id = t.id
       WHERE u.id = $1`,
      [id]
    );
    
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
        user: result.rows[0],
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
    const result = await query(
      'UPDATE users SET is_active = false WHERE id = $1 RETURNING id, full_name',
      [id]
    );
    
    if (result.rows.length === 0) {
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
