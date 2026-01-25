"use strict";
// Location Routes
// Purpose: Office location management endpoints
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const locationController_1 = require("../controllers/locationController");
const auth_1 = require("../middlewares/auth");
const router = (0, express_1.Router)();
// All routes require authentication
router.use(auth_1.authenticate);
// All authenticated users can view locations
router.get('/', locationController_1.listLocations);
// Admin only - create, update, delete locations
router.post('/', (0, auth_1.authorize)('ADMIN'), locationController_1.createLocation);
router.patch('/:id', (0, auth_1.authorize)('ADMIN'), locationController_1.updateLocation);
router.delete('/:id', (0, auth_1.authorize)('ADMIN'), locationController_1.deleteLocation);
exports.default = router;
//# sourceMappingURL=locationRoutes.js.map