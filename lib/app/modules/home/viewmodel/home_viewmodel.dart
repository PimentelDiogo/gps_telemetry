import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:gps_telemetry/app/shared/services/location_service.dart';
import 'package:gps_telemetry/app/shared/services/sensor_service.dart';
import 'package:gps_telemetry/app/shared/database/database_service.dart';
import 'package:gps_telemetry/app/modules/telemetry/viewmodel/telemetry_viewmodel.dart';

class HomeViewModel extends ChangeNotifier {
  final LocationService _locationService = Modular.get<LocationService>();
  final SensorService _sensorService = Modular.get<SensorService>();
  final DatabaseService _databaseService = Modular.get<DatabaseService>();

  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRecording = false;
  TelemetryViewModel? _telemetryViewModel;

  List<Map<String, dynamic>> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isRecording => _isRecording;

  HomeViewModel() {
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    _setLoading(true);
    try {
      _sessions = await _databaseService.getAllSessions();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar sessões: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshSessions() async {
    await _loadSessions();
  }

  Future<void> createNewSession(String sessionName) async {
    try {
      await _databaseService.createSession(sessionName);
      await _loadSessions();
    } catch (e) {
      _errorMessage = 'Erro ao criar sessão: $e';
      notifyListeners();
    }
  }

  Future<void> deleteSession(int sessionId) async {
    try {
      await _databaseService.deleteSession(sessionId);
      await _loadSessions();
    } catch (e) {
      _errorMessage = 'Erro ao deletar sessão: $e';
      notifyListeners();
    }
  }

  String _generateSessionName() {
    final existingNames = _sessions.map((s) => s['name'] as String).toList();
    
    for (int i = 1; i <= 999; i++) {
      final name = 'rota$i';
      if (!existingNames.contains(name)) {
        return name;
      }
    }
    
    // Fallback se todos os números de 1-999 estiverem ocupados
    return 'rota${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> toggleTelemetry() async {
    if (_isRecording) {
      await _stopTelemetry();
    } else {
      await _startTelemetry();
    }
  }

  Future<void> _startTelemetry() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      // Gerar nome automático
      final sessionName = _generateSessionName();
      
      // Criar nova instância do TelemetryViewModel
      _telemetryViewModel = TelemetryViewModel();
      
      // Iniciar sessão
      await _telemetryViewModel!.startNewSession(sessionName);
      
      _isRecording = true;
      await _loadSessions(); // Atualizar lista de sessões
      
    } catch (e) {
      _errorMessage = 'Erro ao iniciar telemetria: $e';
      _isRecording = false;
      _telemetryViewModel = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _stopTelemetry() async {
    try {
      _setLoading(true);
      
      if (_telemetryViewModel != null) {
        await _telemetryViewModel!.stopSession();
        _telemetryViewModel!.dispose();
        _telemetryViewModel = null;
      }
      
      _isRecording = false;
      await _loadSessions(); // Atualizar lista de sessões
      
    } catch (e) {
      _errorMessage = 'Erro ao parar telemetria: $e';
    } finally {
      _setLoading(false);
    }
  }

  void navigateToTelemetry() {
    Modular.to.pushNamed('/telemetry');
  }

  void navigateToHistory() {
    Modular.to.pushNamed('/history');
  }

  void navigateToSessionDetails(int sessionId) {
    Modular.to.pushNamed('/telemetry/session/$sessionId');
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  String formatSessionDuration(Map<String, dynamic> session) {
    final startTime = session['start_time'] as int?;
    final endTime = session['end_time'] as int?;
    
    if (startTime == null) return 'N/A';
    if (endTime == null) return 'Em andamento';
    
    final duration = Duration(milliseconds: endTime - startTime);
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

  String formatDistance(double? distance) {
    if (distance == null || distance == 0) return '0 km';
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }

  String formatSpeed(double? speed) {
    if (speed == null || speed == 0) return '0 km/h';
    return '${speed.toStringAsFixed(1)} km/h';
  }

  @override
  void dispose() {
    if (_telemetryViewModel != null) {
      _telemetryViewModel!.dispose();
      _telemetryViewModel = null;
    }
    super.dispose();
  }
}