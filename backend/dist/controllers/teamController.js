"use strict";
// Team Controller
// Purpose: Team management operations (Admin access)
Object.defineProperty(exports, "__esModule", { value: true });
exports.listTeams = listTeams;
exports.createTeam = createTeam;
exports.getTeam = getTeam;
exports.updateTeam = updateTeam;
exports.deleteTeam = deleteTeam;
const database_1 = require("../config/database");
const logger_1 = require("../utils/logger");
/**
 * GET /api/teams
 * List all teams with lead info
 */
async function listTeams(req, res) {
    try {
        const result = await (0, database_1.query)(`
      SELECT t.id, t.name, t.lead_id, t.is_active, t.created_at,
             u.full_name as lead_name, u.mobile_number as lead_mobile,
             (SELECT COUNT(*) FROM users WHERE team_id = t.id AND is_active = true) as member_count
      FROM teams t
      LEFT JOIN users u ON t.lead_id = u.id
      WHERE t.is_active = true
      ORDER BY t.name
    `);
        res.json({
            success: true,
            data: {
                teams: result.rows,
            },
        });
    }
    catch (error) {
        logger_1.logger.error('List teams error', { error: error.message });
        res.status(500).json({
            success: false,
            error: 'Failed to fetch teams',
        });
    }
}
/**
 * POST /api/teams
 * Create a new team (Admin only)
 */
async function createTeam(req, res) {
    try {
        const { name, lead_id } = req.body;
        // Validate required fields
        if (!name || name.trim().length === 0) {
            res.status(400).json({
                success: false,
                error: 'Team name is required',
            });
            return;
        }
        // Check if team name already exists
        const existingTeam = await (0, database_1.query)('SELECT id FROM teams WHERE LOWER(name) = LOWER($1) AND is_active = true', [name.trim()]);
        if (existingTeam.rows.length > 0) {
            res.status(409).json({
                success: false,
                error: 'A team with this name already exists',
            });
            return;
        }
        // Verify lead exists if provided
        if (lead_id) {
            const leadResult = await (0, database_1.query)('SELECT id FROM users WHERE id = $1 AND is_active = true', [lead_id]);
            if (leadResult.rows.length === 0) {
                res.status(404).json({
                    success: false,
                    error: 'Lead user not found',
                });
                return;
            }
        }
        // Create team
        const result = await (0, database_1.query)(`INSERT INTO teams (name, lead_id)
       VALUES ($1, $2)
       RETURNING id, name, lead_id, created_at`, [name.trim(), lead_id || null]);
        const newTeam = result.rows[0];
        // If lead assigned, update lead's role and team_id
        if (lead_id) {
            await (0, database_1.query)('UPDATE users SET role = $1, team_id = $2 WHERE id = $3', ['LEAD', newTeam.id, lead_id]);
        }
        logger_1.logger.info('Team created', {
            teamId: newTeam.id,
            teamName: newTeam.name,
            leadId: lead_id,
            createdBy: req.user?.userId,
        });
        res.status(201).json({
            success: true,
            message: 'Team created successfully',
            data: {
                team: newTeam,
            },
        });
    }
    catch (error) {
        logger_1.logger.error('Create team error', { error: error.message });
        res.status(500).json({
            success: false,
            error: 'Failed to create team',
        });
    }
}
/**
 * GET /api/teams/:id
 * Get single team with members
 */
async function getTeam(req, res) {
    try {
        const { id } = req.params;
        // Get team details
        const teamResult = await (0, database_1.query)(`
      SELECT t.id, t.name, t.lead_id, t.is_active, t.created_at,
             u.full_name as lead_name, u.mobile_number as lead_mobile
      FROM teams t
      LEFT JOIN users u ON t.lead_id = u.id
      WHERE t.id = $1
    `, [id]);
        if (teamResult.rows.length === 0) {
            res.status(404).json({
                success: false,
                error: 'Team not found',
            });
            return;
        }
        // Get team members
        const membersResult = await (0, database_1.query)(`
      SELECT id, full_name, mobile_number, role
      FROM users
      WHERE team_id = $1 AND is_active = true
      ORDER BY role, full_name
    `, [id]);
        res.json({
            success: true,
            data: {
                team: teamResult.rows[0],
                members: membersResult.rows,
            },
        });
    }
    catch (error) {
        logger_1.logger.error('Get team error', { error: error.message });
        res.status(500).json({
            success: false,
            error: 'Failed to fetch team',
        });
    }
}
/**
 * PATCH /api/teams/:id
 * Update team (Admin only)
 */
