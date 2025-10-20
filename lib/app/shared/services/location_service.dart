import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  StreamController<Position>? _positionController;
  StreamSubscription<Position>? _positionSubscription;

  Stream<Position> get positionStream {
    _positionController ??= StreamController<Position>.broadcast();
    return _positionController!.stream;
  }

  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Permission.location.request();
      return permission == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkLocationPermission() async {
    try {
      final permission = await Permission.location.status;
      return permission == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        final granted = await requestLocationPermission();
        if (!granted) {
          return null;
        }
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Serviços de localização estão desabilitados');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
        ),
      );

      return position;
    } catch (e) {
      return null;
    }
  }

  Future<void> startLocationTracking() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        final granted = await requestLocationPermission();
        if (!granted) {
          return;
        }
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _positionController?.add(position);
        },
        onError: (error) {
        },
      );
    } catch (e) {
    }
  }

  void stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void dispose() {
    stopLocationTracking();
    _positionController?.close();
    _positionController = null;
  }

  double calculateSpeed(Position position) {
    return position.speed * 3.6;
  }

  double calculateDistance(Position start, Position end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }
}