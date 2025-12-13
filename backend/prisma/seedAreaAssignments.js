import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('🌱 Starting area assignments seeding...');

    // Check if user 00002 exists
    const user = await prisma.user.findUnique({
        where: { id: '00002' },
    });

    if (!user) {
        console.log('❌ User 00002 not found. Creating user first...');

        // Create user 00002 if not exists
        await prisma.user.create({
            data: {
                id: '00002',
                employeeCode: 'EMP00002',
                contactNumber: '+919876543211',
                name: 'Test Salesman',
                email: 'salesman@test.com',
                isActive: true,
            },
        });
        console.log('✅ User 00002 created');
    } else {
        console.log('✅ User 00002 found:', user.name);
    }

    // Create area assignments for user 00002
    const assignments = [
        {
            salesmanId: '00002',
            pinCode: '110001',
            country: 'India',
            state: 'Delhi',
            district: 'Central Delhi',
            city: 'New Delhi',
            areas: ['Connaught Place', 'Karol Bagh'],
            businessTypes: ['grocery', 'cafe', 'restaurant'],
            totalBusinesses: 25,
        },
        {
            salesmanId: '00002',
            pinCode: '110002',
            country: 'India',
            state: 'Delhi',
            district: 'Central Delhi',
            city: 'New Delhi',
            areas: ['Rajouri Garden', 'Janakpuri'],
            businessTypes: ['grocery', 'pharmacy', 'supermarket'],
            totalBusinesses: 30,
        },
    ];

    for (const assignment of assignments) {
        // Check if assignment already exists
        const existing = await prisma.areaAssignment.findFirst({
            where: {
                salesmanId: assignment.salesmanId,
                pinCode: assignment.pinCode,
            },
        });

        if (!existing) {
            await prisma.areaAssignment.create({
                data: assignment,
            });
            console.log(`✅ Created assignment for ${assignment.city} - ${assignment.pinCode}`);
        } else {
            console.log(`ℹ️  Assignment already exists for ${assignment.city} - ${assignment.pinCode}`);
        }
    }

    // Verify assignments were created
    const allAssignments = await prisma.areaAssignment.findMany({
        where: { salesmanId: '00002' },
        select: {
            id: true,
            salesmanId: true,
            city: true,
            pinCode: true,
        },
    });

    console.log('📊 All assignments for user 00002:', allAssignments);
    console.log('🎉 Area assignments seeding completed!');
}

main()
    .catch((e) => {
        console.error('❌ Seeding error:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });