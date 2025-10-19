import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../shared/repositories/telemetry_repository.dart';
import '../../../shared/models/telemetry_session.dart';
import '../../telemetry/viewmodel/telemetry_viewmodel.dart';

class HistoryViewModel extends ChangeNotifier {
  final TelemetryRepository _telemetryRepository = Modular.get<TelemetryRepository>();

  // Estado da tela
  bool _isLoading = false;
  String? _errorMessage;
  List<TelemetrySession> _sessions = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TelemetrySession> get sessions => _sessions;

  HistoryViewModel() {
    loadSessions();
  }

  /// Carrega as últimas 10 sessões
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

  /// Recarrega as sessões
  Future<void> refreshSessions() async {
    await loadSessions();
  }

  /// Deleta uma sessão
  Future<void> deleteSession(int sessionId) async {
    try {
      _setLoading(true);
      await _telemetryRepository.deleteSession(sessionId);
      // Recarregar a lista após deletar
      await loadSessions();
    } catch (e) {
      _errorMessage = 'Erro ao deletar sessão: $e';
      _setLoading(false);
    }
  }

  /// Navega para os detalhes de uma sessão
  void navigateToSessionDetails(int sessionId) {
    print('🔵 HISTORY_NAVIGATION: Iniciando navegação para sessão $sessionId');
    print('🔵 HISTORY_NAVIGATION: Rota completa: /session-details/$sessionId');
    
    try {
      final result = Modular.to.pushNamed('/session-details/$sessionId');
      print('🟢 HISTORY_NAVIGATION: pushNamed executado com sucesso');
      print('🟢 HISTORY_NAVIGATION: Resultado: $result');
    } catch (e) {
      print('🔴 HISTORY_NAVIGATION: Erro na navegação: $e');
    }
  }

  /// Navega para criar nova sessão
  void navigateToNewSession() {
    Modular.to.pushNamed('/');
  }

  /// Inicia uma nova sessão com nome personalizado
  Future<void> startNewSessionWithName(String sessionName) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      // Criar nova instância do TelemetryViewModel
      final telemetryViewModel = TelemetryViewModel();
      
      // Iniciar sessão
      await telemetryViewModel.startNewSession(sessionName);
      
      // Navegar para a página de telemetria
      Modular.to.pushNamed('/');
      
      // Recarregar sessões após iniciar
      await loadSessions();
      
    } catch (e) {
      _errorMessage = 'Erro ao iniciar sessão: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Mostra dialog para inserir nome da sessão e inicia
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