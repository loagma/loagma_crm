import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// ==================== COUNTRY ====================

export const getAllCountries = async (req, res) => {
  try {
    const countries = await prisma.country.findMany({
      orderBy: { country_name: 'asc' },
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
    const { country_name } = req.body;
    if (!country_name) {
      return res.status(400).json({ success: false, message: 'Country name is required' });
    }

    const country = await prisma.country.create({
      data: { country_name }
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
    const { country_name } = req.body;

    const country = await prisma.country.update({
      where: { country_id: parseInt(id) },
      data: { country_name }
    });
    res.json({ success: true, data: country });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const deleteCountry = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.country.delete({ where: { country_id: parseInt(id) } });
    res.json({ success: true, message: 'Country deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== STATE ====================

export const getAllStates = async (req, res) => {
  try {
    const { country_id } = req.query;
    const where = country_id ? { country_id: parseInt(country_id) } : {};

    const states = await prisma.state.findMany({
      where,
      orderBy: { state_name: 'asc' },
      include: {
        country: true,
        _count: {
          select: { regions: true }
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
    const { state_name, country_id } = req.body;
    if (!state_name || !country_id) {
      return res.status(400).json({ success: false, message: 'State name and country_id are required' });
    }

    const state = await prisma.state.create({
      data: { state_name, country_id },
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
    const { state_name, country_id } = req.body;

    const state = await prisma.state.update({
      where: { state_id: parseInt(id) },
      data: { state_name, country_id },
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
    await prisma.state.delete({ where: { state_id: parseInt(id) } });
    res.json({ success: true, message: 'State deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== REGION ====================

export const getAllRegions = async (req, res) => {
  try {
    const { state_id } = req.query;
    const where = state_id ? { state_id: parseInt(state_id) } : {};

    const regions = await prisma.region.findMany({
      where,
      orderBy: { region_name: 'asc' },
      include: {
        state: {
          include: { country: true }
        },
        _count: {
          select: { districts: true }
        }
      }
    });
    res.json({ success: true, data: regions });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createRegion = async (req, res) => {
  try {
    const { region_name, state_id } = req.body;
    if (!region_name || !state_id) {
      return res.status(400).json({ success: false, message: 'Region name and state_id are required' });
    }

    const region = await prisma.region.create({
      data: { region_name, state_id },
      include: { state: true }
    });
    res.status(201).json({ success: true, data: region });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const updateRegion = async (req, res) => {
  try {
    const { id } = req.params;
    const { region_name, state_id } = req.body;

    const region = await prisma.region.update({
      where: { region_id: parseInt(id) },
      data: { region_name, state_id },
      include: { state: true }
    });
    res.json({ success: true, data: region });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const deleteRegion = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.region.delete({ where: { region_id: parseInt(id) } });
    res.json({ success: true, message: 'Region deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== DISTRICT ====================

export const getAllDistricts = async (req, res) => {
  try {
    const { region_id } = req.query;
    const where = region_id ? { region_id: parseInt(region_id) } : {};

    const districts = await prisma.district.findMany({
      where,
      orderBy: { district_name: 'asc' },
      include: {
        region: {
          include: {
            state: {
              include: { country: true }
            }
          }
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
    const { district_name, region_id } = req.body;
    if (!district_name || !region_id) {
      return res.status(400).json({ success: false, message: 'District name and region_id are required' });
    }

    const district = await prisma.district.create({
      data: { district_name, region_id },
      include: { region: true }
    });
    res.status(201).json({ success: true, data: district });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const updateDistrict = async (req, res) => {
  try {
    const { id } = req.params;
    const { district_name, region_id } = req.body;

    const district = await prisma.district.update({
      where: { district_id: parseInt(id) },
      data: { district_name, region_id },
      include: { region: true }
    });
    res.json({ success: true, data: district });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const deleteDistrict = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.district.delete({ where: { district_id: parseInt(id) } });
    res.json({ success: true, message: 'District deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== CITY ====================

export const getAllCities = async (req, res) => {
  try {
    const { district_id } = req.query;
    const where = district_id ? { district_id: parseInt(district_id) } : {};

    const cities = await prisma.city.findMany({
      where,
      orderBy: { city_name: 'asc' },
      include: {
        district: {
          include: {
            region: {
              include: {
                state: {
                  include: { country: true }
                }
              }
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
    const { city_name, district_id } = req.body;
    if (!city_name || !district_id) {
      return res.status(400).json({ success: false, message: 'City name and district_id are required' });
    }

    const city = await prisma.city.create({
      data: { city_name, district_id },
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
    const { city_name, district_id } = req.body;

    const city = await prisma.city.update({
      where: { city_id: parseInt(id) },
      data: { city_name, district_id },
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
    await prisma.city.delete({ where: { city_id: parseInt(id) } });
    res.json({ success: true, message: 'City deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== ZONE ====================

export const getAllZones = async (req, res) => {
  try {
    const { city_id } = req.query;
    const where = city_id ? { city_id: parseInt(city_id) } : {};

    const zones = await prisma.zone.findMany({
      where,
      orderBy: { zone_name: 'asc' },
      include: {
        city: {
          include: {
            district: {
              include: {
                region: {
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
    const { zone_name, city_id } = req.body;
    if (!zone_name || !city_id) {
      return res.status(400).json({ success: false, message: 'Zone name and city_id are required' });
    }

    const zone = await prisma.zone.create({
      data: { zone_name, city_id },
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
    const { zone_name, city_id } = req.body;

    const zone = await prisma.zone.update({
      where: { zone_id: parseInt(id) },
      data: { zone_name, city_id },
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
    await prisma.zone.delete({ where: { zone_id: parseInt(id) } });
    res.json({ success: true, message: 'Zone deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== AREA ====================

export const getAllAreas = async (req, res) => {
  try {
    const { zone_id } = req.query;
    const where = zone_id ? { zone_id: parseInt(zone_id) } : {};

    const areas = await prisma.area.findMany({
      where,
      orderBy: { area_name: 'asc' },
      include: {
        zone: {
          include: {
            city: {
              include: {
                district: {
                  include: {
                    region: {
                      include: {
                        state: {
                          include: { country: true }
                        }
                      }
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
    const { area_name, zone_id } = req.body;
    if (!area_name || !zone_id) {
      return res.status(400).json({ success: false, message: 'Area name and zone_id are required' });
    }

    const area = await prisma.area.create({
      data: { area_name, zone_id },
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
    const { area_name, zone_id } = req.body;

    const area = await prisma.area.update({
      where: { area_id: parseInt(id) },
      data: { area_name, zone_id },
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
    await prisma.area.delete({ where: { area_id: parseInt(id) } });
    res.json({ success: true, message: 'Area deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
