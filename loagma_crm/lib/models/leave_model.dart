class LeaveModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int numberOfDays;
  final String? reason;
  final String status;
  final DateTime requestedAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? adminRemarks;

  LeaveModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.numberOfDays,
    this.reason,
    required this.status,
    required this.requestedAt,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.adminRemarks,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      employeeName: json['employeeName'] ?? '',
      leaveType: json['leaveType'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      numberOfDays: json['numberOfDays'] ?? 0,
      reason: json['reason'],
      status: json['status'] ?? 'PENDING',
      requestedAt: DateTime.parse(json['requestedAt']),
      approvedBy: json['approver']?['name'],
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      rejectionReason: json['rejectionReason'],
      adminRemarks: json['adminRemarks'],
    );
  }

  Map<String, dynamic> toJson() => {
    'leaveType': leaveType,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'reason': reason,
  };

  // Helper methods for UI
  String get formattedDateRange {
    final startStr = '${startDate.day}/${startDate.month}/${startDate.year}';
    final endStr = '${endDate.day}/${endDate.month}/${endDate.year}';
    return '$startStr - $endStr';
  }

  String get formattedRequestedAt {
    return '${requestedAt.day}/${requestedAt.month}/${requestedAt.year}';
  }

  String get daysText {
    return numberOfDays == 1 ? '1 day' : '$numberOfDays days';
  }

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
  bool get isCancelled => status == 'CANCELLED';
  bool get canCancel => isPending;
}

class LeaveBalance {
  final String id;
  final String employeeId;
  final int year;
  final int sickLeaves;
  final int casualLeaves;
  final int earnedLeaves;
  final int usedSickLeaves;
  final int usedCasualLeaves;
  final int usedEarnedLeaves;

  LeaveBalance({
    required this.id,
    required this.employeeId,
    required this.year,
    required this.sickLeaves,
    required this.casualLeaves,
    required this.earnedLeaves,
    required this.usedSickLeaves,
    required this.usedCasualLeaves,
    required this.usedEarnedLeaves,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      year: json['year'] ?? DateTime.now().year,
      sickLeaves: json['sickLeaves'] ?? 0,
      casualLeaves: json['casualLeaves'] ?? 0,
      earnedLeaves: json['earnedLeaves'] ?? 0,
      usedSickLeaves: json['usedSickLeaves'] ?? 0,
      usedCasualLeaves: json['usedCasualLeaves'] ?? 0,
      usedEarnedLeaves: json['usedEarnedLeaves'] ?? 0,
    );
  }

  // Helper getters
  int get availableSickLeaves => sickLeaves - usedSickLeaves;
  int get availableCasualLeaves => casualLeaves - usedCasualLeaves;
  int get availableEarnedLeaves => earnedLeaves - usedEarnedLeaves;
  int get totalAvailableLeaves =>
      availableSickLeaves + availableCasualLeaves + availableEarnedLeaves;
  int get totalUsedLeaves =>
      usedSickLeaves + usedCasualLeaves + usedEarnedLeaves;
  int get totalAllocatedLeaves => sickLeaves + casualLeaves + earnedLeaves;
}

class LeaveStatistics {
  final LeaveBalance balance;
  final Map<String, int> usedLeaves;
  final int totalLeavesUsed;
  final int totalLeavesAvailable;
  final int pendingRequests;

  LeaveStatistics({
    required this.balance,
    required this.usedLeaves,
    required this.totalLeavesUsed,
    required this.totalLeavesAvailable,
    required this.pendingRequests,
  });

  factory LeaveStatistics.fromJson(Map<String, dynamic> json) {
    return LeaveStatistics(
      balance: LeaveBalance.fromJson(json['balance']),
      usedLeaves: Map<String, int>.from(json['usedLeaves'] ?? {}),
      totalLeavesUsed: json['totalLeavesUsed'] ?? 0,
      totalLeavesAvailable: json['totalLeavesAvailable'] ?? 0,
      pendingRequests: json['pendingRequests'] ?? 0,
    );
  }
}
