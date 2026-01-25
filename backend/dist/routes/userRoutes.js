"use strict";
// User Routes
// Purpose: User management endpoints
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const userController_1 = require("../controllers/userController");
const auth_1 = require("../middlewares/auth");
const router = (0, express_1.Router)();
// All routes require authentication
router.use(auth_1.authenticate);
// Admin and Lead can list users
router.get('/', (0, auth_1.authorize)('ADMIN', 'LEAD'), userController_1.listUsers);
// Admin and Lead can view user details
router.get('/:id', (0, auth_1.authorize)('ADMIN', 'LEAD'), userController_1.getUser);
// Admin only - assign team
router.patch('/:id/assign-team', (0, auth_1.authorize)('ADMIN'), userController_1.assignTeam);
// Admin only - delete user
router.delete('/:id', (0, auth_1.authorize)('ADMIN'), userController_1.deleteUser);
exports.default = router;
//# sourceMappingURL=userRoutes.js.map