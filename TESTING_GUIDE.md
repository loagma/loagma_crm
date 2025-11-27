# Employee Management System - Testing Guide

## Quick Test Scenarios

### Test 1: Create Employee with All New Features

**Steps:**
1. Open app and navigate to "Create Employee" screen
2. Enter contact number (10 digits)
3. Fill in basic details (name, email, gender)
4. **Test Multi-Select Languages:**
   - Tap on "Preferred Languages" field
   - Select multiple languages (e.g., English, Hindi, Marathi)
   - Tap "Done"
   - Verify selected languages are displayed
5. **Test Pincode Lookup:**
   - Enter a 6-digit pincode (e.g., 400001)
   - Click "Lookup" button
   - Wait for location details to load
   - Verify city, state, country are auto-filled
6. **Test Area Selection:**
   - After pincode lookup, verify area dropdown appears
   - Select an area from the dropdown
7. **Test Geolocation:**
   - Click "Capture Current Location" button
   - Grant location permissions if prompted
   - Wait for location to be captured
   - Verify coordinates are displayed
   - Verify map appears with marker
   - Click "Open in Maps" to test external map launch
8. Fill in remaining fields (salary, etc.)
9. Click "Create Employee"
10. **Verify:**
    - Success message appears
    - Employee ID is in format EMP000001
    - Form resets

### Test 2: Edit Employee

**Steps:**
1. Navigate to employee list
2. Select an existing employee
3. Click "Edit" button
4. **Verify Pre-filled Data:**
   - Check if languages are pre-selected
   - Check if area is pre-filled
   - Check if map shows existing location (if available)
5. **Update Languages:**
   - Tap "Preferred Languages"
   - Add or remove languages
   - Tap "Done"
6. **Update Location:**
   - Enter new pincode
   - Click "Lookup"
   - Select new area
   - Click "Capture Current Location" to update geolocation
7. Click "Update"
8. **Verify:**
   - Success message appears
   - Changes are saved

### Test 3: View Employee Details

**Steps:**
1. Navigate to employee list
2. Select an employee with complete data
3. **Verify Display:**
   - Employee ID shows in EMP format
   - Multiple languages displayed (comma-separated)
   - Area shown in Address Information section
   - Geolocation section appears (if data exists)
   - Coordinates displayed correctly
   - Map shows with marker at correct location
4. **Test Copy Coordinates:**
   - Click copy icon next to coordinates
   - Verify "Copied to clipboard" message
   - Paste somewhere to verify

### Test 4: Numeric Employee IDs

**Steps:**
1. Create first employee
2. Note the ID (should be EMP000001)
3. Create second employee
4. Note the ID (should be EMP000002)
5. Create third employee
6. Note the ID (should be EMP000003)
7. **Verify:** IDs are sequential and numeric

### Test 5: Pincode Lookup Edge Cases

**Test 5a: Invalid Pincode**
1. Enter invalid pincode (e.g., 12345 or 1234567)
2. Click "Lookup"
3. Verify error message appears

**Test 5b: Pincode with No Areas**
1. Enter valid pincode with no areas
2. Click "Lookup"
3. Verify "No areas found" message appears
4. Verify area dropdown does not appear

**Test 5c: Network Error**
1. Disable internet connection
2. Enter valid pincode
3. Click "Lookup"
4. Verify error message appears

### Test 6: Geolocation Edge Cases

**Test 6a: Location Permission Denied**
1. Click "Capture Current Location"
2. Deny location permission
3. Verify error message appears

**Test 6b: Location Services Disabled**
1. Disable location services on device
2. Click "Capture Current Location"
3. Verify error message appears

**Test 6c: Clear Location**
1. Capture location
2. Verify map appears
3. Click "X" button to clear location
4. Verify location is removed
5. Verify map disappears

### Test 7: Form Validation

**Test 7a: Required Fields**
1. Try to submit form without contact number
2. Verify validation error appears
3. Try to submit without salary
4. Verify validation error appears

