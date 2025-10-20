import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/location_service.dart';
import '../services/sensor_service.dart';
import '../database/database_service.dart';
import '../models/telemetry_data.dart';
import '../models/telemetry_session.dart';

class TelemetryRepository {
  final LocationService _locationService;
  final SensorService _sensorService;
  final DatabaseService _databaseService;

  final StreamController<TelemetryData> _telemetryController = 
      StreamController<TelemetryData>.broadcast();

  Position? _currentPosition;
  AccelerometerEvent? _currentAcceleration;
  double? _currentHeading;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<double>? _compassSubscription;

  TelemetryRepository({
    required LocationService locationService,
    required SensorService sensorService,
    required DatabaseService databaseService,
  }) : _locationService = locationService,
       _sensorService = sensorService,
       _databaseService = databaseService;

  Stream<TelemetryData> get telemetryStream => _telemetryController.stream;

  Position? get currentPosition => _currentPosition;

  AccelerometerEvent? get currentAcceleration => _currentAcceleration;

  double? get currentHeading => _currentHeading;

  double get currentSpeed => _currentPosition?.speed != null 
      ? _locationService.calculateSpeed(_currentPosition!) 
      : 0.0;

  String get currentCardinalDirection => _currentHeading != null
      ? _sensorService.getCardinalDirection(_currentHeading!)
      : 'N/A';

  double get currentAccelerationMagnitude => _currentAcceleration != null
      ? _sensorService.calculateAccelerationMagnitude(_currentAcceleration!)
      : 0.0;

  bool get isMoving => _currentAcceleration != null
      ? _sensorService.detectMovement(_currentAcceleration!)
      : false;

  Future<void> startDataCollection() async {
    await _locationService.startLocationTracking();
    _sensorService.startAccelerometerTracking();
    _sensorService.startCompassTracking();

    _positionSubscription = _locationService.positionStream.listen(
      _onPositionUpdate,
      onError: (error) {},
    );

    _accelerometerSubscription = _sensorService.accelerometerStream.listen(
      _onAccelerometerUpdate,
      onError: (error) {},
    );

    _compassSubscription = _sensorService.compassStream.listen(
      _onCompassUpdate,
      onError: (error) {},
    );
  }

  void stopDataCollection() {
    _locationService.stopLocationTracking();
    _sensorService.stopAccelerometerTracking();
    _sensorService.stopCompassTracking();

    _positionSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _compassSubscription?.cancel();

    _positionSubscription = null;
    _accelerometerSubscription = null;
    _compassSubscription = null;
  }

  Future<int> saveTelemetryPoint(int sessionId) async {
    if (_currentPosition == null) {
      throw Exception('Posição atual não disponível');
    }

    final telemetryData = TelemetryData(
      sessionId: sessionId,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      altitude: _currentPosition!.altitude,
      speed: currentSpeed,
      heading: _currentHeading,
      accelerationX: _currentAcceleration?.x,
      accelerationY: _currentAcceleration?.y,
      accelerationZ: _currentAcceleration?.z,
      timestamp: DateTime.now(),
    );

    return await _databaseService.insertTelemetryPoint(telemetryData);
  }

  Future<List<TelemetryData>> getSessionPoints(int sessionId) async {
    return await _databaseService.getSessionPoints(sessionId);
  }

  Future<int> createSession(String name) async {
    return await _databaseService.createSession(name);
  }

  Future<void> endSession(int sessionId) async {
    final points = await _databaseService.getSessionPoints(sessionId);
    
    if (points.isEmpty) {
      await _databaseService.endSession(sessionId);
      return;
    }

    double totalDistance = 0.0;
    double maxSpeed = 0.0;
    double totalSpeed = 0.0;
    int speedCount = 0;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      
      if (point.speed != null && point.speed! > maxSpeed) {
        maxSpeed = point.speed!;
      }
      
      if (point.speed != null) {
        totalSpeed += point.speed!;
        speedCount++;
      }
      
      if (i > 0) {
        final previousPoint = points[i - 1];
        final distance = Geolocator.distanceBetween(
          previousPoint.latitude,
          previousPoint.longitude,
          point.latitude,
          point.longitude,
        );
        totalDistance += distance;
      }
    }

    final avgSpeed = speedCount > 0 ? totalSpeed / speedCount : 0.0;

    await _databaseService.endSession(
      sessionId,
      totalDistance: totalDistance,
      maxSpeed: maxSpeed,
      avgSpeed: avgSpeed,
    );
  }

  Future<List<TelemetrySession>> getAllSessions() async {
    final sessionsData = await _databaseService.getAllSessions();
    return sessionsData.map((data) => TelemetrySession.fromMap(data)).toList();
  }

  Future<List<TelemetrySession>> getRecentSessions({int limit = 10}) async {
    final sessionsData = await _databaseService.getAllSessions();
    final sessions = sessionsData.map((data) => TelemetrySession.fromMap(data)).toList();
    
    if (sessions.length > limit) {
      return sessions.take(limit).toList();
    }
    
    return sessions;
  }

  Future<TelemetrySession?> getSession(int sessionId) async {
    final sessionData = await _databaseService.getSession(sessionId);
    if (sessionData == null) return null;
    return TelemetrySession.fromMap(sessionData);
  }

  Future<void> deleteSession(int sessionId) async {
    await _databaseService.deleteSession(sessionId);
  }

  Future<Map<String, dynamic>> getSessionStatistics(int sessionId) async {
    return await _databaseService.getSessionStatistics(sessionId);
  }

  double calculateDistance(Position start, Position end) {
    return _locationService.calculateDistance(start, end);
  }

  TelemetryData? createCurrentTelemetryData(int sessionId) {
    if (_currentPosition == null) return null;

    return TelemetryData(
      sessionId: sessionId,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      altitude: _currentPosition!.altitude,
      speed: currentSpeed,
      heading: _currentHeading,
      accelerationX: _currentAcceleration?.x,
      accelerationY: _currentAcceleration?.y,
      accelerationZ: _currentAcceleration?.z,
      timestamp: DateTime.now(),
    );
  }

  void _onPositionUpdate(Position position) {
    _currentPosition = position;
    _emitTelemetryData();
  }

  void _onAccelerometerUpdate(AccelerometerEvent event) {
    _currentAcceleration = event;
    _emitTelemetryData();
  }

  void _onCompassUpdate(double heading) {
    _currentHeading = heading;
    _emitTelemetryData();
  }

  void _emitTelemetryData() {
    if (_currentPosition != null) {
      final telemetryData = TelemetryData(
        sessionId: 0,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        altitude: _currentPosition!.altitude,
        speed: currentSpeed,
        heading: _currentHeading,
        accelerationX: _currentAcceleration?.x,
        accelerationY: _currentAcceleration?.y,
        accelerationZ: _currentAcceleration?.z,
        timestamp: DateTime.now(),
      );

      _telemetryController.add(telemetryData);
    }
  }

  void dispose() {
    stopDataCollection();
    _telemetryController.close();
  }
}