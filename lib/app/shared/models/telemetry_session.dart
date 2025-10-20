class TelemetrySession {
  final int? id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalDistance;
  final double maxSpeed;
  final double avgSpeed;
  final DateTime createdAt;

  TelemetrySession({
    this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    this.totalDistance = 0.0,
    this.maxSpeed = 0.0,
    this.avgSpeed = 0.0,
    required this.createdAt,
  });

  Duration get duration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  String get formattedStartDate {
    return '${startTime.day.toString().padLeft(2, '0')}/${startTime.month.toString().padLeft(2, '0')}/${startTime.year} ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get formattedDistance {
    if (totalDistance < 1000) {
      return '${totalDistance.toStringAsFixed(0)} m';
    } else {
      return '${(totalDistance / 1000).toStringAsFixed(2)} km';
    }
  }

  String get formattedMaxSpeed {
    return '${maxSpeed.toStringAsFixed(1)} km/h';
  }

  String get formattedAvgSpeed {
    return '${avgSpeed.toStringAsFixed(1)} km/h';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'total_distance': totalDistance,
      'max_speed': maxSpeed,
      'avg_speed': avgSpeed,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory TelemetrySession.fromMap(Map<String, dynamic> map) {
    return TelemetrySession(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(
        map['start_time']?.toInt() ?? 0,
      ),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'])
          : null,
      totalDistance: map['total_distance']?.toDouble() ?? 0.0,
      maxSpeed: map['max_speed']?.toDouble() ?? 0.0,
      avgSpeed: map['avg_speed']?.toDouble() ?? 0.0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at']?.toInt() ?? 0,
      ),
    );
  }

  TelemetrySession copyWith({
    int? id,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    double? totalDistance,
    double? maxSpeed,
    double? avgSpeed,
    DateTime? createdAt,
  }) {
    return TelemetrySession(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalDistance: totalDistance ?? this.totalDistance,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'TelemetrySession{id: $id, name: $name, duration: $formattedDuration, distance: $formattedDistance}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TelemetrySession &&
        other.id == id &&
        other.name == name &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.totalDistance == totalDistance &&
        other.maxSpeed == maxSpeed &&
        other.avgSpeed == avgSpeed &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      startTime,
      endTime,
      totalDistance,
      maxSpeed,
      avgSpeed,
      createdAt,
    );
  }
}