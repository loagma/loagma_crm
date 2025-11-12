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
  final int? areaId;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    this.areaId,
    required this.createdAt,
    required this.updatedAt,
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
      areaId: json['areaId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
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
      if (areaId != null) 'areaId': areaId,
    };
  }
}
