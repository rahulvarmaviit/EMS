// Seed Admin Script
// Purpose: Create initial admin user with proper password hash
// Run: npx tsx src/scripts/seedAdmin.ts

import bcrypt from 'bcryptjs';
import { query, closePool } from '../config/database';
import { logger } from '../utils/logger';

async function seedAdmin() {
  const mobileNumber = '+1234567890';
  const password = 'admin123';
  const fullName = 'System Admin';
  
  try {
    // Check if admin already exists
    const existing = await query(
      'SELECT id FROM users WHERE mobile_number = $1',
      [mobileNumber]
    );
    
    if (existing.rows.length > 0) {
      logger.info('Admin user already exists', { mobileNumber });
      console.log('\n========================================');
      console.log('  Admin user already exists!');
      console.log('========================================');
      console.log(`  Mobile: ${mobileNumber}`);
      console.log(`  Password: ${password}`);
      console.log('========================================\n');
    } else {
      // Hash password
      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash(password, salt);
      
      // Create admin user
      await query(
        `INSERT INTO users (mobile_number, password_hash, full_name, role)
         VALUES ($1, $2, $3, 'ADMIN')`,
        [mobileNumber, passwordHash, fullName]
      );
      
      logger.info('Admin user created successfully', { mobileNumber });
      console.log('\n========================================');
      console.log('  Admin user created successfully!');
      console.log('========================================');
      console.log(`  Mobile: ${mobileNumber}`);
      console.log(`  Password: ${password}`);
      console.log(`  Role: ADMIN`);
      console.log('========================================\n');
    }
  } catch (error) {
    logger.error('Failed to seed admin', { error: (error as Error).message });
    console.error('Failed to create admin user:', (error as Error).message);
  } finally {
    await closePool();
  }
}

seedAdmin();
