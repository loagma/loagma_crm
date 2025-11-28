class Salesman {
  final String id;
  final String name;
  final String contactNumber;
  final String? employeeCode;
  final String? email;
  final List<String> assignedPinCodes;

  Salesman({
    required this.id,
    required this.name,
    required this.contactNumber,
    this.employeeCode,
    this.email,
    this.assignedPinCodes = const [],
  });

  factory Salesman.fromJson(Map<String, dynamic> json) {
    return Salesman(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      employeeCode: json['employeeCode'],
      email: json['email'],
      assignedPinCodes: json['assignedPinCodes'] != null
          ? List<String>.from(json['assignedPinCodes'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contactNumber': contactNumber,
      'employeeCode': employeeCode,
      'email': email,
      'assignedPinCodes': assignedPinCodes,
    };
  }

  Salesman copyWith({
    String? id,
    String? name,
    String? contactNumber,
    String? employeeCode,
    String? email,
    List<String>? assignedPinCodes,
  }) {
    return Salesman(
      id: id ?? this.id,
      name: name ?? this.name,
      contactNumber: contactNumber ?? this.contactNumber,
      employeeCode: employeeCode ?? this.employeeCode,
      email: email ?? this.email,
      assignedPinCodes: assignedPinCodes ?? this.assignedPinCodes,
    );
  }
}