async function updateTeam(req, res) {
    try {
        const { id } = req.params;
        const { name, lead_id } = req.body;
        // Verify team exists
        const existingTeam = await (0, database_1.query)('SELECT id, lead_id FROM teams WHERE id = $1', [id]);
        if (existingTeam.rows.length === 0) {
            res.status(404).json({
                success: false,
                error: 'Team not found',
            });
            return;
        }
        const oldLeadId = existingTeam.rows[0].lead_id;
        // Build update query dynamically
        const updates = [];
        const values = [];
        let paramIndex = 1;
        if (name !== undefined) {
            updates.push(`name = $${paramIndex}`);
            values.push(name.trim());
            paramIndex++;
        }
        if (lead_id !== undefined) {
            // Verify new lead exists
            if (lead_id) {
                const leadResult = await (0, database_1.query)('SELECT id FROM users WHERE id = $1 AND is_active = true', [lead_id]);
                if (leadResult.rows.length === 0) {
                    res.status(404).json({
                        success: false,
                        error: 'Lead user not found',
                    });
                    return;
                }
            }
            updates.push(`lead_id = $${paramIndex}`);
            values.push(lead_id || null);
            paramIndex++;
        }
        if (updates.length === 0) {
            res.status(400).json({
                success: false,
                error: 'No fields to update',
            });
            return;
        }
        values.push(id);
        const result = await (0, database_1.query)(`UPDATE teams SET ${updates.join(', ')} WHERE id = $${paramIndex} RETURNING *`, values);
        // Update user roles if lead changed
        if (lead_id !== undefined && lead_id !== oldLeadId) {
            // Demote old lead to EMPLOYEE
            if (oldLeadId) {
                await (0, database_1.query)('UPDATE users SET role = $1 WHERE id = $2', ['EMPLOYEE', oldLeadId]);
            }
            // Promote new lead
            if (lead_id) {
                await (0, database_1.query)('UPDATE users SET role = $1, team_id = $2 WHERE id = $3', ['LEAD', id, lead_id]);
            }
        }
        logger_1.logger.info('Team updated', {
            teamId: id,
            updatedBy: req.user?.userId,
        });
        res.json({
            success: true,
            message: 'Team updated successfully',
            data: {
                team: result.rows[0],
            },
        });
    }
    catch (error) {
        logger_1.logger.error('Update team error', { error: error.message });
        res.status(500).json({
            success: false,
            error: 'Failed to update team',
        });
    }
}
/**
 * DELETE /api/teams/:id
 * Soft delete a team (Admin only)
 */
async function deleteTeam(req, res) {
    try {
        const { id } = req.params;
        // Check if team has members
        const membersResult = await (0, database_1.query)('SELECT COUNT(*) FROM users WHERE team_id = $1 AND is_active = true', [id]);
        if (parseInt(membersResult.rows[0].count, 10) > 0) {
            res.status(400).json({
                success: false,
                error: 'Cannot delete team with active members. Reassign members first.',
            });
            return;
        }
        // Soft delete
        const result = await (0, database_1.query)('UPDATE teams SET is_active = false WHERE id = $1 RETURNING id, name', [id]);
        if (result.rows.length === 0) {
            res.status(404).json({
                success: false,
                error: 'Team not found',
            });
            return;
        }
        logger_1.logger.info('Team deleted', {
            teamId: id,
            deletedBy: req.user?.userId,
        });
        res.json({
            success: true,
            message: 'Team deleted successfully',
        });
    }
    catch (error) {
        logger_1.logger.error('Delete team error', { error: error.message });
        res.status(500).json({
            success: false,
            error: 'Failed to delete team',
        });
    }
}
exports.default = { listTeams, createTeam, getTeam, updateTeam, deleteTeam };
//# sourceMappingURL=teamController.js.map