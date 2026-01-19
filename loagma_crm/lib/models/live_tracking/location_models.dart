/// Base location data model
class LocationData {
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy;
  final double? speed;
  final double? heading;

  LocationData({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
    this.speed,
    this.heading,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      userId: json['user_id'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
    );
  }
}

/// Live location model with active status
class LiveLocation extends LocationData {
  final bool isActive;
  final DateTime lastUpdate;

  LiveLocation({
    required super.userId,
    required super.latitude,
    required super.longitude,
    required super.timestamp,
    required super.accuracy,
    super.speed,
    super.heading,
    required this.isActive,
    required this.lastUpdate,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['is_active'] = isActive;
    json['last_update'] = lastUpdate.millisecondsSinceEpoch;
    return json;
  }

  factory LiveLocation.fromJson(Map<String, dynamic> json) {
    return LiveLocation(
      userId: json['user_id'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
      isActive: json['is_active'] ?? false,
      lastUpdate: DateTime.fromMillisecondsSinceEpoch(json['last_update'] ?? 0),
    );
  }
}

/// Location history model with additional metadata
class LocationHistory extends LocationData {
  final String id;
  final double? distanceFromPrevious;

  LocationHistory({
    required this.id,
    required super.userId,
    required super.latitude,
    required super.longitude,
    required super.timestamp,
    required super.accuracy,
    super.speed,
    super.heading,
    this.distanceFromPrevious,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['id'] = id;
    json['distance_from_previous'] = distanceFromPrevious;
    return json;
  }

  factory LocationHistory.fromJson(Map<String, dynamic> json) {
    return LocationHistory(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
      distanceFromPrevious: json['distance_from_previous']?.toDouble(),
    );
  }
}

/// User model with role-based access
class TrackingUser {
  final String id;
  final String email;
  final UserRole role;
  final String name;
  final bool active;
  final DateTime createdAt;

  TrackingUser({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    required this.active,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.toString().split('.').last,
      'name': name,
      'active': active,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory TrackingUser.fromJson(Map<String, dynamic> json) {
    return TrackingUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.salesman,
      ),
      name: json['name'] ?? '',
      active: json['active'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] ?? 0),
    );
  }
}

/// User roles for the tracking system
enum UserRole { admin, salesman }
