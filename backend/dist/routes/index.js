"use strict";
// Main Routes Index
// Purpose: Aggregate all route modules
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const authRoutes_1 = __importDefault(require("./authRoutes"));
const userRoutes_1 = __importDefault(require("./userRoutes"));
const teamRoutes_1 = __importDefault(require("./teamRoutes"));
const locationRoutes_1 = __importDefault(require("./locationRoutes"));
const attendanceRoutes_1 = __importDefault(require("./attendanceRoutes"));
const router = (0, express_1.Router)();
// Mount route modules
router.use('/auth', authRoutes_1.default);
router.use('/users', userRoutes_1.default);
router.use('/teams', teamRoutes_1.default);
router.use('/locations', locationRoutes_1.default);
router.use('/attendance', attendanceRoutes_1.default);
exports.default = router;
//# sourceMappingURL=index.js.map