class Country {
  final int id;
  final String name;

  Country({
    required this.id,
    required this.name,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'],
      name: json['name'],
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
      id: json['id'],
      name: json['name'],
      countryId: json['countryId'],
      country: json['country'] != null ? Country.fromJson(json['country']) : null,
    );
  }
}

class District {
  final int id;
  final String name;
  final int stateId;
  final State? state;

  District({
    required this.id,
    required this.name,
    required this.stateId,
    this.state,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'],
      name: json['name'],
      stateId: json['stateId'],
      state: json['state'] != null ? State.fromJson(json['state']) : null,
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
      id: json['id'],
      name: json['name'],
      districtId: json['districtId'],
      district: json['district'] != null ? District.fromJson(json['district']) : null,
    );
  }
}

class Zone {
  final int id;
  final String name;
  final int cityId;
  final City? city;

  Zone({
    required this.id,
    required this.name,
    required this.cityId,
    this.city,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'],
      name: json['name'],
      cityId: json['cityId'],
      city: json['city'] != null ? City.fromJson(json['city']) : null,
    );
  }
}

class Area {
  final int id;
  final String name;
  final int zoneId;
  final Zone? zone;

  Area({
    required this.id,
    required this.name,
    required this.zoneId,
    this.zone,
  });

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['id'],
      name: json['name'],
      zoneId: json['zoneId'],
      zone: json['zone'] != null ? Zone.fromJson(json['zone']) : null,
    );
  }
}
