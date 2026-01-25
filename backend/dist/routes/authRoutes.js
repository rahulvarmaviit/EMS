"use strict";
// Authentication Routes
// Purpose: Login, registration, and profile endpoints
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const authController_1 = require("../controllers/authController");
const auth_1 = require("../middlewares/auth");
const router = (0, express_1.Router)();
// Public routes (no auth required)
router.post('/login', authController_1.login);
// Protected routes
router.get('/me', auth_1.authenticate, authController_1.getProfile);
// Admin only - register new users
router.post('/register', auth_1.authenticate, (0, auth_1.authorize)('ADMIN'), authController_1.register);
exports.default = router;
//# sourceMappingURL=authRoutes.js.map