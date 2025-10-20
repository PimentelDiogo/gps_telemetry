import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/models/telemetry_session.dart';
import '../../../shared/models/telemetry_data.dart';
import '../../../shared/repositories/telemetry_repository.dart';

class SessionDetailsViewModel extends ChangeNotifier {
  final TelemetryRepository _telemetryRepository = Modular.get<TelemetryRepository>();
  
  SessionDetailsViewModel();

  TelemetrySession? _session;
  List<TelemetryData> _telemetryPoints = [];
  bool _isLoading = false;
  String? _errorMessage;

  TelemetrySession? get session => _session;
  List<TelemetryData> get telemetryPoints => _telemetryPoints;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalDistance => _session?.totalDistance ?? 0.0;
  double get maxSpeed => _session?.maxSpeed ?? 0.0;
  double get avgSpeed => _session?.avgSpeed ?? 0.0;
  Duration get duration => _session?.duration ?? Duration.zero;
  int get totalPoints => _telemetryPoints.length;

  String get formattedDistance {
    if (totalDistance < 1000) {
      return '${totalDistance.toStringAsFixed(0)} m';
    } else {
      return '${(totalDistance / 1000).toStringAsFixed(2)} km';
    }
  }
  String get formattedMaxSpeed => '${maxSpeed.toStringAsFixed(1)} km/h';
  String get formattedAvgSpeed => '${avgSpeed.toStringAsFixed(1)} km/h';
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

  String get formattedStartTime {
    if (_session?.startTime == null) return 'N/A';
    final startTime = _session!.startTime;
    return '${startTime.day.toString().padLeft(2, '0')}/${startTime.month.toString().padLeft(2, '0')}/${startTime.year} '
           '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  String get formattedEndTime {
    if (_session?.endTime == null) return 'N/A';
    final endTime = _session!.endTime!;
    return '${endTime.day.toString().padLeft(2, '0')}/${endTime.month.toString().padLeft(2, '0')}/${endTime.year} '
           '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> loadSessionDetails(int sessionId) async {
    _setLoading(true);
    _clearError();

    try {
      _session = await _telemetryRepository.getSession(sessionId);
      
      if (_session == null) {
        _setError('Sessão não encontrada');
        return;
      }

      _telemetryPoints = await _telemetryRepository.getSessionPoints(sessionId);
      
    } catch (e) {
      _setError('Erro ao carregar detalhes da sessão: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteSession() async {
    if (_session == null) return;

    try {
      await _telemetryRepository.deleteSession(_session!.id!);
      _navigateBack();
    } catch (e) {
      _setError('Erro ao excluir sessão: $e');
    }
  }

  Future<void> exportSession() async {
    if (_session == null || _telemetryPoints.isEmpty) {
      _setError('Nenhum dado disponível para exportação');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      await _showExportFormatDialog();
    } catch (e) {
      _setError('Erro ao exportar dados: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _showExportFormatDialog() async {
    await _exportToCSV();
    await _exportToJSON();
  }

  Future<void> _exportToCSV() async {
    try {
      List<List<dynamic>> csvData = [
        [
          'Timestamp',
          'Data/Hora',
          'Latitude',
          'Longitude',
          'Velocidade (km/h)',
          'Altitude (m)',
          'Aceleração X',
          'Aceleração Y',
          'Aceleração Z',
          'Direção (°)'
        ]
      ];

      for (var point in _telemetryPoints) {
        csvData.add([
          point.timestamp.millisecondsSinceEpoch,
          point.timestamp.toIso8601String(),
          point.latitude,
          point.longitude,
          point.speed ?? 0.0,
          point.altitude ?? 0.0,
          point.accelerationX ?? 0.0,
          point.accelerationY ?? 0.0,
          point.accelerationZ ?? 0.0,
          point.heading ?? 0.0,
        ]);
      }

      String csvString = const ListToCsvConverter().convert(csvData);

      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${_session!.name}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvString);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Dados da sessão ${_session!.name} em formato CSV',
      );
    } catch (e) {
      throw Exception('Erro ao exportar CSV: $e');
    }
  }

  Future<void> _exportToJSON() async {
    try {
      Map<String, dynamic> jsonData = {
        'session': {
          'id': _session!.id,
          'name': _session!.name,
          'startTime': _session!.startTime.toIso8601String(),
          'endTime': _session!.endTime?.toIso8601String(),
          'totalDistance': _session!.totalDistance,
          'maxSpeed': _session!.maxSpeed,
          'avgSpeed': _session!.avgSpeed,
          'duration': _session!.duration.inSeconds,
        },
        'statistics': {
          'totalPoints': _telemetryPoints.length,
          'formattedDistance': formattedDistance,
          'formattedMaxSpeed': formattedMaxSpeed,
          'formattedAvgSpeed': formattedAvgSpeed,
          'formattedDuration': formattedDuration,
        },
        'telemetryPoints': _telemetryPoints.map((point) => {
          'timestamp': point.timestamp.millisecondsSinceEpoch,
          'dateTime': point.timestamp.toIso8601String(),
          'latitude': point.latitude,
          'longitude': point.longitude,
          'speed': point.speed,
          'altitude': point.altitude,
          'acceleration': {
            'x': point.accelerationX,
            'y': point.accelerationY,
            'z': point.accelerationZ,
          },
          'heading': point.heading,
        }).toList(),
        'exportInfo': {
          'exportedAt': DateTime.now().toIso8601String(),
          'appVersion': '1.0.0',
          'format': 'JSON',
        }
      };

      String jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${_session!.name}_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Dados da sessão ${_session!.name} em formato JSON',
      );
    } catch (e) {
      throw Exception('Erro ao exportar JSON: $e');
    }
  }

  void viewOnMap() {
    if (_session == null) return;
    
    Modular.to.pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _navigateBack() {
    Modular.to.pop();
  }

  @override
  void dispose() {
    super.dispose();
  }
}