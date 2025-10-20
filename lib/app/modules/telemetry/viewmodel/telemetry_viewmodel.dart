import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gps_telemetry/app/shared/repositories/telemetry_repository.dart';
import 'package:gps_telemetry/app/shared/database/database_service.dart';
import 'package:gps_telemetry/app/shared/models/telemetry_data.dart';

class TelemetryViewModel extends ChangeNotifier {
  final TelemetryRepository _telemetryRepository = Modular.get<TelemetryRepository>();
  final DatabaseService _databaseService = Modular.get<DatabaseService>();

  int? _currentSessionId;
  bool _isRecording = false;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<TelemetryData>? _telemetrySubscription;
  
  TelemetryData? _currentTelemetryData;
  Marker? _mapMarker;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];
  
  double _totalDistance = 0.0;
  double _maxSpeed = 0.0;
  double _avgSpeed = 0.0;
  int _pointCount = 0;
  DateTime? _sessionStartTime;
  Position? _lastPosition;

  int? get currentSessionId => _currentSessionId;
  bool get isRecording => _isRecording;
  bool get isCollecting => _isRecording;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Position? get currentPosition => _telemetryRepository.currentPosition;
  AccelerometerEvent? get currentAcceleration => _telemetryRepository.currentAcceleration;
  double? get currentHeading => _telemetryRepository.currentHeading;
  TelemetryData? get currentTelemetryData => _currentTelemetryData;
  Marker? get mapMarker => _mapMarker;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  List<LatLng> get routePoints => _routePoints;
  double get totalDistance => _totalDistance;
  double get maxSpeed => _maxSpeed;
  double get avgSpeed => _avgSpeed;
  int get pointCount => _pointCount;
  DateTime? get sessionStartTime => _sessionStartTime;

  double get currentSpeed => _telemetryRepository.currentSpeed;

  Duration get sessionDuration => _sessionStartTime != null 
      ? DateTime.now().difference(_sessionStartTime!) 
      : Duration.zero;

  TelemetryViewModel({int? sessionId}) {
    if (sessionId != null) {
      _loadSession(sessionId);
    }
  }

  Future<void> _loadSession(int sessionId) async {
    _setLoading(true);
    try {
      final session = await _databaseService.getSession(sessionId);
      if (session != null) {
        _currentSessionId = sessionId;
        _totalDistance = session['total_distance']?.toDouble() ?? 0.0;
        _maxSpeed = session['max_speed']?.toDouble() ?? 0.0;
        _avgSpeed = session['avg_speed']?.toDouble() ?? 0.0;
        
        final points = await _databaseService.getSessionPoints(sessionId);
        _pointCount = points.length;
        
        if (session['start_time'] != null) {
          _sessionStartTime = DateTime.fromMillisecondsSinceEpoch(session['start_time']);
        }
        
        if (session['end_time'] == null) {
          _isRecording = true;
          await _startTracking();
        }
      } else {
        _errorMessage = 'Sessão não encontrada';
      }
    } catch (e) {
      _errorMessage = 'Erro ao carregar sessão: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> startNewSession(String sessionName) async {
    if (_isRecording) {
      return;
    }

    try {
      _setLoading(true);
      _errorMessage = null;
      
      _currentSessionId = await _telemetryRepository.createSession(sessionName);
      
      _sessionStartTime = DateTime.now();
      _resetStatistics();
      
      await _startTracking();
      _isRecording = true;
      
    } catch (e) {
      _errorMessage = 'Erro ao iniciar sessão: $e';
      _isRecording = false;
      _currentSessionId = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> stopSession() async {
    if (!_isRecording || _currentSessionId == null) {
      return;
    }

    try {
      _setLoading(true);
      _stopTracking();
      
      await _telemetryRepository.endSession(_currentSessionId!);
      
      _isRecording = false;
      _currentSessionId = null;
      _sessionStartTime = null;
      _resetStatistics();
      clearRoute();
    } catch (e) {
      _errorMessage = 'Erro ao parar sessão: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _startTracking() async {
    try {
      await _telemetryRepository.startDataCollection();
      
      _telemetrySubscription = _telemetryRepository.telemetryStream.listen(
        _onTelemetryUpdate,
        onError: (error) {
          _errorMessage = 'Erro na coleta de dados: $error';
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Erro ao iniciar rastreamento: $e';
      notifyListeners();
    }
  }

  void _stopTracking() {
    _telemetryRepository.stopDataCollection();
    _telemetrySubscription?.cancel();
    _telemetrySubscription = null;
  }

  DateTime? _lastUIUpdate;
  static const Duration _uiUpdateInterval = Duration(milliseconds: 100);

  void _onTelemetryUpdate(TelemetryData telemetryData) {
    _currentTelemetryData = telemetryData;
    
    _updateMapMarker(telemetryData);
    
    _addRoutePoint(telemetryData);
    
    if (_isRecording && _currentSessionId != null) {
      _updateStatistics(telemetryData);
      _saveTelemetryPoint(telemetryData);
    }
    
    final now = DateTime.now();
    if (_lastUIUpdate == null || now.difference(_lastUIUpdate!) >= _uiUpdateInterval) {
      _lastUIUpdate = now;
      notifyListeners();
    }
  }

  void _updateStatistics(TelemetryData telemetryData) {
    final currentPosition = Position(
      latitude: telemetryData.latitude,
      longitude: telemetryData.longitude,
      timestamp: telemetryData.timestamp,
      accuracy: 0,
      altitude: telemetryData.altitude ?? 0,
      altitudeAccuracy: 0,
      heading: telemetryData.heading ?? 0,
      headingAccuracy: 0,
      speed: telemetryData.speed ?? 0,
      speedAccuracy: 0,
    );

    if (_lastPosition != null) {
      final distance = _telemetryRepository.calculateDistance(_lastPosition!, currentPosition);
      _totalDistance += distance;
    }

    final speed = telemetryData.speed ?? 0;
    if (speed > _maxSpeed) {
      _maxSpeed = speed;
    }

    _pointCount++;
    _avgSpeed = _pointCount > 0 ? (_avgSpeed * (_pointCount - 1) + speed) / _pointCount : speed;
    _lastPosition = currentPosition;
  }

  Future<void> _saveTelemetryPoint(TelemetryData telemetryData) async {
    if (_currentSessionId == null) {
      return;
    }

    try {
      await _telemetryRepository.saveTelemetryPoint(_currentSessionId!);
    } catch (e) {
      _errorMessage = 'Erro ao salvar dados: $e';
    }
  }

  void _resetStatistics() {
    _totalDistance = 0.0;
    _maxSpeed = 0.0;
    _avgSpeed = 0.0;
    _pointCount = 0;
    _lastPosition = null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }

  String formatSpeed(double speed) {
    return '${speed.toStringAsFixed(1)} km/h';
  }

  String getCardinalDirection() {
    return _telemetryRepository.currentCardinalDirection;
  }

  void _updateMapMarker(TelemetryData telemetryData) {
    final position = LatLng(telemetryData.latitude, telemetryData.longitude);
    
    _mapMarker = Marker(
      markerId: const MarkerId('current_position'),
      position: position,
      infoWindow: InfoWindow(
        title: 'Posição Atual',
        snippet: 'Velocidade: ${formatSpeed(telemetryData.speed ?? 0)}',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
    
    _markers = {_mapMarker!};
  }

  void _addRoutePoint(TelemetryData telemetryData) {
    final point = LatLng(telemetryData.latitude, telemetryData.longitude);
    _routePoints.add(point);
    
    if (_routePoints.length > 1) {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          color: Colors.blue,
          width: 3,
        ),
      };
    }
  }

  void clearRoute() {
    _routePoints.clear();
    _polylines.clear();
    _markers.clear();
    _mapMarker = null;
    notifyListeners();
  }

  Future<String> _generateSessionName() async {
    final sessions = await _databaseService.getAllSessions();
    final existingNames = sessions.map((s) => s['name'] as String).toList();
    
    for (int i = 1; i <= 999; i++) {
      final name = 'rota$i';
      if (!existingNames.contains(name)) {
        return name;
      }
    }
    
    return 'rota${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> startSessionAutomatically() async {
    if (_isRecording) {
      return;
    }

    try {
      final sessionName = await _generateSessionName();
      await startNewSession(sessionName);
    } catch (e) {
      _errorMessage = 'Erro ao iniciar sessão: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }
}