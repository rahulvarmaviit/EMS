// Main Routes Index
// Purpose: Aggregate all route modules

import { Router } from 'express';
import authRoutes from './authRoutes';
import userRoutes from './userRoutes';
import teamRoutes from './teamRoutes';
import locationRoutes from './locationRoutes';
import attendanceRoutes from './attendanceRoutes';

const router = Router();

// Mount route modules
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/teams', teamRoutes);
router.use('/locations', locationRoutes);
router.use('/attendance', attendanceRoutes);

export default router;
