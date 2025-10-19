import 'package:flutter_modular/flutter_modular.dart';
import 'package:gps_telemetry/app/modules/telemetry/view/telemetry_page.dart';
import 'package:gps_telemetry/app/modules/telemetry/viewmodel/telemetry_viewmodel.dart';

class TelemetryModule extends Module {
  @override
  void binds(Injector i) {
    i.add<TelemetryViewModel>(TelemetryViewModel.new);
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const TelemetryPage());
    r.child('/:sessionId', child: (context) {
      final sessionId = int.tryParse(r.args.params['sessionId'] ?? '0') ?? 0;
      return TelemetryPage(sessionId: sessionId);
    });
  }
}