"use strict";
// Attendance Controller
// Purpose: Handle check-in, check-out, and attendance history
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkIn = checkIn;
exports.checkOut = checkOut;
exports.getSelfAttendance = getSelfAttendance;
exports.getTeamAttendance = getTeamAttendance;
const database_1 = require("../config/database");
const geoService_1 = require("../services/geoService");
const logger_1 = require("../utils/logger");
const env_1 = __importDefault(require("../config/env"));
/**
 * POST /api/attendance/check-in
 * Record user check-in with GPS validation
 */
async function checkIn(req, res) {
    try {
        const userId = req.user?.userId;
        const { latitude, longitude } = req.body;
        // Validate coordinates
        if (!(0, geoService_1.validateCoordinates)(latitude, longitude)) {
            res.status(400).json({
                success: false,
                error: 'Invalid GPS coordinates. Please enable location services.',
            });
            return;
        }
        // Check if already checked in today
        const today = new Date().toISOString().split('T')[0];
        const existingAttendance = await (0, database_1.query)('SELECT id, check_in_time FROM attendance WHERE user_id = $1 AND date = $2', [userId, today]);
        if (existingAttendance.rows.length > 0) {
            res.status(400).json({
                success: false,
                error: 'You have already checked in today',
                data: {
                    check_in_time: existingAttendance.rows[0].check_in_time,
                },
            });
            return;
        }
        // Get all active office locations
        const locationsResult = await (0, database_1.query)('SELECT id, name, latitude, longitude, radius_meters FROM locations WHERE is_active = true');
        if (locationsResult.rows.length === 0) {
            res.status(400).json({
                success: false,
                error: 'No office locations configured. Contact admin.',
            });
            return;
        }
        // Server-side geofence validation (never trust client)
        const locations = locationsResult.rows.map(row => ({
            id: row.id,
            name: row.name,
            latitude: parseFloat(row.latitude),
            longitude: parseFloat(row.longitude),
            radius_meters: row.radius_meters,
        }));
        const matchingLocation = (0, geoService_1.isWithinGeofence)(latitude, longitude, locations);
        if (!matchingLocation) {
            logger_1.logger.attendance('geo_rejected', userId, {
                latitude,
                longitude,
                nearestLocations: locations.map(l => l.name),
            });
            res.status(400).json({
                success: false,
                error: 'You are not within any office location. Please move closer to check in.',
            });
            return;
        }
        // Determine status (on-time or late)
        const now = new Date();
        const checkInHour = now.getHours();
        const checkInMinutes = now.getMinutes();
        // Late threshold: After 9:15 AM (configurable)
        let status = 'PRESENT';
        if (checkInHour > 9 || (checkInHour === 9 && checkInMinutes > env_1.default.LATE_THRESHOLD_MINUTES)) {
            status = 'LATE';
        }
        // Record check-in
        const result = await (0, database_1.query)(`INSERT INTO attendance (user_id, date, check_in_time, check_in_lat, check_in_long, status)
       VALUES ($1, $2, NOW(), $3, $4, $5)
       RETURNING id, date, check_in_time, status`, [userId, today, latitude, longitude, status]);
        logger_1.logger.attendance('check_in', userId, {
            location: matchingLocation.name,
            status,
            coordinates: { latitude, longitude },
        });
        res.status(201).json({
            success: true,
            message: `Checked in at ${matchingLocation.name}`,
            data: {
                attendance: result.rows[0],
                location: matchingLocation.name,
            },
        });
    }
    catch (error) {
        logger_1.logger.error('Check-in error', { error: error.message });
        res.status(500).json({
            success: false,
            error: 'Check-in failed. Please try again.',
        });
    }
}
/**
 * POST /api/attendance/check-out
 * Record user check-out with GPS validation
 */
async function checkOut(req, res) {
    try {
        const userId = req.user?.userId;
        const { latitude, longitude } = req.body;
        // Validate coordinates
        if (!(0, geoService_1.validateCoordinates)(latitude, longitude)) {
            res.status(400).json({
                success: false,
                error: 'Invalid GPS coordinates. Please enable location services.',
            });
            return;
        }
        // Find today's check-in record
        const today = new Date().toISOString().split('T')[0];
        const existingAttendance = await (0, database_1.query)('SELECT id, check_in_time, check_out_time, status FROM attendance WHERE user_id = $1 AND date = $2', [userId, today]);
        if (existingAttendance.rows.length === 0) {
            res.status(400).json({
                success: false,
                error: 'You have not checked in today. Please check in first.',
            });
            return;
        }
        const attendance = existingAttendance.rows[0];
        if (attendance.check_out_time) {
            res.status(400).json({
                success: false,
                error: 'You have already checked out today',
                data: {
                    check_out_time: attendance.check_out_time,
                },
            });
            return;
        }
        // Calculate work hours and update status if needed
        const checkInTime = new Date(attendance.check_in_time);
        const checkOutTime = new Date();
        const hoursWorked = (checkOutTime.getTime() - checkInTime.getTime()) / (1000 * 60 * 60);
        let status = attendance.status;
        if (hoursWorked < env_1.default.HALF_DAY_HOURS) {
            status = 'HALF_DAY';
        }
        // Update attendance record
        const result = await (0, database_1.query)(`UPDATE attendance 
       SET check_out_time = NOW(), check_out_lat = $1, check_out_long = $2, status = $3
       WHERE id = $4
       RETURNING id, date, check_in_time, check_out_time, status`, [latitude, longitude, status, attendance.id]);
        logger_1.logger.attendance('check_out', userId, {
            hoursWorked: hoursWorked.toFixed(2),
            status,
        });
        res.json({
            success: true,
            message: 'Checked out successfully',
            data: {
                attendance: result.rows[0],
                hoursWorked: hoursWorked.toFixed(2),
            },
        });
    }
    catch (error) {
        logger_1.logger.error('Check-out error', { error: error.message });
        res.status(500).json({
            success: false,
            error: 'Check-out failed. Please try again.',
        });
    }
}
/**
 * GET /api/attendance/self
 * Get current user's attendance history
 */
