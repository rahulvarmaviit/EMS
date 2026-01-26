
import { Router } from 'express';
import leaveController from '../controllers/leaveController';
import { authenticate } from '../middlewares/auth';

const router = Router();

// Apply auth middleware to all routes
router.use(authenticate);

// Create new leave request
router.post('/', leaveController.createLeaveRequest);

// Get my leave history
router.get('/self', leaveController.getMyLeaves);

// Get team leave requests (Lead/Admin)
router.get('/team', leaveController.getTeamLeaves);

export default router;
