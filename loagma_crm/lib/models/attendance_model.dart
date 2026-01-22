import 'package:flutter/foundation.dart';

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
    try {
      // Parse punch-in time - use the raw punchInTime from database (UTC)
      // and convert to local time for display
      DateTime? parsePunchInTime() {
        final rawTime = json['punchInTime'];
        if (rawTime == null) return null;

        try {
          // Parse the UTC time from database
          final utcTime = DateTime.parse(rawTime.toString());
          // Convert to local time for display
          return utcTime.toLocal();
        } catch (e) {
          debugPrint('Error parsing punchInTime: $e');
          return null;
        }
      }

      DateTime? parsePunchOutTime() {
        final rawTime = json['punchOutTime'];
        if (rawTime == null) return null;

        try {
          // Parse the UTC time from database
          final utcTime = DateTime.parse(rawTime.toString());
          // Convert to local time for display
          return utcTime.toLocal();
        } catch (e) {
          debugPrint('Error parsing punchOutTime: $e');
          return null;
        }
      }

      return AttendanceModel(
        id: json['id']?.toString() ?? '',
        employeeId: json['employeeId']?.toString() ?? '',
        employeeName: json['employeeName']?.toString() ?? '',
        date: _parseDateTime(json['date']) ?? DateTime.now(),
        punchInTime: parsePunchInTime() ?? DateTime.now(),
        punchInLatitude: _parseDouble(json['punchInLatitude']) ?? 0.0,
        punchInLongitude: _parseDouble(json['punchInLongitude']) ?? 0.0,
        punchInPhoto: json['punchInPhoto']?.toString(),
        punchInAddress: json['punchInAddress']?.toString(),
        bikeKmStart: json['bikeKmStart']?.toString(),
        punchOutTime: parsePunchOutTime(),
        punchOutLatitude: json['punchOutLatitude'] != null
            ? _parseDouble(json['punchOutLatitude'])
            : null,
        punchOutLongitude: json['punchOutLongitude'] != null
            ? _parseDouble(json['punchOutLongitude'])
            : null,
        punchOutPhoto: json['punchOutPhoto']?.toString(),
        punchOutAddress: json['punchOutAddress']?.toString(),
        bikeKmEnd: json['bikeKmEnd']?.toString(),
        totalWorkHours: json['totalWorkHours'] != null
            ? _parseDouble(json['totalWorkHours'])
            : null,
        totalDistanceKm: json['totalDistanceKm'] != null
            ? _parseDouble(json['totalDistanceKm'])
            : null,
        status: json['status']?.toString() ?? 'active',
        createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error parsing AttendanceModel from JSON: $e');
      debugPrint('JSON data: $json');
      rethrow;
    }
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
        if (dateValue.isEmpty) return null;
        // Parse ISO format and convert to local time
        return DateTime.parse(dateValue).toLocal();
      } else if (dateValue is DateTime) {
        return dateValue.toLocal();
      } else if (dateValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue).toLocal();
      } else {
        debugPrint(
          'Warning: Unexpected date format: $dateValue (${dateValue.runtimeType})',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error parsing date: $dateValue, error: $e');
      return null;
    }
  }

  // Helper method for safe double parsing
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;

    try {
      if (value is double) {
        return value;
      } else if (value is int) {
        return value.toDouble();
      } else if (value is String) {
        return double.parse(value);
      } else {
        debugPrint(
          'Warning: Unexpected number format: $value (${value.runtimeType})',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error parsing double: $value, error: $e');
      return null;
    }
  }

  // Get current work duration for active attendance
  Duration get currentWorkDuration {
    if (!isPunchedIn) return Duration.zero;

    final now = DateTime.now().toLocal();
    final localPunchInTime = punchInTime.toLocal();
    final duration = now.difference(localPunchInTime);

    // Ensure duration is not negative
    return duration.isNegative ? Duration.zero : duration;
  }

  // Get total work duration (for completed attendance)
  Duration get totalWorkDuration {
    if (punchOutTime == null) return currentWorkDuration;

    final localPunchInTime = punchInTime.toLocal();
    final localPunchOutTime = punchOutTime!.toLocal();
    final duration = localPunchOutTime.difference(localPunchInTime);
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
