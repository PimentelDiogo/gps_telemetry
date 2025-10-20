import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../shared/repositories/telemetry_repository.dart';
import '../../../shared/models/telemetry_session.dart';
import '../../telemetry/viewmodel/telemetry_viewmodel.dart';

class HistoryViewModel extends ChangeNotifier {
  final TelemetryRepository _telemetryRepository = Modular.get<TelemetryRepository>();

  bool _isLoading = false;
  String? _errorMessage;
  List<TelemetrySession> _sessions = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TelemetrySession> get sessions => _sessions;

  HistoryViewModel() {
    loadSessions();
  }

  Future<void> loadSessions() async {
    try {
      _setLoading(true);
      _errorMessage = null;
      _sessions = await _telemetryRepository.getRecentSessions(limit: 10);
    } catch (e) {
      _errorMessage = 'Erro ao carregar histórico: $e';
      _sessions = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshSessions() async {
    await loadSessions();
  }

  Future<void> deleteSession(int sessionId) async {
    try {
      _setLoading(true);
      await _telemetryRepository.deleteSession(sessionId);
      await loadSessions();
    } catch (e) {
      _errorMessage = 'Erro ao deletar sessão: $e';
      _setLoading(false);
    }
  }

  void navigateToSessionDetails(int sessionId) {
    
    try {
      final result = Modular.to.pushNamed('/session-details/$sessionId');
    } catch (e) {
    }
  }

  void navigateToNewSession() {
    Modular.to.pushNamed('/');
  }

  Future<void> startNewSessionWithName(String sessionName) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final telemetryViewModel = TelemetryViewModel();
      
      await telemetryViewModel.startNewSession(sessionName);
      
      Modular.to.pushNamed('/');
      
      await loadSessions();
      
    } catch (e) {
      _errorMessage = 'Erro ao iniciar sessão: $e';
    } finally {
      _setLoading(false);
    }
  }

  void showStartSessionDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Sessão de Telemetria'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome da sessão',
            hintText: 'Ex: Viagem para casa',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                startNewSessionWithName(controller.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}