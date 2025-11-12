import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// ==================== COUNTRY ====================

export const getAllCountries = async (req, res) => {
  try {
    const countries = await prisma.country.findMany({
      orderBy: { name: 'asc' },
      include: {
        _count: {
          select: { states: true }
        }
      }
    });
    res.json({ success: true, data: countries });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createCountry = async (req, res) => {
  try {
    const { name } = req.body;
    if (!name) {
      return res.status(400).json({ success: false, message: 'Country name is required' });
    }

    const country = await prisma.country.create({
      data: { name }
    });
    res.status(201).json({ success: true, data: country });
  } catch (error) {
    if (error.code === 'P2002') {
      return res.status(400).json({ success: false, message: 'Country already exists' });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

export const updateCountry = async (req, res) => {
  try {
    const { id } = req.params;
    const { name } = req.body;

    const country = await prisma.country.update({
      where: { id },
      data: { name }
    });
    res.json({ success: true, data: country });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const deleteCountry = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.country.delete({ where: { id } });
    res.json({ success: true, message: 'Country deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== STATE ====================

export const getAllStates = async (req, res) => {
  try {
    const { countryId } = req.query;
    const where = countryId ? { countryId: parseInt(countryId) } : {};

    const states = await prisma.state.findMany({
      where,
      orderBy: { name: 'asc' },
      include: {
        country: true,
        _count: {
          select: { districts: true }
        }
      }
    });
    res.json({ success: true, data: states });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createState = async (req, res) => {
  try {
    const { name, countryId } = req.body;
    if (!name || !countryId) {
      return res.status(400).json({ success: false, message: 'Name and countryId are required' });
    }

    const state = await prisma.state.create({
      data: { name, countryId },
      include: { country: true }
    });
    res.status(201).json({ success: true, data: state });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const updateState = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, countryId } = req.body;

    const state = await prisma.state.update({
      where: { id },
      data: { name, countryId },
      include: { country: true }
    });
    res.json({ success: true, data: state });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const deleteState = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.state.delete({ where: { id } });
    res.json({ success: true, message: 'State deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== DISTRICT ====================

export const getAllDistricts = async (req, res) => {
  try {
    const { stateId } = req.query;
    const where = stateId ? { stateId: parseInt(stateId) } : {};

    const districts = await prisma.district.findMany({
      where,
      orderBy: { name: 'asc' },
      include: {
        state: {
          include: { country: true }
        },
        _count: {
          select: { cities: true }
        }
      }
    });
    res.json({ success: true, data: districts });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createDistrict = async (req, res) => {
  try {
    const { name, stateId } = req.body;
    if (!name || !stateId) {
      return res.status(400).json({ success: false, message: 'Name and stateId are required' });
    }

    const district = await prisma.district.create({
      data: { name, stateId },
      include: { state: true }
    });
    res.status(201).json({ success: true, data: district });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const updateDistrict = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, stateId } = req.body;

    const district = await prisma.district.update({
      where: { id },
      data: { name, stateId },
      include: { state: true }
    });
    res.json({ success: true, data: district });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const deleteDistrict = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.district.delete({ where: { id } });
    res.json({ success: true, message: 'District deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== CITY ====================

export const getAllCities = async (req, res) => {
  try {
    const { districtId } = req.query;
    const where = districtId ? { districtId: parseInt(districtId) } : {};

    const cities = await prisma.city.findMany({
      where,
      orderBy: { name: 'asc' },
      include: {
        district: {
          include: {
            state: {
              include: { country: true }
            }
          }
        },
        _count: {
          select: { zones: true }
        }
      }
    });
    res.json({ success: true, data: cities });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createCity = async (req, res) => {
  try {
    const { name, districtId } = req.body;
    if (!name || !districtId) {
      return res.status(400).json({ success: false, message: 'Name and districtId are required' });
    }

    const city = await prisma.city.create({
      data: { name, districtId },
      include: { district: true }
    });
    res.status(201).json({ success: true, data: city });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const updateCity = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, districtId } = req.body;

    const city = await prisma.city.update({
      where: { id },
      data: { name, districtId },
      include: { district: true }
    });
    res.json({ success: true, data: city });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const deleteCity = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.city.delete({ where: { id } });
    res.json({ success: true, message: 'City deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== ZONE ====================

export const getAllZones = async (req, res) => {
  try {
    const { cityId } = req.query;
    const where = cityId ? { cityId: parseInt(cityId) } : {};

    const zones = await prisma.zone.findMany({
      where,
      orderBy: { name: 'asc' },
      include: {
        city: {
          include: {
            district: {
              include: {
                state: {
                  include: { country: true }
                }
              }
            }
          }
        },
        _count: {
          select: { areas: true }
        }
      }
    });
    res.json({ success: true, data: zones });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createZone = async (req, res) => {
  try {
    const { name, cityId } = req.body;
    if (!name || !cityId) {
      return res.status(400).json({ success: false, message: 'Name and cityId are required' });
    }

    const zone = await prisma.zone.create({
      data: { name, cityId },
      include: { city: true }
    });
    res.status(201).json({ success: true, data: zone });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const updateZone = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, cityId } = req.body;

    const zone = await prisma.zone.update({
      where: { id },
      data: { name, cityId },
      include: { city: true }
    });
    res.json({ success: true, data: zone });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const deleteZone = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.zone.delete({ where: { id } });
    res.json({ success: true, message: 'Zone deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== AREA ====================

export const getAllAreas = async (req, res) => {
  try {
    const { zoneId } = req.query;
    const where = zoneId ? { zoneId: parseInt(zoneId) } : {};

    const areas = await prisma.area.findMany({
      where,
      orderBy: { name: 'asc' },
      include: {
        zone: {
          include: {
            city: {
              include: {
                district: {
                  include: {
                    state: {
                      include: { country: true }
                    }
                  }
                }
              }
            }
          }
        },
        _count: {
          select: { accounts: true }
        }
      }
    });
    res.json({ success: true, data: areas });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createArea = async (req, res) => {
  try {
    const { name, zoneId } = req.body;
    if (!name || !zoneId) {
      return res.status(400).json({ success: false, message: 'Name and zoneId are required' });
    }

    const area = await prisma.area.create({
      data: { name, zoneId },
      include: { zone: true }
    });
    res.status(201).json({ success: true, data: area });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const updateArea = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, zoneId } = req.body;

    const area = await prisma.area.update({
      where: { id },
      data: { name, zoneId },
      include: { zone: true }
    });
    res.json({ success: true, data: area });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const deleteArea = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.area.delete({ where: { id } });
    res.json({ success: true, message: 'Area deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
