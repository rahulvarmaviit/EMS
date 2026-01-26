
import { prisma } from './src/config/database';

// Script to clean up today's attendance records for testing
async function main() {
    try {
        // Get UTC midnight for today
        const now = new Date();
        const utcToday = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()));

        // Also get what the old code would have produced (local midnight)
        const localToday = new Date();
        localToday.setHours(0, 0, 0, 0);

        console.log('======= Date Comparison =======');
        console.log(`Now: ${now.toISOString()}`);
        console.log(`UTC Today (correct): ${utcToday.toISOString()}`);
        console.log(`Local Today (old/wrong): ${localToday.toISOString()}`);

        // Find all attendance records from last 3 days
        const threeDaysAgo = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate() - 3));

        console.log('\n======= Recent Attendance Records =======');
        const records = await prisma.attendance.findMany({
            where: {
                date: {
                    gte: threeDaysAgo
                }
            },
            include: {
                user: {
                    select: { full_name: true }
                }
            },
            orderBy: { date: 'desc' }
        });

        console.log(`Found ${records.length} records in last 3 days:\n`);
        for (const r of records) {
            console.log(`User: ${r.user.full_name}`);
            console.log(`  Date (stored): ${r.date.toISOString()}`);
            console.log(`  Check-in: ${r.check_in_time.toISOString()}`);
            console.log(`  Check-out: ${r.check_out_time?.toISOString() || 'N/A'}`);
            console.log('---');
        }

        // Delete today's records to allow fresh testing
        console.log('\n======= Cleanup =======');
        const deleted = await prisma.attendance.deleteMany({
            where: {
                date: {
                    gte: threeDaysAgo
                }
            }
        });
        console.log(`Deleted ${deleted.count} attendance records from last 3 days for fresh testing.`);

    } catch (error) {
        console.error('Error:', error);
    } finally {
        await prisma.$disconnect();
    }
}

main();
