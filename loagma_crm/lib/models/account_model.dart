class Account {
  final String id;
  final String accountCode;
  final String? businessName;
  final String personName;
  final DateTime? dateOfBirth;
  final String contactNumber;
  final String? businessType;
  final String? customerStage;
  final String? funnelStage;
  final String? gstNumber;
  final String? panCard;
  final String? ownerImage;
  final String? shopImage;
  final bool? isActive;
  final String? pincode;
  final String? country;
  final String? state;
  final String? district;
  final String? city;
  final String? area;
  final String? address;
  final String? assignedToId;
  final String? createdById;
  final String? approvedById;
  final DateTime? approvedAt;
  final bool isApproved;
  final int? areaId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related objects
  final Map<String, dynamic>? assignedTo;
  final Map<String, dynamic>? createdBy;
  final Map<String, dynamic>? approvedBy;
  final Map<String, dynamic>? areaRelation;

  Account({
    required this.id,
    required this.accountCode,
    this.businessName,
    required this.personName,
    this.dateOfBirth,
    required this.contactNumber,
    this.businessType,
    this.customerStage,
    this.funnelStage,
    this.gstNumber,
    this.panCard,
    this.ownerImage,
    this.shopImage,
    this.isActive,
    this.pincode,
    this.country,
    this.state,
    this.district,
    this.city,
    this.area,
    this.address,
    this.assignedToId,
    this.createdById,
    this.approvedById,
    this.approvedAt,
    this.isApproved = false,
    this.areaId,
    required this.createdAt,
    required this.updatedAt,
    this.assignedTo,
    this.createdBy,
    this.approvedBy,
    this.areaRelation,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      accountCode: json['accountCode'],
      businessName: json['businessName'],
      personName: json['personName'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      contactNumber: json['contactNumber'],
      businessType: json['businessType'],
      customerStage: json['customerStage'],
      funnelStage: json['funnelStage'],
      gstNumber: json['gstNumber'],
      panCard: json['panCard'],
      ownerImage: json['ownerImage'],
      shopImage: json['shopImage'],
      isActive: json['isActive'],
      pincode: json['pincode'],
      country: json['country'],
      state: json['state'],
      district: json['district'],
      city: json['city'],
      area: json['area'],
      address: json['address'],
      assignedToId: json['assignedToId'],
      createdById: json['createdById'],
      approvedById: json['approvedById'],
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      isApproved: json['isApproved'] ?? false,
      areaId: json['areaId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      assignedTo: json['assignedTo'] is Map
          ? json['assignedTo'] as Map<String, dynamic>?
          : null,
      createdBy: json['createdBy'] is Map
          ? json['createdBy'] as Map<String, dynamic>?
          : null,
      approvedBy: json['approvedBy'] is Map
          ? json['approvedBy'] as Map<String, dynamic>?
          : null,
      areaRelation: json['areaRelation'] is Map
          ? json['areaRelation'] as Map<String, dynamic>?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (businessName != null) 'businessName': businessName,
      'personName': personName,
      'contactNumber': contactNumber,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (businessType != null) 'businessType': businessType,
      if (customerStage != null) 'customerStage': customerStage,
      if (funnelStage != null) 'funnelStage': funnelStage,
      if (gstNumber != null) 'gstNumber': gstNumber,
      if (panCard != null) 'panCard': panCard,
      if (ownerImage != null) 'ownerImage': ownerImage,
      if (shopImage != null) 'shopImage': shopImage,
      if (isActive != null) 'isActive': isActive,
      if (pincode != null) 'pincode': pincode,
      if (country != null) 'country': country,
      if (state != null) 'state': state,
      if (district != null) 'district': district,
      if (city != null) 'city': city,
      if (area != null) 'area': area,
      if (address != null) 'address': address,
      if (assignedToId != null) 'assignedToId': assignedToId,
      if (createdById != null) 'createdById': createdById,
      if (areaId != null) 'areaId': areaId,
    };
  }

  String get createdByName => createdBy?['name'] ?? 'Unknown';
  String get approvedByName => approvedBy?['name'] ?? 'Not Approved';
  String get assignedToName => assignedTo?['name'] ?? 'Unassigned';
  String get areaName => areaRelation?['area_name'] ?? 'No Area';
}
