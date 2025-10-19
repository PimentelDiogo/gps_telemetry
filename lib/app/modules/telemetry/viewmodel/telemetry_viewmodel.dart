import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gps_telemetry/app/shared/repositories/telemetry_repository.dart';
import 'package:gps_telemetry/app/shared/database/database_service.dart';
import 'package:gps_telemetry/app/shared/models/telemetry_data.dart';
import 'dart:developer' as dev;

class TelemetryViewModel extends ChangeNotifier {
  final TelemetryRepository _telemetryRepository = Modular.get<TelemetryRepository>();
  final DatabaseService _databaseService = Modular.get<DatabaseService>();

  // Estado da sessão
  int? _currentSessionId;
  bool _isRecording = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Stream de dados consolidados
  StreamSubscription<TelemetryData>? _telemetrySubscription;
  
  // Estado da UI
  TelemetryData? _currentTelemetryData;
  Marker? _mapMarker;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];
  
  // Estatísticas da sessão
  double _totalDistance = 0.0;
  double _maxSpeed = 0.0;
  double _avgSpeed = 0.0;
  int _pointCount = 0;
  DateTime? _sessionStartTime;
  Position? _lastPosition;

  // Getters
  int? get currentSessionId => _currentSessionId;
  bool get isRecording => _isRecording;
  bool get isCollecting => _isRecording; // Alias para isRecording
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

  // Propriedades calculadas
  double get currentSpeed => _telemetryRepository.currentSpeed;

  Duration get sessionDuration => _sessionStartTime != null 
      ? DateTime.now().difference(_sessionStartTime!) 
      : Duration.zero;

  TelemetryViewModel({int? sessionId}) {
    dev.log("🟡 TELEMETRY_VIEWMODEL: Inicializando TelemetryViewModel - sessionId: $sessionId 🟡");
    if (sessionId != null) {
      _loadSession(sessionId);
    }
  }

  Future<void> _loadSession(int sessionId) async {
    dev.log("🟡 TELEMETRY_VIEWMODEL: Carregando sessão ID: $sessionId 🟡");
    _setLoading(true);
    try {
      final session = await _databaseService.getSession(sessionId);
      if (session != null) {
        dev.log("🟢 TELEMETRY_VIEWMODEL: Sessão encontrada - Nome: ${session['name']}, Distância: ${session['total_distance']} 🟢");
        _currentSessionId = sessionId;
        _totalDistance = session['total_distance']?.toDouble() ?? 0.0;
        _maxSpeed = session['max_speed']?.toDouble() ?? 0.0;
        _avgSpeed = session['avg_speed']?.toDouble() ?? 0.0;
        
        final points = await _databaseService.getSessionPoints(sessionId);
        _pointCount = points.length;
        dev.log("🟡 TELEMETRY_VIEWMODEL: Pontos carregados: ${_pointCount} 🟡");
        
        if (session['start_time'] != null) {
          _sessionStartTime = DateTime.fromMillisecondsSinceEpoch(session['start_time']);
          dev.log("🟡 TELEMETRY_VIEWMODEL: Hora de início: $_sessionStartTime 🟡");
        }
        
        // Se a sessão não tem end_time, ela ainda está ativa
        if (session['end_time'] == null) {
          dev.log("🟡 TELEMETRY_VIEWMODEL: Sessão ainda ativa, retomando gravação 🟡");
          _isRecording = true;
          await _startTracking();
        }
      } else {
        dev.log("🔴 TELEMETRY_VIEWMODEL: Sessão não encontrada para ID: $sessionId 🔴");
        _errorMessage = 'Sessão não encontrada';
      }
    } catch (e) {
      dev.log("🔴 TELEMETRY_VIEWMODEL: Erro ao carregar sessão: $e 🔴");
      _errorMessage = 'Erro ao carregar sessão: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> startNewSession(String sessionName) async {
    if (_isRecording) {
      dev.log("🔴 TELEMETRY_VIEWMODEL: Tentativa de iniciar nova sessão enquanto já está gravando 🔴");
      return;
    }

    dev.log("🟡 TELEMETRY_VIEWMODEL: Iniciando nova sessão: '$sessionName' 🟡");
    try {
      _setLoading(true);
      _errorMessage = null; // Limpar erros anteriores
      
      _currentSessionId = await _telemetryRepository.createSession(sessionName);
      dev.log("🟢 TELEMETRY_VIEWMODEL: Sessão criada com ID: $_currentSessionId 🟢");
      
      _sessionStartTime = DateTime.now();
      _resetStatistics();
      
      await _startTracking();
      _isRecording = true;
      
      dev.log("🟢 TELEMETRY_VIEWMODEL: Nova sessão iniciada com sucesso! 🟢");
    } catch (e) {
      dev.log("🔴 TELEMETRY_VIEWMODEL: Erro ao iniciar sessão: $e 🔴");
      _errorMessage = 'Erro ao iniciar sessão: $e';
      _isRecording = false;
      _currentSessionId = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> stopSession() async {
    if (!_isRecording || _currentSessionId == null) {
      dev.log("🔴 TELEMETRY_VIEWMODEL: Tentativa de parar sessão que não está ativa 🔴");
      return;
    }

    dev.log("🟡 TELEMETRY_VIEWMODEL: Parando sessão ID: $_currentSessionId 🟡");
    try {
      _setLoading(true);
      _stopTracking();
      
      // Finalizar sessão no repository (que calcula estatísticas automaticamente)
      await _telemetryRepository.endSession(_currentSessionId!);
      dev.log("🟢 TELEMETRY_VIEWMODEL: Sessão finalizada com sucesso - Distância total: ${_totalDistance}m, Pontos: $_pointCount 🟢");
      
      _isRecording = false;
      _currentSessionId = null;
      _sessionStartTime = null;
      _resetStatistics();
      clearRoute();
    } catch (e) {
      dev.log("🔴 TELEMETRY_VIEWMODEL: Erro ao parar sessão: $e 🔴");
      _errorMessage = 'Erro ao parar sessão: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _startTracking() async {
    dev.log("🟡 TELEMETRY_VIEWMODEL: Iniciando rastreamento de dados 🟡");
    try {
      // Iniciar coleta de dados usando o repository
      await _telemetryRepository.startDataCollection();
      dev.log("🟢 TELEMETRY_VIEWMODEL: Coleta de dados iniciada no repository 🟢");
      
      // Subscrever ao stream consolidado de telemetria
      _telemetrySubscription = _telemetryRepository.telemetryStream.listen(
        _onTelemetryUpdate,
        onError: (error) {
          dev.log("🔴 TELEMETRY_VIEWMODEL: Erro no stream de telemetria: $error 🔴");
          _errorMessage = 'Erro na coleta de dados: $error';
          notifyListeners();
        },
      );
      dev.log("🟢 TELEMETRY_VIEWMODEL: Subscription ao stream de telemetria criada 🟢");
    } catch (e) {
      dev.log("🔴 TELEMETRY_VIEWMODEL: Erro ao iniciar rastreamento: $e 🔴");
      _errorMessage = 'Erro ao iniciar rastreamento: $e';
      notifyListeners();
    }
  }

  void _stopTracking() {
    dev.log("🟡 TELEMETRY_VIEWMODEL: Parando rastreamento de dados 🟡");
    _telemetryRepository.stopDataCollection();
    _telemetrySubscription?.cancel();
    _telemetrySubscription = null;
    dev.log("🟢 TELEMETRY_VIEWMODEL: Rastreamento parado com sucesso 🟢");
  }

  // Otimização: Controle de frequência de atualizações
  DateTime? _lastUIUpdate;
  static const Duration _uiUpdateInterval = Duration(milliseconds: 100); // Atualizar UI a cada 100ms

  void _onTelemetryUpdate(TelemetryData telemetryData) {
    dev.log("🟡 TELEMETRY_VIEWMODEL: Dados de telemetria recebidos - Lat: ${telemetryData.latitude}, Lng: ${telemetryData.longitude}, Velocidade: ${telemetryData.speed}km/h 🟡");
    
    // Atualizar dados atuais da telemetria
    _currentTelemetryData = telemetryData;
    
    // Atualizar marcador do mapa
    _updateMapMarker(telemetryData);
    
    // Adicionar ponto à rota
    _addRoutePoint(telemetryData);
    
    if (_isRecording && _currentSessionId != null) {
      _updateStatistics(telemetryData);
      _saveTelemetryPoint(telemetryData);
    }
    
    // Otimização: Limitar frequência de atualizações da UI
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
      dev.log("🟡 TELEMETRY_VIEWMODEL: Distância adicionada: ${distance.toStringAsFixed(2)}m, Total: ${_totalDistance.toStringAsFixed(2)}m 🟡");
    }

    final speed = telemetryData.speed ?? 0;
    if (speed > _maxSpeed) {
      _maxSpeed = speed;
      dev.log("🟡 TELEMETRY_VIEWMODEL: Nova velocidade máxima: ${_maxSpeed.toStringAsFixed(1)}km/h 🟡");
    }

    _pointCount++;
    _avgSpeed = _pointCount > 0 ? (_avgSpeed * (_pointCount - 1) + speed) / _pointCount : speed;
    _lastPosition = currentPosition;
    
    dev.log("🟡 TELEMETRY_VIEWMODEL: Estatísticas atualizadas - Pontos: $_pointCount, Vel. Média: ${_avgSpeed.toStringAsFixed(1)}km/h 🟡");
  }

  Future<void> _saveTelemetryPoint(TelemetryData telemetryData) async {
    if (_currentSessionId == null) {
      dev.log("🔴 TELEMETRY_VIEWMODEL: Tentativa de salvar ponto sem sessão ativa 🔴");
      return;
    }

    try {
      await _telemetryRepository.saveTelemetryPoint(_currentSessionId!);
      dev.log("🟢 TELEMETRY_VIEWMODEL: Ponto de telemetria salvo com sucesso 🟢");
    } catch (e) {
      dev.log("🔴 TELEMETRY_VIEWMODEL: Erro ao salvar ponto de telemetria: $e 🔴");
      _errorMessage = 'Erro ao salvar dados: $e';
    }
  }

  void _resetStatistics() {
    dev.log("🟡 TELEMETRY_VIEWMODEL: Resetando estatísticas da sessão 🟡");
    _totalDistance = 0.0;
    _maxSpeed = 0.0;
    _avgSpeed = 0.0;
    _pointCount = 0;
    _lastPosition = null;
  }

  void _setLoading(bool loading) {
    dev.log("🟡 TELEMETRY_VIEWMODEL: Alterando estado de loading para: $loading 🟡");
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
    dev.log("🟡 TELEMETRY_VIEWMODEL: Marcador do mapa atualizado para posição: ${position.latitude}, ${position.longitude} 🟡");
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
      dev.log("🟡 TELEMETRY_VIEWMODEL: Rota atualizada com ${_routePoints.length} pontos 🟡");
    }
  }

  void clearRoute() {
    dev.log("🟡 TELEMETRY_VIEWMODEL: Limpando rota e marcadores 🟡");
    _routePoints.clear();
    _polylines.clear();
    _markers.clear();
    _mapMarker = null;
    notifyListeners();
  }

  @override
  void dispose() {
    dev.log("🟡 TELEMETRY_VIEWMODEL: Fazendo dispose do TelemetryViewModel 🟡");
    _stopTracking();
    super.dispose();
    dev.log("🟢 TELEMETRY_VIEWMODEL: Dispose concluído 🟢");
  }
}