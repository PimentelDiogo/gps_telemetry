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
    print('🟡 TELEMETRY_MODULE: Configurando rotas do TelemetryModule');
    r.child('/', child: (context) {
      print('🟢 TELEMETRY_MODULE: Criando TelemetryPage');
      return const TelemetryPage();
    });
  }
}