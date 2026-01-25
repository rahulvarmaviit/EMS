// Location Controller
// Purpose: Office location management (Admin only)

import { Request, Response } from 'express';
import { query } from '../config/database';
import { validateCoordinates } from '../services/geoService';
import { logger } from '../utils/logger';

/**
 * GET /api/locations
 * List all office locations
 */
export async function listLocations(req: Request, res: Response): Promise<void> {
  try {
    const result = await query(`
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
  } catch (error) {
    logger.error('List locations error', { error: (error as Error).message });
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
export async function createLocation(req: Request, res: Response): Promise<void> {
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
    if (!validateCoordinates(latitude, longitude)) {
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
    const result = await query(
      `INSERT INTO locations (name, latitude, longitude, radius_meters)
       VALUES ($1, $2, $3, $4)
       RETURNING id, name, latitude, longitude, radius_meters, created_at`,
      [name.trim(), latitude, longitude, radius_meters]
    );
    
    logger.info('Location created', {
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
  } catch (error) {
    logger.error('Create location error', { error: (error as Error).message });
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
export async function updateLocation(req: Request, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const { name, latitude, longitude, radius_meters } = req.body;
    
    // Verify location exists
    const existingLocation = await query(
      'SELECT id FROM locations WHERE id = $1',
      [id]
    );
    
    if (existingLocation.rows.length === 0) {
      res.status(404).json({
        success: false,
        error: 'Location not found',
      });
      return;
    }
    
    // Build update query dynamically
    const updates: string[] = [];
    const values: any[] = [];
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
      
      if (!validateCoordinates(latitude, longitude)) {
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
    
    const result = await query(
      `UPDATE locations SET ${updates.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );
    
    logger.info('Location updated', {
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
  } catch (error) {
    logger.error('Update location error', { error: (error as Error).message });
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
export async function deleteLocation(req: Request, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    
    const result = await query(
      'UPDATE locations SET is_active = false WHERE id = $1 RETURNING id, name',
      [id]
    );
    
    if (result.rows.length === 0) {
      res.status(404).json({
        success: false,
        error: 'Location not found',
      });
      return;
    }
    
    logger.info('Location deleted', {
      locationId: id,
      deletedBy: req.user?.userId,
    });
    
    res.json({
      success: true,
      message: 'Location deleted successfully',
    });
  } catch (error) {
    logger.error('Delete location error', { error: (error as Error).message });
    res.status(500).json({
      success: false,
      error: 'Failed to delete location',
    });
  }
}

export default { listLocations, createLocation, updateLocation, deleteLocation };
