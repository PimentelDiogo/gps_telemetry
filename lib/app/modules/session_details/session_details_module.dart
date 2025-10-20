import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'view/session_details_page.dart';
import 'viewmodel/session_details_viewmodel.dart';

class SessionDetailsModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<SessionDetailsViewModel>(
      () => SessionDetailsViewModel(),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(
      '/:sessionId',
      child: (context) {
        
        final sessionIdParam = r.args.params['sessionId'];
        
        int? sessionId;
        
        if (sessionIdParam != null) {
          sessionId = int.tryParse(sessionIdParam);
        }
        
        if (sessionId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Modular.to.navigate('/history');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        return SessionDetailsPage(sessionId: sessionId);
      },
    );
  }
}