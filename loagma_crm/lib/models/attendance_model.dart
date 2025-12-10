class AttendanceModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime date;

  // Punch In Details
  final DateTime punchInTime;
  final double punchInLatitude;
  final double punchInLongitude;
  final String? punchInPhoto;
  final String? punchInAddress;
  final String? bikeKmStart;

  // Punch Out Details
  final DateTime? punchOutTime;
  final double? punchOutLatitude;
  final double? punchOutLongitude;
  final String? punchOutPhoto;
  final String? punchOutAddress;
  final String? bikeKmEnd;

  // Calculated Fields
  final double? totalWorkHours;
  final double? totalDistanceKm;
  final String status;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.punchInTime,
    required this.punchInLatitude,
    required this.punchInLongitude,
    this.punchInPhoto,
    this.punchInAddress,
    this.bikeKmStart,
    this.punchOutTime,
    this.punchOutLatitude,
    this.punchOutLongitude,
    this.punchOutPhoto,
    this.punchOutAddress,
    this.bikeKmEnd,
    this.totalWorkHours,
    this.totalDistanceKm,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      employeeName: json['employeeName'] ?? '',
      date: _parseDateTime(json['date']) ?? DateTime.now(),
      punchInTime: _parseDateTime(json['punchInTime']) ?? DateTime.now(),
      punchInLatitude: (json['punchInLatitude'] as num).toDouble(),
      punchInLongitude: (json['punchInLongitude'] as num).toDouble(),
      punchInPhoto: json['punchInPhoto'],
      punchInAddress: json['punchInAddress'],
      bikeKmStart: json['bikeKmStart'],
      punchOutTime: json['punchOutTime'] != null
          ? _parseDateTime(json['punchOutTime'])
          : null,
      punchOutLatitude: json['punchOutLatitude'] != null
          ? (json['punchOutLatitude'] as num).toDouble()
          : null,
      punchOutLongitude: json['punchOutLongitude'] != null
          ? (json['punchOutLongitude'] as num).toDouble()
          : null,
      punchOutPhoto: json['punchOutPhoto'],
      punchOutAddress: json['punchOutAddress'],
      bikeKmEnd: json['bikeKmEnd'],
      totalWorkHours: json['totalWorkHours'] != null
          ? (json['totalWorkHours'] as num).toDouble()
          : null,
      totalDistanceKm: json['totalDistanceKm'] != null
          ? (json['totalDistanceKm'] as num).toDouble()
          : null,
      status: json['status'] ?? 'active',
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'date': date.toIso8601String(),
      'punchInTime': punchInTime.toIso8601String(),
      'punchInLatitude': punchInLatitude,
      'punchInLongitude': punchInLongitude,
      'punchInPhoto': punchInPhoto,
      'punchInAddress': punchInAddress,
      'bikeKmStart': bikeKmStart,
      'punchOutTime': punchOutTime?.toIso8601String(),
      'punchOutLatitude': punchOutLatitude,
      'punchOutLongitude': punchOutLongitude,
      'punchOutPhoto': punchOutPhoto,
      'punchOutAddress': punchOutAddress,
      'bikeKmEnd': bikeKmEnd,
      'totalWorkHours': totalWorkHours,
      'totalDistanceKm': totalDistanceKm,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isPunchedIn => status == 'active';
  bool get isPunchedOut => status == 'completed';

  // Helper method for safe date parsing
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;

    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        return dateValue;
      } else {
        print('Warning: Unexpected date format: $dateValue');
        return null;
      }
    } catch (e) {
      print('Error parsing date: $dateValue, error: $e');
      return null;
    }
  }

  // Get current work duration for active attendance
  Duration get currentWorkDuration {
    if (!isPunchedIn) return Duration.zero;

    final now = DateTime.now();
    final duration = now.difference(punchInTime);

    // Ensure duration is not negative
    return duration.isNegative ? Duration.zero : duration;
  }

  // Get total work duration (for completed attendance)
  Duration get totalWorkDuration {
    if (punchOutTime == null) return currentWorkDuration;

    final duration = punchOutTime!.difference(punchInTime);
    return duration.isNegative ? Duration.zero : duration;
  }

  // Format work duration as HH:MM
  String get formattedWorkDuration {
    final duration = isPunchedIn ? currentWorkDuration : totalWorkDuration;

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}
