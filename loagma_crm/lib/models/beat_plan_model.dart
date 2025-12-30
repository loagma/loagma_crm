class WeeklyBeatPlan {
  final String id;
  final String salesmanId;
  final String salesmanName;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final List<String> pincodes;
  final int totalAreas;
  final String status; // DRAFT, ACTIVE, LOCKED, COMPLETED
  final String? generatedBy;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? lockedBy;
  final DateTime? lockedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final List<DailyBeatPlan>? dailyPlans;
  final Map<String, dynamic>? salesman;
  final Map<String, dynamic>? generator;
  final Map<String, dynamic>? stats;

  WeeklyBeatPlan({
    required this.id,
    required this.salesmanId,
    required this.salesmanName,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.pincodes,
    required this.totalAreas,
    required this.status,
    this.generatedBy,
    this.approvedBy,
    this.approvedAt,
    this.lockedBy,
    this.lockedAt,
    required this.createdAt,
    required this.updatedAt,
    this.dailyPlans,
    this.salesman,
    this.generator,
    this.stats,
  });

  factory WeeklyBeatPlan.fromJson(Map<String, dynamic> json) {
    return WeeklyBeatPlan(
      id: json['id'] ?? '',
      salesmanId: json['salesmanId'] ?? '',
      salesmanName: json['salesmanName'] ?? '',
      weekStartDate: DateTime.parse(json['weekStartDate']),
      weekEndDate: DateTime.parse(json['weekEndDate']),
      pincodes: List<String>.from(json['pincodes'] ?? []),
      totalAreas: json['totalAreas'] ?? 0,
      status: json['status'] ?? 'DRAFT',
      generatedBy: json['generatedBy'],
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      lockedBy: json['lockedBy'],
      lockedAt: json['lockedAt'] != null
          ? DateTime.parse(json['lockedAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      dailyPlans: json['dailyPlans'] != null
          ? (json['dailyPlans'] as List)
                .map((e) => DailyBeatPlan.fromJson(e))
                .toList()
          : null,
      salesman: json['salesman'],
      generator: json['generator'],
      stats: json['stats'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'salesmanId': salesmanId,
      'salesmanName': salesmanName,
      'weekStartDate': weekStartDate.toIso8601String(),
      'weekEndDate': weekEndDate.toIso8601String(),
      'pincodes': pincodes,
      'totalAreas': totalAreas,
      'status': status,
      'generatedBy': generatedBy,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'lockedBy': lockedBy,
      'lockedAt': lockedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper getters
  String get statusDisplayName {
    switch (status) {
      case 'DRAFT':
        return 'Draft';
      case 'ACTIVE':
        return 'Active';
      case 'LOCKED':
        return 'Locked';
      case 'COMPLETED':
        return 'Completed';
      default:
        return status;
    }
  }

  bool get isLocked => status == 'LOCKED';
  bool get isActive => status == 'ACTIVE';
  bool get isDraft => status == 'DRAFT';
  bool get isCompleted => status == 'COMPLETED';

  String get weekDisplayName {
    final start = weekStartDate;
    final end = weekEndDate;
    return '${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';
  }

  int get completionRate {
    if (stats != null && stats!['completionRate'] != null) {
      return stats!['completionRate'] as int;
    }
    return 0;
  }
}

class DailyBeatPlan {
  final String id;
  final String weeklyBeatId;
  final int dayOfWeek; // 1=Monday, 2=Tuesday, ..., 7=Sunday
  final DateTime dayDate;
  final List<String> assignedAreas;
  final int plannedVisits;
  final int actualVisits;
  final String status; // PLANNED, IN_PROGRESS, COMPLETED, MISSED
  final DateTime? completedAt;
  final DateTime? carriedFromDate;
  final DateTime? carriedToDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final List<BeatCompletion>? beatCompletions;
  final List<Map<String, dynamic>>? accounts;

  DailyBeatPlan({
    required this.id,
    required this.weeklyBeatId,
    required this.dayOfWeek,
    required this.dayDate,
    required this.assignedAreas,
    required this.plannedVisits,
    required this.actualVisits,
    required this.status,
    this.completedAt,
    this.carriedFromDate,
    this.carriedToDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.beatCompletions,
    this.accounts,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory DailyBeatPlan.fromJson(Map<String, dynamic> json) {
    return DailyBeatPlan(
      id: json['id'] ?? '',
      weeklyBeatId: json['weeklyBeatId'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? 1,
      dayDate: DateTime.parse(json['dayDate']),
      assignedAreas: List<String>.from(json['assignedAreas'] ?? []),
      plannedVisits: json['plannedVisits'] ?? 0,
      actualVisits: json['actualVisits'] ?? 0,
      status: json['status'] ?? 'PLANNED',
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      carriedFromDate: json['carriedFromDate'] != null
          ? DateTime.parse(json['carriedFromDate'])
          : null,
      carriedToDate: json['carriedToDate'] != null
          ? DateTime.parse(json['carriedToDate'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      beatCompletions: json['beatCompletions'] != null
          ? (json['beatCompletions'] as List)
                .map((e) => BeatCompletion.fromJson(e))
                .toList()
          : null,
      accounts: json['accounts'] != null
          ? List<Map<String, dynamic>>.from(json['accounts'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weeklyBeatId': weeklyBeatId,
      'dayOfWeek': dayOfWeek,
      'dayDate': dayDate.toIso8601String(),
      'assignedAreas': assignedAreas,
      'plannedVisits': plannedVisits,
      'actualVisits': actualVisits,
      'status': status,
      'completedAt': completedAt?.toIso8601String(),
      'carriedFromDate': carriedFromDate?.toIso8601String(),
      'carriedToDate': carriedToDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper getters
  String get dayName {
    const days = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return days[dayOfWeek];
    }
    return 'Unknown';
  }

  String get statusDisplayName {
    switch (status) {
      case 'PLANNED':
        return 'Planned';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'MISSED':
        return 'Missed';
      default:
        return status;
    }
  }

  bool get isCompleted => status == 'COMPLETED';
  bool get isMissed => status == 'MISSED';
  bool get isPlanned => status == 'PLANNED';
  bool get isInProgress => status == 'IN_PROGRESS';

  int get completedAreasCount => beatCompletions?.length ?? 0;
  int get totalAreasCount => assignedAreas.length;

  double get completionPercentage {
    if (totalAreasCount == 0) return 0.0;
    return (completedAreasCount / totalAreasCount) * 100;
  }

  List<String> get completedAreas =>
      beatCompletions?.map((bc) => bc.areaName).toList() ?? [];
  List<String> get pendingAreas =>
      assignedAreas.where((area) => !completedAreas.contains(area)).toList();
}

class BeatCompletion {
  final String id;
  final String dailyBeatId;
  final String salesmanId;
  final String areaName;
  final int accountsVisited;
  final DateTime completedAt;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final bool isVerified;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  BeatCompletion({
    required this.id,
    required this.dailyBeatId,
    required this.salesmanId,
    required this.areaName,
    required this.accountsVisited,
    required this.completedAt,
    this.latitude,
    this.longitude,
    this.notes,
    required this.isVerified,
    this.verifiedBy,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BeatCompletion.fromJson(Map<String, dynamic> json) {
    return BeatCompletion(
      id: json['id'] ?? '',
      dailyBeatId: json['dailyBeatId'] ?? '',
      salesmanId: json['salesmanId'] ?? '',
      areaName: json['areaName'] ?? '',
      accountsVisited: json['accountsVisited'] ?? 0,
      completedAt: DateTime.parse(json['completedAt']),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      notes: json['notes'],
      isVerified: json['isVerified'] ?? false,
      verifiedBy: json['verifiedBy'],
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dailyBeatId': dailyBeatId,
      'salesmanId': salesmanId,
      'areaName': areaName,
      'accountsVisited': accountsVisited,
      'completedAt': completedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'isVerified': isVerified,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class TodaysBeatPlan {
  final WeeklyBeatPlan? weeklyPlan;
  final DailyBeatPlan? dailyPlan;
  final List<Map<String, dynamic>> accounts;
  final List<String> completedAreas;

  TodaysBeatPlan({
    this.weeklyPlan,
    this.dailyPlan,
    required this.accounts,
    required this.completedAreas,
  });

  factory TodaysBeatPlan.fromJson(Map<String, dynamic> json) {
    return TodaysBeatPlan(
      weeklyPlan: json['weeklyPlan'] != null
          ? WeeklyBeatPlan.fromJson(json['weeklyPlan'])
          : null,
      dailyPlan: json['dailyPlan'] != null
          ? DailyBeatPlan.fromJson(json['dailyPlan'])
          : null,
      accounts: List<Map<String, dynamic>>.from(json['accounts'] ?? []),
      completedAreas: List<String>.from(json['completedAreas'] ?? []),
    );
  }

  bool get hasBeatPlan => weeklyPlan != null && dailyPlan != null;
  bool get hasAreas => dailyPlan?.assignedAreas.isNotEmpty ?? false;
  bool get hasAccounts => accounts.isNotEmpty;

  List<String> get pendingAreas {
    if (dailyPlan == null) return [];
    return dailyPlan!.assignedAreas
        .where((area) => !completedAreas.contains(area))
        .toList();
  }

  int get totalAreas => dailyPlan?.assignedAreas.length ?? 0;
  int get completedAreasCount => completedAreas.length;

  double get completionPercentage {
    if (totalAreas == 0) return 0.0;
    return (completedAreasCount / totalAreas) * 100;
  }
}
