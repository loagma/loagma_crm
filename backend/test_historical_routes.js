import fetch from 'node-fetch';

async function testHistoricalRoutes() {
    try {
        console.log('🧪 Testing historical routes API...');

        // Test the API call that the Flutter app is making
        const url = 'http://localhost:3000/api/routes/historical?employeeId=sparsh-sahu&date=2026-01-03';

        console.log(`📡 Calling: ${url}`);

        const response = await fetch(url);
        const data = await response.json();

        console.log(`📊 Response Status: ${response.status}`);
        console.log(`📊 Response Data:`, JSON.stringify(data, null, 2));

        if (data.success && data.data && data.data.routes) {
            console.log(`✅ Found ${data.data.routes.length} routes`);
            data.data.routes.forEach((route, index) => {
                console.log(`Route ${index + 1}:`);
                console.log(`  - Employee: ${route.employeeName}`);
                console.log(`  - Date: ${route.date}`);
                console.log(`  - Points: ${route.routeSummary.totalPoints}`);
                console.log(`  - Distance: ${route.routeSummary.totalDistanceKm} km`);
            });
        } else {
            console.log('❌ No routes found or API error');
        }

    } catch (error) {
        console.error('❌ Error testing API:', error);
    }
}

testHistoricalRoutes();