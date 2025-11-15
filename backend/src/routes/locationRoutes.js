import express from 'express';
import {
  // Country
  getAllCountries,
  createCountry,
  updateCountry,
  deleteCountry,
  
  // State
  getAllStates,
  createState,
  updateState,
  deleteState,
  
  // Region
  getAllRegions,
  createRegion,
  updateRegion,
  deleteRegion,
  
  // District
  getAllDistricts,
  createDistrict,
  updateDistrict,
  deleteDistrict,
  
  // City
  getAllCities,
  createCity,
  updateCity,
  deleteCity,
  
  // Zone
  getAllZones,
  createZone,
  updateZone,
  deleteZone,
  
  // Area
  getAllAreas,
  createArea,
  updateArea,
  deleteArea
} from '../controllers/locationController.js';

const router = express.Router();

// ==================== COUNTRY ROUTES ====================
router.get('/countries', getAllCountries);
router.post('/countries', createCountry);
router.put('/countries/:id', updateCountry);
router.delete('/countries/:id', deleteCountry);

// ==================== STATE ROUTES ====================
router.get('/states', getAllStates);
router.post('/states', createState);
router.put('/states/:id', updateState);
router.delete('/states/:id', deleteState);

// ==================== REGION ROUTES ====================
router.get('/regions', getAllRegions);
router.post('/regions', createRegion);
router.put('/regions/:id', updateRegion);
router.delete('/regions/:id', deleteRegion);

// ==================== DISTRICT ROUTES ====================
router.get('/districts', getAllDistricts);
router.post('/districts', createDistrict);
router.put('/districts/:id', updateDistrict);
router.delete('/districts/:id', deleteDistrict);

// ==================== CITY ROUTES ====================
router.get('/cities', getAllCities);
router.post('/cities', createCity);
router.put('/cities/:id', updateCity);
router.delete('/cities/:id', deleteCity);

// ==================== ZONE ROUTES ====================
router.get('/zones', getAllZones);
router.post('/zones', createZone);
router.put('/zones/:id', updateZone);
router.delete('/zones/:id', deleteZone);

// ==================== AREA ROUTES ====================
router.get('/areas', getAllAreas);
router.post('/areas', createArea);
router.put('/areas/:id', updateArea);
router.delete('/areas/:id', deleteArea);

export default router;
