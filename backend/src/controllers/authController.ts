// Authentication Controller
// Purpose: Handle login, registration, and token generation

import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import { query } from '../config/database';
import { generateToken } from '../middlewares/auth';
import { logger } from '../utils/logger';

/**
 * POST /api/auth/login
 * Authenticate user with mobile number and password
 * Returns JWT token and user info on success
 */
export async function login(req: Request, res: Response): Promise<void> {
  try {
    const { mobile_number, password } = req.body;
    
    // Validate required fields
    if (!mobile_number || !password) {
      res.status(400).json({
        success: false,
        error: 'Mobile number and password are required',
      });
      return;
    }
    
    // Find user by mobile number
    const result = await query(
      'SELECT id, mobile_number, password_hash, full_name, role, team_id, is_active FROM users WHERE mobile_number = $1',
      [mobile_number]
    );
    
    if (result.rows.length === 0) {
      logger.auth('failed_login', undefined, { reason: 'user_not_found', mobile_number });
      res.status(401).json({
        success: false,
        error: 'Invalid mobile number or password',
      });
      return;
    }
    
    const user = result.rows[0];
    
    // Check if user is active
    if (!user.is_active) {
      logger.auth('failed_login', user.id, { reason: 'account_deactivated' });
      res.status(401).json({
        success: false,
        error: 'Your account has been deactivated. Contact admin.',
      });
      return;
    }
    
    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    
    if (!isValidPassword) {
      logger.auth('failed_login', user.id, { reason: 'invalid_password' });
      res.status(401).json({
        success: false,
        error: 'Invalid mobile number or password',
      });
      return;
    }
    
    // Generate JWT token
    const token = generateToken({
      userId: user.id,
      mobile_number: user.mobile_number,
      role: user.role,
    });
    
    logger.auth('login', user.id, { role: user.role });
    
    // Return token and user info (exclude password_hash)
    res.json({
      success: true,
      data: {
        token,
        user: {
          id: user.id,
          mobile_number: user.mobile_number,
          full_name: user.full_name,
          role: user.role,
          team_id: user.team_id,
        },
      },
    });
  } catch (error) {
    logger.error('Login error', { error: (error as Error).message });
    res.status(500).json({
      success: false,
      error: 'Login failed. Please try again.',
    });
  }
}

/**
 * POST /api/auth/register
 * Register a new user (Admin only)
 * Creates user with hashed password
 */
export async function register(req: Request, res: Response): Promise<void> {
  try {
    const { mobile_number, password, full_name, role, team_id } = req.body;
    
    // Validate required fields
    if (!mobile_number || !password || !full_name || !role) {
      res.status(400).json({
        success: false,
        error: 'Mobile number, password, full name, and role are required',
      });
      return;
    }
    
    // Validate role
    const validRoles = ['ADMIN', 'LEAD', 'EMPLOYEE'];
    if (!validRoles.includes(role)) {
      res.status(400).json({
        success: false,
        error: `Invalid role. Must be one of: ${validRoles.join(', ')}`,
      });
      return;
    }
    
    // Validate password strength
    if (password.length < 6) {
      res.status(400).json({
        success: false,
        error: 'Password must be at least 6 characters',
      });
      return;
    }
    
    // Check if mobile number already exists
    const existingUser = await query(
      'SELECT id FROM users WHERE mobile_number = $1',
      [mobile_number]
    );
    
    if (existingUser.rows.length > 0) {
      res.status(409).json({
        success: false,
        error: 'Mobile number already registered',
      });
      return;
    }
    
    // Hash password with bcrypt (10 rounds)
    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);
    
    // Insert new user
    const result = await query(
      `INSERT INTO users (mobile_number, password_hash, full_name, role, team_id) 
       VALUES ($1, $2, $3, $4, $5) 
       RETURNING id, mobile_number, full_name, role, team_id, created_at`,
      [mobile_number, password_hash, full_name, role, team_id || null]
    );
    
    const newUser = result.rows[0];
    
    logger.auth('register', newUser.id, { 
      role: newUser.role, 
      createdBy: req.user?.userId 
    });
    
    res.status(201).json({
      success: true,
      data: {
        user: newUser,
      },
    });
  } catch (error) {
    logger.error('Registration error', { error: (error as Error).message });
    res.status(500).json({
      success: false,
      error: 'Registration failed. Please try again.',
    });
  }
}

/**
 * GET /api/auth/me
 * Get current authenticated user's profile
 */
export async function getProfile(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user?.userId;
    
    const result = await query(
      `SELECT u.id, u.mobile_number, u.full_name, u.role, u.team_id, u.created_at,
              t.name as team_name
       FROM users u
       LEFT JOIN teams t ON u.team_id = t.id
       WHERE u.id = $1`,
      [userId]
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
    logger.error('Get profile error', { error: (error as Error).message });
    res.status(500).json({
      success: false,
      error: 'Failed to fetch profile',
    });
  }
}

export default { login, register, getProfile };
