import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/location_service.dart';
import '../services/sensor_service.dart';
import '../database/database_service.dart';
import '../models/telemetry_data.dart';
import '../models/telemetry_session.dart';

/// Repository que consolida dados de localização e sensores
/// em um único modelo de dados TelemetryData
class TelemetryRepository {
  final LocationService _locationService;
  final SensorService _sensorService;
  final DatabaseService _databaseService;

  // Controladores de stream para dados consolidados
  final StreamController<TelemetryData> _telemetryController = 
      StreamController<TelemetryData>.broadcast();

  // Dados atuais dos sensores
  Position? _currentPosition;
  AccelerometerEvent? _currentAcceleration;
  double? _currentHeading;

  // Subscriptions para os streams dos serviços
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

  /// Stream que emite dados consolidados de telemetria
  Stream<TelemetryData> get telemetryStream => _telemetryController.stream;

  /// Dados atuais de posição
  Position? get currentPosition => _currentPosition;

  /// Dados atuais de aceleração
  AccelerometerEvent? get currentAcceleration => _currentAcceleration;

  /// Direção atual da bússola
  double? get currentHeading => _currentHeading;

  /// Velocidade atual calculada
  double get currentSpeed => _currentPosition?.speed != null 
      ? _locationService.calculateSpeed(_currentPosition!) 
      : 0.0;

  /// Direção cardinal atual
  String get currentCardinalDirection => _currentHeading != null
      ? _sensorService.getCardinalDirection(_currentHeading!)
      : 'N/A';

  /// Magnitude da aceleração atual
  double get currentAccelerationMagnitude => _currentAcceleration != null
      ? _sensorService.calculateAccelerationMagnitude(_currentAcceleration!)
      : 0.0;

  /// Detecta se há movimento baseado na aceleração
  bool get isMoving => _currentAcceleration != null
      ? _sensorService.detectMovement(_currentAcceleration!)
      : false;

  /// Inicia a coleta de dados de todos os sensores
  Future<void> startDataCollection() async {
    // Iniciar serviços
    await _locationService.startLocationTracking();
    _sensorService.startAccelerometerTracking();
    _sensorService.startCompassTracking();

    // Subscrever aos streams
    _positionSubscription = _locationService.positionStream.listen(
      _onPositionUpdate,
      onError: (error) {
        print('Erro no stream de posição: $error');
      },
    );

    _accelerometerSubscription = _sensorService.accelerometerStream.listen(
      _onAccelerometerUpdate,
      onError: (error) {
        print('Erro no stream do acelerômetro: $error');
      },
    );

    _compassSubscription = _sensorService.compassStream.listen(
      _onCompassUpdate,
      onError: (error) {
        print('Erro no stream da bússola: $error');
      },
    );
  }

  /// Para a coleta de dados de todos os sensores
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

  /// Salva um ponto de telemetria no banco de dados
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

  /// Obtém pontos de telemetria de uma sessão
  Future<List<TelemetryData>> getSessionPoints(int sessionId) async {
    return await _databaseService.getSessionPoints(sessionId);
  }

  /// Cria uma nova sessão de telemetria
  Future<int> createSession(String name) async {
    return await _databaseService.createSession(name);
  }

  /// Finaliza uma sessão com estatísticas calculadas
  Future<void> endSession(int sessionId) async {
    // Obter pontos da sessão para calcular estatísticas
    final points = await _databaseService.getSessionPoints(sessionId);
    
    if (points.isEmpty) {
      await _databaseService.endSession(sessionId);
      return;
    }

    // Calcular estatísticas
    double totalDistance = 0.0;
    double maxSpeed = 0.0;
    double totalSpeed = 0.0;
    int speedCount = 0;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      
      // Velocidade máxima
      if (point.speed != null && point.speed! > maxSpeed) {
        maxSpeed = point.speed!;
      }
      
      // Soma para velocidade média
      if (point.speed != null) {
        totalSpeed += point.speed!;
        speedCount++;
      }
      
      // Distância total
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

  /// Obtém todas as sessões
  Future<List<TelemetrySession>> getAllSessions() async {
    final sessionsData = await _databaseService.getAllSessions();
    return sessionsData.map((data) => TelemetrySession.fromMap(data)).toList();
  }

  /// Obtém as últimas N sessões
  Future<List<TelemetrySession>> getRecentSessions({int limit = 10}) async {
    final sessionsData = await _databaseService.getAllSessions();
    final sessions = sessionsData.map((data) => TelemetrySession.fromMap(data)).toList();
    
    // Limitar o número de sessões retornadas
    if (sessions.length > limit) {
      return sessions.take(limit).toList();
    }
    
    return sessions;
  }

  /// Obtém uma sessão específica
  Future<TelemetrySession?> getSession(int sessionId) async {
    final sessionData = await _databaseService.getSession(sessionId);
    if (sessionData == null) return null;
    return TelemetrySession.fromMap(sessionData);
  }

  /// Deleta uma sessão
  Future<void> deleteSession(int sessionId) async {
    await _databaseService.deleteSession(sessionId);
  }

  /// Obtém estatísticas de uma sessão
  Future<Map<String, dynamic>> getSessionStatistics(int sessionId) async {
    return await _databaseService.getSessionStatistics(sessionId);
  }

  /// Calcula a distância entre duas posições
  double calculateDistance(Position start, Position end) {
    return _locationService.calculateDistance(start, end);
  }

  /// Cria um modelo TelemetryData com os dados atuais
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

  /// Callback para atualizações de posição
  void _onPositionUpdate(Position position) {
    _currentPosition = position;
    _emitTelemetryData();
  }

  /// Callback para atualizações do acelerômetro
  void _onAccelerometerUpdate(AccelerometerEvent event) {
    _currentAcceleration = event;
    _emitTelemetryData();
  }

  /// Callback para atualizações da bússola
  void _onCompassUpdate(double heading) {
    _currentHeading = heading;
    _emitTelemetryData();
  }

  /// Emite dados consolidados de telemetria
  void _emitTelemetryData() {
    if (_currentPosition != null) {
      final telemetryData = TelemetryData(
        sessionId: 0, // Será definido pelo consumidor
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

  /// Libera recursos
  void dispose() {
    stopDataCollection();
    _telemetryController.close();
  }
}