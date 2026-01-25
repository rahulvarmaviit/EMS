-- Migration: 002_seed_admin
-- Purpose: Seed initial admin user for first-time setup
-- Date: 2026-01-25

-- Create admin user if not exists
-- Password: admin123 (hashed with bcrypt)
-- Mobile: +1234567890

INSERT INTO users (mobile_number, password_hash, full_name, role)
SELECT '+1234567890', '$2b$10$rOz8YJd3Z9p3X5K6Vb7QoO6QZxz9w8R7T6Y5U4I3O2P1A0S9D8F7G', 'System Admin', 'ADMIN'
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE mobile_number = '+1234567890'
);

-- Note: The password hash above is a placeholder
-- In production, generate a proper bcrypt hash for your chosen password
-- You can use: node -e "require('bcryptjs').hash('your_password', 10).then(console.log)"
