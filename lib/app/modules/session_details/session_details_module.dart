import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'view/session_details_page.dart';
import 'viewmodel/session_details_viewmodel.dart';

class SessionDetailsModule extends Module {
  @override
  void binds(Injector i) {
    print('🟢 SESSION_DETAILS_MODULE: Inicializando binds');
    i.addLazySingleton<SessionDetailsViewModel>(
      () => SessionDetailsViewModel(),
    );
  }

  @override
  void routes(RouteManager r) {
    print('🟢 SESSION_DETAILS_MODULE: Configurando rotas');
    r.child(
      '/:sessionId',
      child: (context) {
        print('🔵 SESSION_DETAILS_MODULE: Rota /:sessionId chamada');
        print('🔵 SESSION_DETAILS_MODULE: Argumentos completos: ${r.args}');
        print('🔵 SESSION_DETAILS_MODULE: Parâmetros: ${r.args.params}');
        
        final sessionIdParam = r.args.params['sessionId'];
        print('🔵 SESSION_DETAILS_MODULE: Parâmetro sessionId recebido: $sessionIdParam');
        
        int? sessionId;
        
        // Try to parse sessionId from URL parameter
        if (sessionIdParam != null) {
          sessionId = int.tryParse(sessionIdParam);
          print('🔵 SESSION_DETAILS_MODULE: sessionId parseado: $sessionId');
        }
        
        if (sessionId == null) {
          print('🔴 SESSION_DETAILS_MODULE: sessionId é null ou inválido, redirecionando para /history');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Modular.to.navigate('/history');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        print('🟢 SESSION_DETAILS_MODULE: Carregando SessionDetailsPage com sessionId: $sessionId');
        return SessionDetailsPage(sessionId: sessionId);
      },
    );
  }
}