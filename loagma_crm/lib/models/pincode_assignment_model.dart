class PinCodeAssignment {
  final String salesmanId;
  final String salesmanName;
  final String pinCode;
  final DateTime assignedDate;

  PinCodeAssignment({
    required this.salesmanId,
    required this.salesmanName,
    required this.pinCode,
    required this.assignedDate,
  });

  factory PinCodeAssignment.fromJson(Map<String, dynamic> json) {
    return PinCodeAssignment(
      salesmanId: json['salesmanId'] ?? '',
      salesmanName: json['salesmanName'] ?? '',
      pinCode: json['pinCode'] ?? '',
      assignedDate: json['assignedDate'] != null
          ? DateTime.parse(json['assignedDate'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'salesmanId': salesmanId,
      'salesmanName': salesmanName,
      'pinCode': pinCode,
      'assignedDate': assignedDate.toIso8601String(),
    };
  }
}
