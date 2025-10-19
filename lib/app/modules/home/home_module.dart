import 'package:flutter_modular/flutter_modular.dart';
import 'package:gps_telemetry/app/modules/home/view/home_page.dart';
import 'package:gps_telemetry/app/modules/home/viewmodel/home_viewmodel.dart';

class HomeModule extends Module {
  @override
  void binds(Injector i) {
    i.add<HomeViewModel>(HomeViewModel.new);
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const HomePage());
  }
}