**Test 7b: Field Formats**
1. Enter invalid email format
2. Verify validation error
3. Enter invalid phone number (not 10 digits)
4. Verify validation error
5. Enter invalid Aadhar (not 12 digits)
6. Verify validation error
7. Enter invalid PAN (wrong format)
8. Verify validation error

### Test 8: Multi-Select Languages

**Test 8a: Select Multiple**
1. Open language selector
2. Select 3-4 languages
3. Verify all are checked
4. Click "Done"
5. Verify all are displayed

**Test 8b: Deselect**
1. Open language selector
2. Deselect some languages
3. Click "Done"
4. Verify only selected ones remain

**Test 8c: Select None**
1. Open language selector
2. Deselect all languages
3. Click "Done"
4. Verify "Tap to select" is shown

### Test 9: Map Functionality

**Test 9a: Map Display**
1. Capture location
2. Verify map loads
3. Verify marker appears at correct position
4. Verify marker has info window with title

**Test 9b: Map Interaction**
1. Try to zoom in/out on map
2. Verify zoom works
3. Try to pan the map
4. Verify panning works

**Test 9c: Open in External Maps**
1. Click "Open in Maps" button
2. Verify Google Maps app opens (or browser)
3. Verify location is correct

### Test 10: Data Persistence

**Test 10a: Create and View**
1. Create employee with all fields
2. Navigate away
3. Come back and view employee
4. Verify all data is saved correctly

**Test 10b: Edit and View**
1. Edit employee
2. Change multiple fields
3. Save changes
4. View employee details
5. Verify all changes are saved

## Expected Results Summary

| Test | Expected Result |
|------|----------------|
| Create Employee | Employee created with EMP ID |
| Multi-Select Languages | Multiple languages selectable and saved |
| Pincode Lookup | Auto-fills location details |
| Area Selection | Dropdown appears with areas |
| Geolocation Capture | Coordinates captured and map displayed |
| Edit Employee | All fields editable and saveable |
| View Employee | All fields displayed correctly |
| Map Display | Interactive map with marker |
| Numeric IDs | Sequential EMP000001 format |
| Validation | Proper error messages |

## Common Issues and Solutions

### Issue: Map not displaying
**Solution:** 
- Check Google Maps API key is configured
- Verify internet connection
- Check console for API errors

### Issue: Location not capturing
**Solution:**
- Grant location permissions
- Enable location services
- Check GPS is working

### Issue: Pincode lookup fails
**Solution:**
- Verify backend is running
- Check API endpoint is correct
- Verify pincode exists in database

### Issue: Employee ID not numeric
**Solution:**
- Check backend generateNumericUserId function
- Verify database migration applied
- Check existing users don't have UUID format

### Issue: Languages not saving
**Solution:**
- Check selectedLanguages array is populated
- Verify API request includes preferredLanguages
- Check backend accepts array format

## Performance Testing

1. **Create 100 employees** - Verify IDs are sequential
2. **Load employee list** - Verify performance is acceptable
3. **Load map with location** - Verify map loads quickly
4. **Pincode lookup** - Verify response time is reasonable

## Device Testing

Test on:
- [ ] Android phone
- [ ] Android tablet
- [ ] iOS phone (if available)
- [ ] iOS tablet (if available)
- [ ] Different screen sizes
- [ ] Different Android versions
- [ ] Different iOS versions

## Browser Testing (if web version)

Test on:
- [ ] Chrome
- [ ] Firefox
- [ ] Safari
- [ ] Edge

## Accessibility Testing

- [ ] Screen reader compatibility
- [ ] Keyboard navigation
- [ ] Color contrast
- [ ] Font sizes
- [ ] Touch target sizes

## Security Testing

- [ ] Location permissions properly requested
- [ ] API calls use HTTPS
- [ ] Sensitive data not logged
- [ ] Input validation working
- [ ] SQL injection prevention

---

**Note:** Mark each test as ✅ when completed successfully or ❌ if issues found.
