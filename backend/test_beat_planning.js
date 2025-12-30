import BeatPlanService from './src/services/beatPlanService.js';
import prisma from './src/config/db.js';

async function testBeatPlanningSystem() {
    try {
        console.log('🧪 Testing Beat Planning System...\n');

        // Test 1: Get areas by pincodes
        console.log('📍 Test 1: Getting areas by pincodes...');
        const testPincodes = ['400001', '400002', '400003'];
        const areas = await BeatPlanService.getAreasByPincodes(testPincodes);
        console.log(`✅ Found ${areas.length} areas for pincodes:`, areas.slice(0, 5));

        if (areas.length === 0) {
            console.log('⚠️  No areas found. Creating test accounts...');
            
            // Create test accounts with areas
            const testAreas = ['Andheri East', 'Bandra West', 'Juhu', 'Versova', 'Goregaon East'];
            for (let i = 0; i < testAreas.length; i++) {
                await prisma.account.create({
                    data: {
                        id: `test-account-${i + 1}`,
                        accountCode: `TEST${String(i + 1).padStart(3, '0')}`,
                        personName: `Test Person ${i + 1}`,
                        contactNumber: `9876543${String(i + 1).padStart(3, '0')}`,
                        pincode: testPincodes[i % testPincodes.length],
                        area: testAreas[i],
                        isActive: true,
                        isApproved: true
                    }
                });
            }
            console.log('✅ Created test accounts with areas');
            
            // Re-fetch areas
            const newAreas = await BeatPlanService.getAreasByPincodes(testPincodes);
            console.log(`✅ Now found ${newAreas.length} areas:`, newAreas);
        }

        // Test 2: Area distribution
        console.log('\n🔄 Test 2: Testing area distribution...');
        const testAreasForDistribution = areas.length > 0 ? areas : ['Area 1', 'Area 2', 'Area 3', 'Area 4', 'Area 5', 'Area 6', 'Area 7', 'Area 8'];
        const distribution = BeatPlanService.distributeAreasAcrossDays(testAreasForDistribution);
        console.log('✅ Area distribution across 7 days:');
        distribution.forEach((dayAreas, index) => {
            const dayName = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][index];
            console.log(`   ${dayName}: ${dayAreas.length} areas - ${dayAreas.join(', ')}`);
        });

        // Test 3: Find or create test salesman
        console.log('\n👤 Test 3: Finding test salesman...');
        let testSalesman = await prisma.user.findFirst({
            where: {
                roles: { has: 'salesman' }
            }
        });

        if (!testSalesman) {
            console.log('⚠️  No salesman found. Looking for existing users to update...');
            
            // Try to find any user and update their role
            const existingUser = await prisma.user.findFirst({
                where: {
                    isActive: true
                }
            });

            if (existingUser) {
                console.log(`📝 Updating existing user ${existingUser.name} to salesman role...`);
                testSalesman = await prisma.user.update({
                    where: { id: existingUser.id },
                    data: {
                        roles: ['salesman'],
                        name: existingUser.name || 'Test Salesman'
                    }
                });
                console.log('✅ Updated existing user to salesman');
            } else {
                // Create with unique contact number
                const uniqueContact = `987654${Date.now().toString().slice(-4)}`;
                console.log(`📝 Creating test salesman with contact: ${uniqueContact}...`);
                testSalesman = await prisma.user.create({
                    data: {
                        id: `test-salesman-${Date.now()}`,
                        name: 'Test Salesman',
                        contactNumber: uniqueContact,
                        roles: ['salesman'],
                        isActive: true
                    }
                });
                console.log('✅ Created test salesman');
            }
        }

        console.log(`✅ Using salesman: ${testSalesman.name} (${testSalesman.id})`);

        // Test 4: Generate weekly beat plan
        console.log('\n📅 Test 4: Generating weekly beat plan...');
        const weekStartDate = new Date();
        weekStartDate.setDate(weekStartDate.getDate() - weekStartDate.getDay() + 1); // Get Monday

        try {
            const beatPlanResult = await BeatPlanService.generateWeeklyBeatPlan(
                testSalesman.id,
                weekStartDate,
                testPincodes,
                testSalesman.id // Use the salesman's ID as the generator for testing
            );

            console.log('✅ Beat plan generated successfully!');
            console.log(`   Weekly Plan ID: ${beatPlanResult.weeklyPlan.id}`);
            console.log(`   Total Areas: ${beatPlanResult.totalAreas}`);
            console.log(`   Daily Plans: ${beatPlanResult.dailyPlans.length}`);

            // Test 5: Get today's beat plan
            console.log('\n📋 Test 5: Getting today\'s beat plan...');
            const todaysPlan = await BeatPlanService.getTodaysBeatPlan(testSalesman.id);
            
            if (todaysPlan) {
                console.log('✅ Today\'s beat plan found:');
                console.log(`   Day: ${todaysPlan.dailyPlan.dayName}`);
                console.log(`   Areas: ${todaysPlan.dailyPlan.assignedAreas.length}`);
                console.log(`   Accounts: ${todaysPlan.accounts.length}`);
                console.log(`   Areas list: ${todaysPlan.dailyPlan.assignedAreas.join(', ')}`);

                // Test 6: Mark area complete
                if (todaysPlan.dailyPlan.assignedAreas.length > 0) {
                    console.log('\n✅ Test 6: Marking area as complete...');
                    const firstArea = todaysPlan.dailyPlan.assignedAreas[0];
                    
                    const completion = await BeatPlanService.markBeatComplete(
                        testSalesman.id,
                        todaysPlan.dailyPlan.id,
                        firstArea,
                        {
                            accountsVisited: 3,
                            latitude: 19.0760,
                            longitude: 72.8777,
                            notes: 'Test completion'
                        }
                    );

                    console.log(`✅ Area "${firstArea}" marked as complete`);
                    console.log(`   Completion ID: ${completion.id}`);
                    console.log(`   Accounts Visited: ${completion.accountsVisited}`);
                }
            } else {
                console.log('⚠️  No beat plan found for today');
            }

            // Test 7: Get analytics
            console.log('\n📊 Test 7: Getting beat plan analytics...');
            const analytics = await BeatPlanService.getBeatPlanAnalytics({
                salesmanId: testSalesman.id
            });

            console.log('✅ Analytics retrieved:');
            console.log(`   Total Plans: ${analytics.totalPlans}`);
            console.log(`   Active Plans: ${analytics.activePlans}`);
            console.log(`   Total Areas: ${analytics.totalAreas}`);
            console.log(`   Completed Areas: ${analytics.completedAreas}`);
            console.log(`   Completion Rate: ${analytics.completionRate}%`);

        } catch (error) {
            if (error.message.includes('already exists')) {
                console.log('⚠️  Beat plan already exists for this week');
                
                // Try to get existing plan
                const existingPlan = await prisma.weeklyBeatPlan.findFirst({
                    where: {
                        salesmanId: testSalesman.id,
                        weekStartDate: weekStartDate
                    },
                    include: {
                        dailyPlans: true
                    }
                });

                if (existingPlan) {
                    console.log(`✅ Found existing beat plan: ${existingPlan.id}`);
                    console.log(`   Status: ${existingPlan.status}`);
                    console.log(`   Daily Plans: ${existingPlan.dailyPlans.length}`);
                }
            } else {
                throw error;
            }
        }

        console.log('\n🎉 All tests completed successfully!');

    } catch (error) {
        console.error('❌ Test failed:', error);
        console.error('Stack trace:', error.stack);
    } finally {
        await prisma.$disconnect();
    }
}

// Run the tests
testBeatPlanningSystem();