async function getSelfAttendance(req, res) {
    try {
        const userId = req.user?.userId;
        const { page = 1, limit = 30 } = req.query;
        const pageNum = Math.max(1, parseInt(page, 10));
        const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10)));
        const offset = (pageNum - 1) * limitNum;
        // Get attendance records with pagination
        const result = await (0, database_1.query)(`SELECT id, date, check_in_time, check_out_time, status
       FROM attendance 
       WHERE user_id = $1 
       ORDER BY date DESC
       LIMIT $2 OFFSET $3`, [userId, limitNum, offset]);
        // Get total count for pagination
        const countResult = await (0, database_1.query)('SELECT COUNT(*) FROM attendance WHERE user_id = $1', [userId]);
        const total = parseInt(countResult.rows[0].count, 10);
        res.json({
            success: true,
            data: {
                attendance: result.rows,
                pagination: {
                    page: pageNum,
                    limit: limitNum,
                    total,
                    totalPages: Math.ceil(total / limitNum),
                },
            },
        });
    }
    catch (error) {
        logger_1.logger.error('Get self attendance error', { error: error.message });
        res.status(500).json({
            success: false,
            error: 'Failed to fetch attendance history',
        });
    }
}
/**
 * GET /api/attendance/team/:teamId
 * Get team attendance (Lead/Admin only)
 */
async function getTeamAttendance(req, res) {
    try {
        const { teamId } = req.params;
        const { date, page = 1, limit = 50 } = req.query;
        const userRole = req.user?.role;
        const userId = req.user?.userId;
        // If Lead, verify they are the lead of this team
        if (userRole === 'LEAD') {
            const teamCheck = await (0, database_1.query)('SELECT id FROM teams WHERE id = $1 AND lead_id = $2', [teamId, userId]);
            if (teamCheck.rows.length === 0) {
                res.status(403).json({
                    success: false,
                    error: 'You can only view attendance for your own team',
                });
                return;
            }
        }
        const pageNum = Math.max(1, parseInt(page, 10));
        const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10)));
        const offset = (pageNum - 1) * limitNum;
        // Get team members' attendance
        let queryText = `
      SELECT a.id, a.date, a.check_in_time, a.check_out_time, a.status,
             u.id as user_id, u.full_name, u.mobile_number
      FROM attendance a
      JOIN users u ON a.user_id = u.id
      WHERE u.team_id = $1
    `;
        const queryParams = [teamId];
        // Filter by date if provided
        if (date) {
            queryText += ' AND a.date = $2';
            queryParams.push(date);
        }
        queryText += ' ORDER BY a.date DESC, u.full_name LIMIT $' + (queryParams.length + 1) + ' OFFSET $' + (queryParams.length + 2);
        queryParams.push(limitNum, offset);
        const result = await (0, database_1.query)(queryText, queryParams);
        // Get total count
        let countQuery = 'SELECT COUNT(*) FROM attendance a JOIN users u ON a.user_id = u.id WHERE u.team_id = $1';
        const countParams = [teamId];
        if (date) {
            countQuery += ' AND a.date = $2';
            countParams.push(date);
        }
        const countResult = await (0, database_1.query)(countQuery, countParams);
        const total = parseInt(countResult.rows[0].count, 10);
        res.json({
            success: true,
            data: {
                attendance: result.rows,
                pagination: {
                    page: pageNum,
                    limit: limitNum,
                    total,
                    totalPages: Math.ceil(total / limitNum),
                },
            },
        });
    }
    catch (error) {
        logger_1.logger.error('Get team attendance error', { error: error.message });
        res.status(500).json({
            success: false,
            error: 'Failed to fetch team attendance',
        });
    }
}
exports.default = { checkIn, checkOut, getSelfAttendance, getTeamAttendance };
//# sourceMappingURL=attendanceController.js.map