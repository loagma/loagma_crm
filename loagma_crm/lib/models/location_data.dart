class LocationData {
  static final List<Map<String, dynamic>> locations = [
    {
      'country': 'India',
      'state': 'Delhi',
      'district': 'New Delhi',
      'city': 'Connaught Place',
      'zone': 'Zone G',
      'area': 'Janpath'
    },
    {
      'country': 'India',
      'state': 'Karnataka',
      'district': 'Bengaluru Urban',
      'city': 'Indiranagar',
      'zone': 'Zone F',
      'area': 'HAL Layout'
    },
    {
      'country': 'India',
      'state': 'Madhya Pradesh',
      'district': 'Bhopal',
      'city': 'Arera Hills',
      'zone': 'Zone B',
      'area': 'MP Nagar'
    },
    {
      'country': 'India',
      'state': 'Madhya Pradesh',
      'district': 'Jabalpur',
      'city': 'Wright Town',
      'zone': 'Zone A',
      'area': 'Nehru Nagar'
    },
    {
      'country': 'India',
      'state': 'Madhya Pradesh',
      'district': 'Jabalpur',
      'city': 'Wright Town',
      'zone': 'Zone A',
      'area': 'Ranjhi'
    },
    {
      'country': 'India',
      'state': 'Maharashtra',
      'district': 'Mumbai',
      'city': 'Bandra',
      'zone': 'Zone C',
      'area': 'Lokhandwala'
    },
    {
      'country': 'India',
      'state': 'Maharashtra',
      'district': 'Pune',
      'city': 'Shivajinagar',
      'zone': 'Zone D',
      'area': 'Shivaji Chowk'
    },
    {
      'country': 'India',
      'state': 'Uttar Pradesh',
      'district': 'Lucknow',
      'city': 'Hazratganj',
      'zone': 'Zone E',
      'area': 'Alambagh'
    },
  ];

  static List<String> getCountries() {
    return locations.map((e) => e['country'] as String).toSet().toList();
  }

  static List<String> getStates(String country) {
    return locations
        .where((e) => e['country'] == country)
        .map((e) => e['state'] as String)
        .toSet()
        .toList();
  }

  static List<String> getDistricts(String country, String state) {
    return locations
        .where((e) => e['country'] == country && e['state'] == state)
        .map((e) => e['district'] as String)
        .toSet()
        .toList();
  }

  static List<String> getCities(String country, String state, String district) {
    return locations
        .where((e) =>
            e['country'] == country &&
            e['state'] == state &&
            e['district'] == district)
        .map((e) => e['city'] as String)
        .toSet()
        .toList();
  }

  static List<String> getZones(
      String country, String state, String district, String city) {
    return locations
        .where((e) =>
            e['country'] == country &&
            e['state'] == state &&
            e['district'] == district &&
            e['city'] == city)
        .map((e) => e['zone'] as String)
        .toSet()
        .toList();
  }

  static List<String> getAreas(String country, String state, String district,
      String city, String zone) {
    return locations
        .where((e) =>
            e['country'] == country &&
            e['state'] == state &&
            e['district'] == district &&
            e['city'] == city &&
            e['zone'] == zone)
        .map((e) => e['area'] as String)
        .toSet()
        .toList();
  }
}
