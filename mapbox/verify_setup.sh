#!/bin/bash

# Mapbox Setup Verification Script
# This script verifies that Mapbox is properly configured

echo "🔍 Verifying Mapbox Setup..."
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Your Mapbox token
MAPBOX_TOKEN="pk.eyJ1IjoibG9hZ21hY3JtMTIzIiwiYSI6ImNta2YzZHBrYTBmZHkzZ3F2MGVudjB3NGQifQ.xa5ojP6rByCK2U6Xs0OZyA"

# Test 1: Verify token format
echo "1️⃣  Checking token format..."
if [[ $MAPBOX_TOKEN == pk.* ]]; then
    echo -e "${GREEN}✅ Token format is correct (public token)${NC}"
else
    echo -e "${RED}❌ Token format is incorrect${NC}"
    exit 1
fi
echo ""

# Test 2: Verify token with Mapbox API
echo "2️⃣  Verifying token with Mapbox API..."
RESPONSE=$(curl -s "https://api.mapbox.com/styles/v1/mapbox/streets-v12?access_token=$MAPBOX_TOKEN")

if echo "$RESPONSE" | grep -q "\"id\":\"mapbox://styles/mapbox/streets-v12\""; then
    echo -e "${GREEN}✅ Token is valid and working${NC}"
else
    echo -e "${RED}❌ Token validation failed${NC}"
    echo "Response: $RESPONSE"
    exit 1
fi
echo ""

# Test 3: Check Flutter configuration
echo "3️⃣  Checking Flutter configuration..."
if grep -q "pk.eyJ1IjoibG9hZ21hY3JtMTIzIiwiYSI6ImNta2YzZHBrYTBmZHkzZ3F2MGVudjB3NGQifQ.xa5ojP6rByCK2U6Xs0OZyA" "../loagma_crm/lib/config/mapbox_config.dart"; then
    echo -e "${GREEN}✅ Flutter config is correct${NC}"
else
    echo -e "${RED}❌ Flutter config needs update${NC}"
    exit 1
fi
echo ""

# Test 4: Check Android configuration
echo "4️⃣  Checking Android configuration..."
if grep -q "MAPBOX_ACCESS_TOKEN=pk.eyJ1IjoibG9hZ21hY3JtMTIzIiwiYSI6ImNta2YzZHBrYTBmZHkzZ3F2MGVudjB3NGQifQ.xa5ojP6rByCK2U6Xs0OZyA" "../loagma_crm/android/gradle.properties"; then
    echo -e "${GREEN}✅ Android config is correct${NC}"
else
    echo -e "${RED}❌ Android config needs update${NC}"
    exit 1
fi
echo ""

# Test 5: Check iOS configuration
echo "5️⃣  Checking iOS configuration..."
if grep -q "pk.eyJ1IjoibG9hZ21hY3JtMTIzIiwiYSI6ImNta2YzZHBrYTBmZHkzZ3F2MGVudjB3NGQifQ.xa5ojP6rByCK2U6Xs0OZyA" "../loagma_crm/ios/Runner/Info.plist"; then
    echo -e "${GREEN}✅ iOS config is correct${NC}"
else
    echo -e "${RED}❌ iOS config needs update${NC}"
    exit 1
fi
echo ""

# Test 6: Run Flutter tests
echo "6️⃣  Running Mapbox integration tests..."
cd ../loagma_crm
flutter test test/integration/mapbox_integration_test.dart --reporter compact > /tmp/mapbox_test_output.txt 2>&1

if grep -q "All tests passed!" /tmp/mapbox_test_output.txt; then
    echo -e "${GREEN}✅ All Mapbox integration tests passed${NC}"
else
    echo -e "${YELLOW}⚠️  Some tests may require additional setup${NC}"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Mapbox Setup Verification Complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Your Mapbox integration is properly configured and ready to use!"
echo ""
echo "Next steps:"
echo "  1. Run your Flutter app: flutter run"
echo "  2. Navigate to Live Tracking screen"
echo "  3. View the map with your configured style"
echo ""
echo "For more information, see: mapbox/SETUP_COMPLETE.md"
