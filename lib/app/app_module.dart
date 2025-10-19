import 'package:flutter_modular/flutter_modular.dart';
import 'package:gps_telemetry/app/modules/home/home_module.dart';
import 'package:gps_telemetry/app/modules/telemetry/telemetry_module.dart';
import 'package:gps_telemetry/app/modules/history/history_module.dart';
import 'package:gps_telemetry/app/modules/session_details/session_details_module.dart';
import 'package:gps_telemetry/app/shared/services/location_service.dart';
import 'package:gps_telemetry/app/shared/services/sensor_service.dart';
import 'package:gps_telemetry/app/shared/database/database_service.dart';
import 'package:gps_telemetry/app/shared/repositories/telemetry_repository.dart';

class AppModule extends Module {
  @override
  void binds(Injector i) {
    // Serviços compartilhados
    i.addSingleton<LocationService>(() => LocationService());
    i.addSingleton<SensorService>(() => SensorService());
    i.addSingleton<DatabaseService>(() => DatabaseService());
    
    // Repository que consolida dados dos serviços
    i.addSingleton<TelemetryRepository>(() => TelemetryRepository(
      locationService: i.get<LocationService>(),
      sensorService: i.get<SensorService>(),
      databaseService: i.get<DatabaseService>(),
    ));
  }

  @override
  void routes(RouteManager r) {
    // Rota inicial
    r.module('/', module: HomeModule());
    
    // Módulo de telemetria
    r.module('/telemetry', module: TelemetryModule());
    
    // Módulo de histórico
    r.module('/history', module: HistoryModule());
    
    // Módulo de detalhes da sessão
    r.module('/session-details', module: SessionDetailsModule());
  }
}