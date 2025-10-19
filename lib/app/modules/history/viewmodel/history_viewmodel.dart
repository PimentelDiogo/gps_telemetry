import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../shared/repositories/telemetry_repository.dart';
import '../../../shared/models/telemetry_session.dart';

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
    Modular.to.pushNamed('/session-details/', arguments: {'sessionId': sessionId});
  }

  /// Navega para criar nova sessão
  void navigateToNewSession() {
    Modular.to.pushNamed('/telemetry');
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