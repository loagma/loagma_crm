class Country {
  final int id;
  final String name;

  Country({required this.id, required this.name});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['country_id'] ?? json['id'],
      name: json['country_name'] ?? json['name'],
    );
  }
}

class State {
  final int id;
  final String name;
  final int countryId;
  final Country? country;

  State({
    required this.id,
    required this.name,
    required this.countryId,
    this.country,
  });

  factory State.fromJson(Map<String, dynamic> json) {
    return State(
      id: json['state_id'] ?? json['id'],
      name: json['state_name'] ?? json['name'],
      countryId: json['country_id'] ?? json['countryId'],
      country: json['country'] != null
          ? Country.fromJson(json['country'])
          : null,
    );
  }
}

class Region {
  final int id;
  final String name;
  final int stateId;
  final State? state;

  Region({
    required this.id,
    required this.name,
    required this.stateId,
    this.state,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['region_id'] ?? json['id'],
      name: json['region_name'] ?? json['name'],
      stateId: json['state_id'] ?? json['stateId'],
      state: json['state'] != null ? State.fromJson(json['state']) : null,
    );
  }
}

class District {
  final int id;
  final String name;
  final int regionId;
  final Region? region;

  District({
    required this.id,
    required this.name,
    required this.regionId,
    this.region,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['district_id'] ?? json['id'],
      name: json['district_name'] ?? json['name'],
      regionId: json['region_id'] ?? json['regionId'],
      region: json['region'] != null ? Region.fromJson(json['region']) : null,
    );
  }
}

class City {
  final int id;
  final String name;
  final int districtId;
  final District? district;

  City({
    required this.id,
    required this.name,
    required this.districtId,
    this.district,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['city_id'] ?? json['id'],
      name: json['city_name'] ?? json['name'],
      districtId: json['district_id'] ?? json['districtId'],
      district: json['district'] != null
          ? District.fromJson(json['district'])
          : null,
    );
  }
}

class Zone {
  final int id;
  final String name;
  final int cityId;
  final City? city;

  Zone({required this.id, required this.name, required this.cityId, this.city});

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['zone_id'] ?? json['id'],
      name: json['zone_name'] ?? json['name'],
      cityId: json['city_id'] ?? json['cityId'],
      city: json['city'] != null ? City.fromJson(json['city']) : null,
    );
  }
}

class Area {
  final int id;
  final String name;
  final int zoneId;
  final Zone? zone;

  Area({required this.id, required this.name, required this.zoneId, this.zone});

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['area_id'] ?? json['id'],
      name: json['area_name'] ?? json['name'],
      zoneId: json['zone_id'] ?? json['zoneId'],
      zone: json['zone'] != null ? Zone.fromJson(json['zone']) : null,
    );
  }
}
