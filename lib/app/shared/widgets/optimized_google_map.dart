import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Widget otimizado para GoogleMap que gerencia melhor os recursos
/// e evita o erro "Unable to acquire a buffer item"
class OptimizedGoogleMap extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final MapType mapType;
  final bool zoomControlsEnabled;
  final bool compassEnabled;
  final bool trafficEnabled;
  final bool mapToolbarEnabled;
  final Function(GoogleMapController)? onMapCreated;
  final Function(LatLng)? onTap;
  final double? height;
  final BorderRadius? borderRadius;

  const OptimizedGoogleMap({
    super.key,
    required this.initialCameraPosition,
    this.markers = const {},
    this.polylines = const {},
    this.myLocationEnabled = true,
    this.myLocationButtonEnabled = false,
    this.mapType = MapType.normal,
    this.zoomControlsEnabled = true,
    this.compassEnabled = true,
    this.trafficEnabled = false,
    this.mapToolbarEnabled = false,
    this.onMapCreated,
    this.onTap,
    this.height,
    this.borderRadius,
  });

  @override
  State<OptimizedGoogleMap> createState() => _OptimizedGoogleMapState();
}

class _OptimizedGoogleMapState extends State<OptimizedGoogleMap> {
  GoogleMapController? _mapController;
  bool _isMapReady = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Pequeno delay para evitar conflitos de inicialização
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && !_isDisposed) {
        setState(() {
          // Força rebuild após delay inicial
        });
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    if (_isDisposed || !mounted) return;
    
    _mapController = controller;
    
    // Delay para evitar operações simultâneas que podem causar buffer overflow
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_isDisposed && _mapController != null) {
        _isMapReady = true;
        widget.onMapCreated?.call(controller);
      }
    });
  }

  void _onTap(LatLng position) {
    if (_isMapReady && !_isDisposed && mounted) {
      widget.onTap?.call(position);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mapWidget = GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: widget.initialCameraPosition,
      markers: widget.markers,
      polylines: widget.polylines,
      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: widget.myLocationButtonEnabled,
      mapType: widget.mapType,
      zoomControlsEnabled: widget.zoomControlsEnabled,
      compassEnabled: widget.compassEnabled,
      trafficEnabled: widget.trafficEnabled,
      mapToolbarEnabled: widget.mapToolbarEnabled,
      onTap: widget.onTap != null ? _onTap : null,
      // Configurações otimizadas para reduzir uso de buffer
      liteModeEnabled: false, // Desabilitado para melhor performance
      buildingsEnabled: false, // Reduz uso de recursos gráficos
      indoorViewEnabled: false, // Reduz uso de recursos gráficos
    );

    if (widget.height != null || widget.borderRadius != null) {
      mapWidget = Container(
        height: widget.height,
        decoration: widget.borderRadius != null
            ? BoxDecoration(
                borderRadius: widget.borderRadius!,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : null,
        child: widget.borderRadius != null
            ? ClipRRect(
                borderRadius: widget.borderRadius!,
                child: mapWidget,
              )
            : mapWidget,
      );
    }

    return mapWidget;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isMapReady = false;
    
    // Delay para garantir que operações pendentes sejam concluídas
    Future.delayed(const Duration(milliseconds: 100), () {
      _mapController?.dispose();
      _mapController = null;
    });
    
    super.dispose();
  }
}