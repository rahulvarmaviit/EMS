// Authentication Routes
// Purpose: Login, registration, and profile endpoints

import { Router } from 'express';
import { login, register, getProfile } from '../controllers/authController';
import { authenticate, optionalAuthenticate, authorize } from '../middlewares/auth';

const router = Router();

// Public routes (no auth required)
router.post('/login', login);

// Self-registration for employees (optional auth to allow admin override)
router.post('/signup', optionalAuthenticate, register);

// Protected routes
router.get('/me', authenticate, getProfile);

// Admin only - register new users with role assignment
router.post('/register', authenticate, authorize('ADMIN'), register);

export default router;
