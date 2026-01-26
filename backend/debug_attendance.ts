
import { prisma } from './src/config/database';

async function main() {
    try {
        // Get all attendance records
        const attendance = await prisma.attendance.findMany({
            orderBy: { date: 'desc' },
            take: 10,
        });

        console.log('======= All Attendance Records =======');
        console.log(`Found ${attendance.length} records:\n`);

        for (const a of attendance) {
            console.log(`ID: ${a.id}`);
            console.log(`  User ID: ${a.user_id}`);
            console.log(`  Date (DB): ${a.date}`);
            console.log(`  Date ISO: ${a.date.toISOString()}`);
            console.log(`  Date Local: ${a.date.toLocaleString()}`);
            console.log(`  Check-in: ${a.check_in_time}`);
            console.log(`  Check-out: ${a.check_out_time || 'Not checked out'}`);
            console.log(`  Status: ${a.status}`);
            console.log('---');
        }

        // Check what "today" looks like on the server
        const serverNow = new Date();
        const serverToday = new Date();
        serverToday.setHours(0, 0, 0, 0);

        console.log('\n======= Server Date Info =======');
        console.log(`Server now: ${serverNow.toISOString()}`);
        console.log(`Server today (midnight): ${serverToday.toISOString()}`);
        console.log(`Server timezone offset: ${serverNow.getTimezoneOffset()} minutes`);

    } catch (error) {
        console.error('Error:', error);
    } finally {
        await prisma.$disconnect();
    }
}

main();
