import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gps_telemetry/app/modules/home/viewmodel/home_viewmodel.dart';
import '../../../shared/widgets/action_card.dart';
import '../../../shared/widgets/session_card.dart';
import 'dart:developer' as dev;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _isMapLoading = true;
  bool _isMapReady = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          dev.log('Permissão de localização negada');
          setState(() {
            _isMapLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        dev.log('Permissão de localização negada permanentemente');
        setState(() {
          _isMapLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isMapLoading = false;
      });

      _addCurrentLocationMarker();
    } catch (e) {
      dev.log('Erro ao obter localização: $e');
      setState(() {
        _isMapLoading = false;
      });
    }
  }

  void _addCurrentLocationMarker() {
    if (_currentPosition != null && _isMapReady) {
      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentPosition!,
            infoWindow: const InfoWindow(
              title: 'Localização Atual',
              snippet: 'Você está aqui',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _isMapReady = true;
    });
    _addCurrentLocationMarker();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Modular.get<HomeViewModel>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'GPS Telemetry',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          elevation: 0,
        ),
        body: Consumer<HomeViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (viewModel.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      viewModel.errorMessage!,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: viewModel.refreshSessions,
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: viewModel.refreshSessions,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ActionCard(
                                  icon: viewModel.isRecording ? Icons.stop : Icons.play_arrow,
                                  title: viewModel.isRecording ? 'Parar Telemetria' : 'Iniciar Telemetria',
                                  color: viewModel.isRecording ? Colors.red : Colors.green,
                                  isActive: viewModel.isRecording,
                                  onTap: () => viewModel.toggleTelemetry(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ActionCard(
                                  icon: Icons.history,
                                  title: 'Histórico',
                                  color: Colors.orange,
                                  onTap: viewModel.navigateToHistory,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Localização Atual',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          // Mapa integrado
                          Container(
                            height: 550,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _isMapLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : GoogleMap(
                                      onMapCreated: _onMapCreated,
                                      initialCameraPosition: CameraPosition(
                                        target: _currentPosition ?? const LatLng(-23.5505, -46.6333),
                                        zoom: 15.0,
                                      ),
                                      markers: _markers,
                                      myLocationEnabled: false,
                                      myLocationButtonEnabled: false,
                                      mapType: MapType.normal,
                                      zoomControlsEnabled: true,
                                      compassEnabled: false,
                                      buildingsEnabled: false,
                                      indoorViewEnabled: false,
                                      trafficEnabled: false,
                                      rotateGesturesEnabled: false,
                                      scrollGesturesEnabled: true,
                                      tiltGesturesEnabled: false,
                                      zoomGesturesEnabled: true,
                                      mapToolbarEnabled: false,
                                      minMaxZoomPreference: const MinMaxZoomPreference(10.0, 20.0),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                 
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}