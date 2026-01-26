
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
    const mobileNumber = '7989498358';
    const password = 'admin123';
    const fullName = 'Admin User';
    const role = 'ADMIN';

    console.log(`Checking for user: ${mobileNumber}...`);

    const existingUser = await prisma.user.findUnique({
        where: { mobile_number: mobileNumber },
    });

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    if (existingUser) {
        console.log('User found. Updating password and role...');
        await prisma.user.update({
            where: { id: existingUser.id },
            data: {
                password_hash: passwordHash,
                role: role,
                is_active: true,
            },
        });
        console.log('User updated successfully.');
    } else {
        console.log('User not found. Creating new admin user...');
        await prisma.user.create({
            data: {
                mobile_number: mobileNumber,
                password_hash: passwordHash,
                full_name: fullName,
                role: role,
                is_active: true,
            },
        });
        console.log('User created successfully.');
    }
}

main()
    .catch((e) => {
        console.error('Error:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
