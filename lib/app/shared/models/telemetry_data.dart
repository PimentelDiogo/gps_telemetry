class TelemetryData {
  final int? id;
  final int sessionId;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? speed;
  final double? heading;
  final double? accelerationX;
  final double? accelerationY;
  final double? accelerationZ;
  final DateTime timestamp;

  TelemetryData({
    this.id,
    required this.sessionId,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.speed,
    this.heading,
    this.accelerationX,
    this.accelerationY,
    this.accelerationZ,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'acceleration_x': accelerationX,
      'acceleration_y': accelerationY,
      'acceleration_z': accelerationZ,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory TelemetryData.fromMap(Map<String, dynamic> map) {
    return TelemetryData(
      id: map['id']?.toInt(),
      sessionId: map['session_id']?.toInt() ?? 0,
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      altitude: map['altitude']?.toDouble(),
      speed: map['speed']?.toDouble(),
      heading: map['heading']?.toDouble(),
      accelerationX: map['acceleration_x']?.toDouble(),
      accelerationY: map['acceleration_y']?.toDouble(),
      accelerationZ: map['acceleration_z']?.toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp']?.toInt() ?? 0,
      ),
    );
  }

  TelemetryData copyWith({
    int? id,
    int? sessionId,
    double? latitude,
    double? longitude,
    double? altitude,
    double? speed,
    double? heading,
    double? accelerationX,
    double? accelerationY,
    double? accelerationZ,
    DateTime? timestamp,
  }) {
    return TelemetryData(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      accelerationX: accelerationX ?? this.accelerationX,
      accelerationY: accelerationY ?? this.accelerationY,
      accelerationZ: accelerationZ ?? this.accelerationZ,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'TelemetryData{id: $id, sessionId: $sessionId, lat: $latitude, lng: $longitude, speed: $speed, timestamp: $timestamp}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TelemetryData &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.altitude == altitude &&
        other.speed == speed &&
        other.heading == heading &&
        other.accelerationX == accelerationX &&
        other.accelerationY == accelerationY &&
        other.accelerationZ == accelerationZ &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      sessionId,
      latitude,
      longitude,
      altitude,
      speed,
      heading,
      accelerationX,
      accelerationY,
      accelerationZ,
      timestamp,
    );
  }
}