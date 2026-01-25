// Authentication Routes
// Purpose: Login, registration, and profile endpoints

import { Router } from 'express';
import { login, register, getProfile } from '../controllers/authController';
import { authenticate, authorize } from '../middlewares/auth';

const router = Router();

// Public routes (no auth required)
router.post('/login', login);

// Protected routes
router.get('/me', authenticate, getProfile);

// Admin only - register new users
router.post('/register', authenticate, authorize('ADMIN'), register);

export default router;
