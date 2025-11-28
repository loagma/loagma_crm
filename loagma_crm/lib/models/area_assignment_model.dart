class AreaAssignment {
  final String id;
  final String salesmanId;
  final String salesmanName;
  final String pinCode;
  final String country;
  final String state;
  final String district;
  final String city;
  final List<String> areas;
  final List<String> businessTypes;
  final DateTime assignedDate;
  final int totalBusinesses;

  AreaAssignment({
    required this.id,
    required this.salesmanId,
    required this.salesmanName,
    required this.pinCode,
    required this.country,
    required this.state,
    required this.district,
    required this.city,
    required this.areas,
    required this.businessTypes,
    required this.assignedDate,
    this.totalBusinesses = 0,
  });

  factory AreaAssignment.fromJson(Map<String, dynamic> json) {
    return AreaAssignment(
      id: json['id'] ?? json['_id'] ?? '',
      salesmanId: json['salesmanId'] ?? '',
      salesmanName: json['salesmanName'] ?? '',
      pinCode: json['pinCode'] ?? '',
      country: json['country'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      city: json['city'] ?? '',
      areas: json['areas'] != null ? List<String>.from(json['areas']) : [],
      businessTypes: json['businessTypes'] != null
          ? List<String>.from(json['businessTypes'])
          : [],
      assignedDate: json['assignedDate'] != null
          ? DateTime.parse(json['assignedDate'])
          : DateTime.now(),
      totalBusinesses: json['totalBusinesses'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'salesmanId': salesmanId,
      'salesmanName': salesmanName,
      'pinCode': pinCode,
      'country': country,
      'state': state,
      'district': district,
      'city': city,
      'areas': areas,
      'businessTypes': businessTypes,
      'assignedDate': assignedDate.toIso8601String(),
      'totalBusinesses': totalBusinesses,
    };
  }
}
