"use strict";
// Team Routes
// Purpose: Team management endpoints
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const teamController_1 = require("../controllers/teamController");
const auth_1 = require("../middlewares/auth");
const router = (0, express_1.Router)();
// All routes require authentication
router.use(auth_1.authenticate);
// All authenticated users can view teams
router.get('/', teamController_1.listTeams);
router.get('/:id', teamController_1.getTeam);
// Admin only - create, update, delete teams
router.post('/', (0, auth_1.authorize)('ADMIN'), teamController_1.createTeam);
router.patch('/:id', (0, auth_1.authorize)('ADMIN'), teamController_1.updateTeam);
router.delete('/:id', (0, auth_1.authorize)('ADMIN'), teamController_1.deleteTeam);
exports.default = router;
//# sourceMappingURL=teamRoutes.js.map