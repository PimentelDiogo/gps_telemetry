import 'package:flutter_modular/flutter_modular.dart';
import 'view/history_page.dart';
import 'viewmodel/history_viewmodel.dart';

class HistoryModule extends Module {
  @override
  void binds(Injector i) {
    i.add<HistoryViewModel>(HistoryViewModel.new);
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const HistoryPage());
  }
}