import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../shared/models/telemetry_data.dart';
import '../../../shared/widgets/optimized_google_map.dart';

class SessionMapWidget extends StatefulWidget {
  final List<TelemetryData> telemetryPoints;
  final double? initialZoom;

  const SessionMapWidget({
    super.key,
    required this.telemetryPoints,
    this.initialZoom = 15.0,
  });

  @override
  State<SessionMapWidget> createState() => _SessionMapWidgetState();
}

class _SessionMapWidgetState extends State<SessionMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _setupMapData();
  }

  void _setupMapData() {
    if (widget.telemetryPoints.isEmpty) return;

    // Create markers for start and end points
    _markers = {
      Marker(
        markerId: const MarkerId('start'),
        position: LatLng(
          widget.telemetryPoints.first.latitude,
          widget.telemetryPoints.first.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(
          title: 'Início',
          snippet: 'Ponto de partida da sessão',
        ),
      ),
      if (widget.telemetryPoints.length > 1)
        Marker(
          markerId: const MarkerId('end'),
          position: LatLng(
            widget.telemetryPoints.last.latitude,
            widget.telemetryPoints.last.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'Fim',
            snippet: 'Ponto final da sessão',
          ),
        ),
    };

    // Create polyline for the route
    if (widget.telemetryPoints.length > 1) {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: widget.telemetryPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(),
          color: Colors.blue,
          width: 4,
          patterns: [],
        ),
      };
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapReady = true;
    
    // Delay para evitar operações simultâneas que podem causar buffer overflow
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _isMapReady) {
        _fitMapToRoute();
      }
    });
  }

  void _fitMapToRoute() {
    if (widget.telemetryPoints.isEmpty || _mapController == null || !_isMapReady || !mounted) return;

    if (widget.telemetryPoints.length == 1) {
      // Single point - just center on it
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            widget.telemetryPoints.first.latitude,
            widget.telemetryPoints.first.longitude,
          ),
          widget.initialZoom ?? 15.0,
        ),
      );
      return;
    }

    // Multiple points - fit to bounds
    double minLat = widget.telemetryPoints.first.latitude;
    double maxLat = widget.telemetryPoints.first.latitude;
    double minLng = widget.telemetryPoints.first.longitude;
    double maxLng = widget.telemetryPoints.first.longitude;

    for (final point in widget.telemetryPoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.telemetryPoints.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 8),
              Text(
                'Nenhum ponto de telemetria disponível',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return OptimizedGoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: LatLng(
            widget.telemetryPoints.first.latitude,
            widget.telemetryPoints.first.longitude,
          ),
          zoom: widget.initialZoom ?? 15.0,
        ),
        markers: _markers,
        polylines: _polylines,
        mapType: MapType.normal,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        mapToolbarEnabled: false,
        height: 300,
         borderRadius: BorderRadius.circular(12),
       );
  }

  @override
  void dispose() {
    _isMapReady = false;
    _mapController?.dispose();
    _mapController = null;
    _markers.clear();
    _polylines.clear();
    super.dispose();
  }
}