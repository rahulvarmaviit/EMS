"use strict";
// Location Controller
// Purpose: Office location management (Admin only)
Object.defineProperty(exports, "__esModule", { value: true });
exports.listLocations = listLocations;
exports.createLocation = createLocation;
exports.updateLocation = updateLocation;
exports.deleteLocation = deleteLocation;
const database_1 = require("../config/database");
const geoService_1 = require("../services/geoService");
const logger_1 = require("../utils/logger");
/**
 * GET /api/locations
 * List all office locations
 */
async function listLocations(req, res) {
    try {
        const result = await (0, database_1.query)(`
      SELECT id, name, latitude, longitude, radius_meters, is_active, created_at
      FROM locations
      WHERE is_active = true
      ORDER BY name
    `);
        res.json({
            success: true,
            data: {
                locations: result.rows,
            },
        });
    }
    catch (error) {
        logger_1.logger.error('List locations error', { error: error.message });
        res.status(500).json({
            success: false,
            error: 'Failed to fetch locations',
        });
    }
}
/**
 * POST /api/locations
 * Create a new office location (Admin only)
 */
async function createLocation(req, res) {
    try {
        const { name, latitude, longitude, radius_meters = 50 } = req.body;
        // Validate required fields
        if (!name || name.trim().length === 0) {
            res.status(400).json({
                success: false,
                error: 'Location name is required',
            });
            return;
        }
        // Validate coordinates
        if (!(0, geoService_1.validateCoordinates)(latitude, longitude)) {
            res.status(400).json({
                success: false,
                error: 'Invalid GPS coordinates. Latitude must be -90 to 90, Longitude must be -180 to 180.',
            });
            return;
        }
        // Validate radius
        if (radius_meters < 1 || radius_meters > 1000) {
            res.status(400).json({
                success: false,
                error: 'Radius must be between 1 and 1000 meters',
            });
            return;
        }
        // Create location
        const result = await (0, database_1.query)(`INSERT INTO locations (name, latitude, longitude, radius_meters)
       VALUES ($1, $2, $3, $4)
       RETURNING id, name, latitude, longitude, radius_meters, created_at`, [name.trim(), latitude, longitude, radius_meters]);
        logger_1.logger.info('Location created', {
            locationId: result.rows[0].id,
            name: name.trim(),
            createdBy: req.user?.userId,
        });
        res.status(201).json({
            success: true,
            message: 'Location created successfully',
            data: {
                location: result.rows[0],
            },
        });
    }
    catch (error) {
        logger_1.logger.error('Create location error', { error: error.message });
        res.status(500).json({
            success: false,
            error: 'Failed to create location',
        });
    }
}
/**
 * PATCH /api/locations/:id
 * Update office location (Admin only)
 */
async function updateLocation(req, res) {
    try {
        const { id } = req.params;
        const { name, latitude, longitude, radius_meters } = req.body;
        // Verify location exists
        const existingLocation = await (0, database_1.query)('SELECT id FROM locations WHERE id = $1', [id]);
        if (existingLocation.rows.length === 0) {
            res.status(404).json({
                success: false,
                error: 'Location not found',
            });
            return;
        }
        // Build update query dynamically
        const updates = [];
        const values = [];
        let paramIndex = 1;
        if (name !== undefined) {
            updates.push(`name = $${paramIndex}`);
            values.push(name.trim());
            paramIndex++;
        }
        if (latitude !== undefined || longitude !== undefined) {
            // If updating coordinates, need both
            if ((latitude !== undefined) !== (longitude !== undefined)) {
                res.status(400).json({
                    success: false,
                    error: 'Both latitude and longitude must be provided together',
                });
                return;
            }
            if (!(0, geoService_1.validateCoordinates)(latitude, longitude)) {
                res.status(400).json({
                    success: false,
                    error: 'Invalid GPS coordinates',
                });
                return;
            }
            updates.push(`latitude = $${paramIndex}`);
            values.push(latitude);
            paramIndex++;
            updates.push(`longitude = $${paramIndex}`);
            values.push(longitude);
            paramIndex++;
        }
        if (radius_meters !== undefined) {
            if (radius_meters < 1 || radius_meters > 1000) {
                res.status(400).json({
                    success: false,
                    error: 'Radius must be between 1 and 1000 meters',
                });
                return;
            }
            updates.push(`radius_meters = $${paramIndex}`);
            values.push(radius_meters);
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
        const result = await (0, database_1.query)(`UPDATE locations SET ${updates.join(', ')} WHERE id = $${paramIndex} RETURNING *`, values);
        logger_1.logger.info('Location updated', {
            locationId: id,
            updatedBy: req.user?.userId,
        });
        res.json({
            success: true,
            message: 'Location updated successfully',
            data: {
                location: result.rows[0],
            },
        });
    }
    catch (error) {
        logger_1.logger.error('Update location error', { error: error.message });
        res.status(500).json({
            success: false,
            error: 'Failed to update location',
        });
    }
}
/**
 * DELETE /api/locations/:id
 * Soft delete a location (Admin only)
 */
async function deleteLocation(req, res) {
    try {
        const { id } = req.params;
        const result = await (0, database_1.query)('UPDATE locations SET is_active = false WHERE id = $1 RETURNING id, name', [id]);
        if (result.rows.length === 0) {
            res.status(404).json({
                success: false,
                error: 'Location not found',
            });
            return;
        }
        logger_1.logger.info('Location deleted', {
            locationId: id,
            deletedBy: req.user?.userId,
        });
        res.json({
            success: true,
            message: 'Location deleted successfully',
        });
    }
    catch (error) {
        logger_1.logger.error('Delete location error', { error: error.message });
        res.status(500).json({
            success: false,
            error: 'Failed to delete location',
        });
    }
}
exports.default = { listLocations, createLocation, updateLocation, deleteLocation };
//# sourceMappingURL=locationController.js.map