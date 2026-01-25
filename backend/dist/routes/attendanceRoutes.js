"use strict";
// Attendance Routes
// Purpose: Check-in, check-out, and attendance history endpoints
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const attendanceController_1 = require("../controllers/attendanceController");
const auth_1 = require("../middlewares/auth");
const router = (0, express_1.Router)();
// All routes require authentication
router.use(auth_1.authenticate);
// All authenticated users can check in/out and view their own history
router.post('/check-in', attendanceController_1.checkIn);
router.post('/check-out', attendanceController_1.checkOut);
router.get('/self', attendanceController_1.getSelfAttendance);
// Admin and Lead can view team attendance
router.get('/team/:teamId', (0, auth_1.authorize)('ADMIN', 'LEAD'), attendanceController_1.getTeamAttendance);
exports.default = router;
//# sourceMappingURL=attendanceRoutes.js.map