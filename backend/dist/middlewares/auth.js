"use strict";
// Authentication Middleware
// Purpose: JWT verification and role-based access control (RBAC)
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authenticate = authenticate;
exports.authorize = authorize;
exports.generateToken = generateToken;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const env_1 = __importDefault(require("../config/env"));
const logger_1 = require("../utils/logger");
/**
 * Verify JWT token and attach user to request
 * Use this middleware on all protected routes
 */
function authenticate(req, res, next) {
    try {
        // Get token from Authorization header
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            res.status(401).json({
                success: false,
                error: 'No token provided. Please login.'
            });
            return;
        }
        const token = authHeader.split(' ')[1];
        // Verify token
        const decoded = jsonwebtoken_1.default.verify(token, env_1.default.JWT_SECRET);
        // Attach user to request for use in controllers
        req.user = decoded;
        next();
    }
    catch (error) {
        if (error instanceof jsonwebtoken_1.default.TokenExpiredError) {
            logger_1.logger.auth('failed_login', undefined, { reason: 'token_expired' });
            res.status(401).json({
                success: false,
                error: 'Token expired. Please login again.'
            });
            return;
        }
        if (error instanceof jsonwebtoken_1.default.JsonWebTokenError) {
            logger_1.logger.auth('failed_login', undefined, { reason: 'invalid_token' });
            res.status(401).json({
                success: false,
                error: 'Invalid token. Please login again.'
            });
            return;
        }
        logger_1.logger.error('Auth middleware error', { error: error.message });
        res.status(500).json({
            success: false,
            error: 'Authentication failed'
        });
    }
}
/**
 * Role-based access control middleware factory
 * Use: authorize('ADMIN') or authorize('ADMIN', 'LEAD')
 * @param allowedRoles - Roles that can access this route
 */
function authorize(...allowedRoles) {
    return (req, res, next) => {
        // Must be authenticated first
        if (!req.user) {
            res.status(401).json({
                success: false,
                error: 'Not authenticated'
            });
            return;
        }
        // Check if user's role is in allowed list
        if (!allowedRoles.includes(req.user.role)) {
            logger_1.logger.warn('Unauthorized access attempt', {
                userId: req.user.userId,
                role: req.user.role,
                requiredRoles: allowedRoles,
                path: req.path,
            });
            res.status(403).json({
                success: false,
                error: 'You do not have permission to access this resource'
            });
            return;
        }
        next();
    };
}
/**
 * Generate JWT token for a user
 * @param payload - User data to encode in token
 * @returns Signed JWT token string
 */
function generateToken(payload) {
    return jsonwebtoken_1.default.sign(payload, env_1.default.JWT_SECRET, {
        expiresIn: env_1.default.JWT_EXPIRES_IN,
    });
}
exports.default = { authenticate, authorize, generateToken };
//# sourceMappingURL=auth.js.map