import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_compass/flutter_compass.dart';

class SensorService {
  StreamController<AccelerometerEvent>? _accelerometerController;
  StreamController<double>? _compassController;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;

  Stream<AccelerometerEvent> get accelerometerStream {
    _accelerometerController ??= StreamController<AccelerometerEvent>.broadcast();
    return _accelerometerController!.stream;
  }

  Stream<double> get compassStream {
    _compassController ??= StreamController<double>.broadcast();
    return _compassController!.stream;
  }

  void startAccelerometerTracking() {
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        _accelerometerController?.add(event);
      },
      onError: (error) {},
    );
  }

  void startCompassTracking() {
    _compassSubscription = FlutterCompass.events?.listen(
      (CompassEvent event) {
        if (event.heading != null) {
          _compassController?.add(event.heading!);
        }
      },
      onError: (error) {},
    );
  }

  void stopAccelerometerTracking() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  void stopCompassTracking() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
  }

  void dispose() {
    stopAccelerometerTracking();
    stopCompassTracking();
    _accelerometerController?.close();
    _compassController?.close();
    _accelerometerController = null;
    _compassController = null;
  }

  double calculateAccelerationMagnitude(AccelerometerEvent event) {
    return sqrt(
      event.x * event.x + 
      event.y * event.y + 
      event.z * event.z
    );
  }

  String getCardinalDirection(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading >= 22.5 && heading < 67.5) return 'NE';
    if (heading >= 67.5 && heading < 112.5) return 'E';
    if (heading >= 112.5 && heading < 157.5) return 'SE';
    if (heading >= 157.5 && heading < 202.5) return 'S';
    if (heading >= 202.5 && heading < 247.5) return 'SW';
    if (heading >= 247.5 && heading < 292.5) return 'W';
    if (heading >= 292.5 && heading < 337.5) return 'NW';
    return 'N';
  }

  bool detectMovement(AccelerometerEvent event, {double threshold = 12.0}) {
    final magnitude = calculateAccelerationMagnitude(event);
    return magnitude > threshold;
  }
}