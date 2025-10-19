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
    print('🟡 HISTORY_MODULE: Configurando rotas do HistoryModule');
    r.child('/', child: (context) {
      print('🟢 HISTORY_MODULE: Criando HistoryPage');
      return const HistoryPage();
    });
  }
}