class TaskAssignment {
  final String id;
  final String salesmanId;
  final String salesmanName;
  final String pincode;
  final String country;
  final String state;
  final String district;
  final String city;
  final List<String> areas;
  final List<String> businessTypes;
  final DateTime assignedDate;
  final int totalBusinesses;

  TaskAssignment({
    required this.id,
    required this.salesmanId,
    required this.salesmanName,
    required this.pincode,
    required this.country,
    required this.state,
    required this.district,
    required this.city,
    required this.areas,
    required this.businessTypes,
    required this.assignedDate,
    required this.totalBusinesses,
  });

  factory TaskAssignment.fromJson(Map<String, dynamic> json) {
    return TaskAssignment(
      id: json['id'] ?? '',
      salesmanId: json['salesmanId'] ?? '',
      salesmanName: json['salesmanName'] ?? '',
      pincode: json['pincode'] ?? '',
      country: json['country'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      city: json['city'] ?? '',
      areas: List<String>.from(json['areas'] ?? []),
      businessTypes: List<String>.from(json['businessTypes'] ?? []),
      assignedDate: DateTime.parse(
        json['assignedDate'] ?? DateTime.now().toIso8601String(),
      ),
      totalBusinesses: json['totalBusinesses'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'salesmanId': salesmanId,
      'salesmanName': salesmanName,
      'pincode': pincode,
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

  @override
  String toString() {
    return 'TaskAssignment(id: $id, salesmanName: $salesmanName, city: $city, pincode: $pincode, areas: ${areas.length})';
  }
}
