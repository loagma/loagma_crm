// Insert test approval data directly
import pkg from 'pg';
const { Client } = pkg;

const client = new Client({
    connectionString: "postgresql://neondb_owner:npg_SJkITA8xRm5j@ep-shy-pond-ahz1sdqw-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require"
});

async function insertTestApproval() {
    try {
        await client.connect();
        console.log('✅ Connected to database');

        // Delete existing requests for EMP001 today
        const deleteResult = await client.query(`
            DELETE FROM "LatePunchApproval" 
            WHERE "employeeId" = 'EMP001' 
            AND "requestDate" >= CURRENT_DATE 
            AND "requestDate" < CURRENT_DATE + INTERVAL '1 day'
        `);
        console.log(`🗑️ Deleted ${deleteResult.rowCount} existing requests`);

        // Insert new approved request with code 108767
        const insertResult = await client.query(`
            INSERT INTO "LatePunchApproval" (
                id,
                "employeeId",
                "employeeName",
                "requestDate",
                "punchInDate",
                reason,
                status,
                "approvedBy",
                "approvedAt",
                "adminRemarks",
                "approvalCode",
                "codeExpiresAt",
                "codeUsed",
                "createdAt",
                "updatedAt"
            ) VALUES (
                'test_' || extract(epoch from now())::text,
                'EMP001',
                'Test Employee',
                NOW(),
                NOW(),
                'Testing OTP flow - traffic jam caused delay',
                'APPROVED',
                'ADMIN001',
                NOW(),
                'Approved for testing OTP flow',
                '108767',
                NOW() + INTERVAL '2 hours',
                false,
                NOW(),
                NOW()
            )
        `);
        console.log(`✅ Inserted ${insertResult.rowCount} test approval record`);

        // Verify the insert
        const verifyResult = await client.query(`
            SELECT * FROM "LatePunchApproval" 
            WHERE "employeeId" = 'EMP001' 
            AND "approvalCode" = '108767'
        `);
        console.log('📊 Verification result:', verifyResult.rows[0]);
        console.log('\n🎉 Test approval record created successfully!');
        console.log('📱 You can now test OTP code 108767 in the Flutter app');

    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await client.end();
    }
}

insertTestApproval();