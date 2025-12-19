class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String priority;
  final String? targetRole;
  final String? targetUserId;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdAtIST;
  final String? readAtIST;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    this.targetRole,
    this.targetUserId,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdAtIST,
    this.readAtIST,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      priority: json['priority'] ?? 'normal',
      targetRole: json['targetRole'],
      targetUserId: json['targetUserId'],
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdAtIST: json['createdAtIST'],
      readAtIST: json['readAtIST'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'targetRole': targetRole,
      'targetUserId': targetUserId,
      'data': data,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdAtIST': createdAtIST,
      'readAtIST': readAtIST,
    };
  }

  // Helper getters
  String get formattedTime {
    if (createdAtIST != null) {
      return _formatTime(createdAtIST!);
    }
    return _formatTime(createdAt.toIso8601String());
  }

  String get typeIcon {
    switch (type) {
      case 'punch_in':
        return '🟢';
      case 'punch_out':
        return '🔴';
      case 'alert':
        return '⚠️';
      case 'general':
        return '📢';
      default:
        return '📝';
    }
  }

  String get priorityText {
    switch (priority) {
      case 'urgent':
        return 'URGENT';
      case 'high':
        return 'HIGH';
      case 'normal':
        return 'NORMAL';
      case 'low':
        return 'LOW';
      default:
        return 'NORMAL';
    }
  }

  // Get employee name from data if available
  String? get employeeName {
    return data?['employeeName'];
  }

  // Get attendance ID from data if available
  String? get attendanceId {
    return data?['attendanceId'];
  }

  // Get work duration from data if available (for punch-out notifications)
  String? get workDuration {
    return data?['workDurationFormatted'];
  }

  // Get location info from data if available
  Map<String, dynamic>? get locationInfo {
    return data?['location'];
  }

  static String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return timestamp;
    }
  }
}

class NotificationCounts {
  final int total;
  final int unread;
  final int read;
  final int? punchIn;
  final int? punchOut;
  final int? totalUnread;

  NotificationCounts({
    required this.total,
    required this.unread,
    required this.read,
    this.punchIn,
    this.punchOut,
    this.totalUnread,
  });

  factory NotificationCounts.fromJson(Map<String, dynamic> json) {
    return NotificationCounts(
      total: json['total'] ?? 0,
      unread: json['unread'] ?? 0,
      read: json['read'] ?? 0,
      punchIn: json['punchIn'],
      punchOut: json['punchOut'],
      totalUnread: json['totalUnread'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'unread': unread,
      'read': read,
      'punchIn': punchIn,
      'punchOut': punchOut,
      'totalUnread': totalUnread,
    };
  }
}
