"use strict";
// Seed Admin Script
// Purpose: Create initial admin user with proper password hash
// Run: npx tsx src/scripts/seedAdmin.ts
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const database_1 = require("../config/database");
const logger_1 = require("../utils/logger");
async function seedAdmin() {
    const mobileNumber = '+1234567890';
    const password = 'admin123';
    const fullName = 'System Admin';
    try {
        // Check if admin already exists
        const existing = await (0, database_1.query)('SELECT id FROM users WHERE mobile_number = $1', [mobileNumber]);
        if (existing.rows.length > 0) {
            logger_1.logger.info('Admin user already exists', { mobileNumber });
            console.log('\n========================================');
            console.log('  Admin user already exists!');
            console.log('========================================');
            console.log(`  Mobile: ${mobileNumber}`);
            console.log(`  Password: ${password}`);
            console.log('========================================\n');
        }
        else {
            // Hash password
            const salt = await bcryptjs_1.default.genSalt(10);
            const passwordHash = await bcryptjs_1.default.hash(password, salt);
            // Create admin user
            await (0, database_1.query)(`INSERT INTO users (mobile_number, password_hash, full_name, role)
         VALUES ($1, $2, $3, 'ADMIN')`, [mobileNumber, passwordHash, fullName]);
            logger_1.logger.info('Admin user created successfully', { mobileNumber });
            console.log('\n========================================');
            console.log('  Admin user created successfully!');
            console.log('========================================');
            console.log(`  Mobile: ${mobileNumber}`);
            console.log(`  Password: ${password}`);
            console.log(`  Role: ADMIN`);
            console.log('========================================\n');
        }
    }
    catch (error) {
        logger_1.logger.error('Failed to seed admin', { error: error.message });
        console.error('Failed to create admin user:', error.message);
    }
    finally {
        await (0, database_1.closePool)();
    }
}
seedAdmin();
//# sourceMappingURL=seedAdmin.js.map