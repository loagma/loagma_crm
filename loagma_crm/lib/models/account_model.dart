class Account {
  final String id;
  final String accountCode;
  final String personName;
  final DateTime? dateOfBirth;
  final String contactNumber;
  final String? businessType;
  final String? customerStage;
  final String? funnelStage;
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
  final Map<String, dynamic>? area;

  Account({
    required this.id,
    required this.accountCode,
    required this.personName,
    this.dateOfBirth,
    required this.contactNumber,
    this.businessType,
    this.customerStage,
    this.funnelStage,
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
    this.area,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      accountCode: json['accountCode'],
      personName: json['personName'],
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth']) 
          : null,
      contactNumber: json['contactNumber'],
      businessType: json['businessType'],
      customerStage: json['customerStage'],
      funnelStage: json['funnelStage'],
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
      assignedTo: json['assignedTo'],
      createdBy: json['createdBy'],
      approvedBy: json['approvedBy'],
      area: json['area'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personName': personName,
      'contactNumber': contactNumber,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (businessType != null) 'businessType': businessType,
      if (customerStage != null) 'customerStage': customerStage,
      if (funnelStage != null) 'funnelStage': funnelStage,
      if (assignedToId != null) 'assignedToId': assignedToId,
      if (createdById != null) 'createdById': createdById,
      if (areaId != null) 'areaId': areaId,
    };
  }

  String get createdByName => createdBy?['name'] ?? 'Unknown';
  String get approvedByName => approvedBy?['name'] ?? 'Not Approved';
  String get assignedToName => assignedTo?['name'] ?? 'Unassigned';
  String get areaName => area?['area_name'] ?? 'No Area';
}
