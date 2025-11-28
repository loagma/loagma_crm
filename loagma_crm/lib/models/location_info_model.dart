class LocationInfo {
  final String pinCode;
  final String country;
  final String state;
  final String district;
  final String city;
  final List<String> areas;

  LocationInfo({
    required this.pinCode,
    required this.country,
    required this.state,
    required this.district,
    required this.city,
    required this.areas,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      pinCode: json['pinCode'] ?? '',
      country: json['country'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      city: json['city'] ?? '',
      areas: json['areas'] != null ? List<String>.from(json['areas']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pinCode': pinCode,
      'country': country,
      'state': state,
      'district': district,
      'city': city,
      'areas': areas,
    };
  }
}
