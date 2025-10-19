import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gps_telemetry/app/modules/telemetry/viewmodel/telemetry_viewmodel.dart';

class TelemetryPage extends StatelessWidget {
  final int? sessionId;

  const TelemetryPage({super.key, this.sessionId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Modular.get<TelemetryViewModel>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Telemetria GPS'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            Consumer<TelemetryViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isRecording) {
                  return IconButton(
                    onPressed: viewModel.stopSession,
                    icon: const Icon(Icons.stop),
                    tooltip: 'Parar Gravação',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: Consumer<TelemetryViewModel>(
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
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Mapa na parte superior
                Expanded(
                  flex: 3,
                  child: _MapSection(viewModel: viewModel),
                ),
                
                // Dados de telemetria na parte inferior
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status da sessão
                        _StatusCard(viewModel: viewModel),
                        const SizedBox(height: 16),
                        
                        // Dados em tempo real
                        Row(
                          children: [
                            Expanded(child: _SpeedCard(viewModel: viewModel)),
                            const SizedBox(width: 8),
                            Expanded(child: _SensorCard(viewModel: viewModel)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Estatísticas da sessão
                        _StatisticsCard(viewModel: viewModel),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: Consumer<TelemetryViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isRecording) {
              return FloatingActionButton(
                onPressed: viewModel.stopSession,
                backgroundColor: Colors.red,
                child: const Icon(Icons.stop),
              );
            } else {
              return FloatingActionButton(
                onPressed: () => _showStartSessionDialog(context, viewModel),
                child: const Icon(Icons.play_arrow),
              );
            }
          },
        ),
      ),
    );
  }

  void _showStartSessionDialog(BuildContext context, TelemetryViewModel viewModel) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Sessão de Telemetria'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome da sessão',
            hintText: 'Ex: Viagem para casa',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                viewModel.startNewSession(controller.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final TelemetryViewModel viewModel;

  const _StatusCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  viewModel.isRecording ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: viewModel.isRecording ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  viewModel.isRecording ? 'Gravando' : 'Parado',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: viewModel.isRecording ? Colors.red : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (viewModel.sessionStartTime != null) ...[
              const SizedBox(height: 8),
              Text(
                'Duração: ${viewModel.formatDuration(viewModel.sessionDuration)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }
}



class _SpeedCard extends StatelessWidget {
  final TelemetryViewModel viewModel;

  const _SpeedCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Velocidade',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  // Otimização: Usar Selector para atualizar apenas quando a velocidade mudar
                  Selector<TelemetryViewModel, double>(
                    selector: (context, viewModel) => viewModel.currentSpeed,
                    builder: (context, currentSpeed, child) {
                      return Text(
                        viewModel.formatSpeed(currentSpeed),
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                  Text(
                    'Velocidade Atual',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final TelemetryViewModel viewModel;

  const _SensorCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sensores',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
               children: [
                 Expanded(
                   child: Column(
                     children: [
                       // Otimização: Usar Consumer para atualizar apenas quando necessário
                        Consumer<TelemetryViewModel>(
                          builder: (context, viewModel, child) {
                            return Text(
                              '${viewModel.currentAcceleration?.x?.toStringAsFixed(2) ?? '0.00'} m/s²',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            );
                          },
                        ),
                       Text(
                         'Aceleração',
                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                           color: Theme.of(context).colorScheme.outline,
                         ),
                       ),
                     ],
                   ),
                 ),
                 Expanded(
                   child: Column(
                     children: [
                       // Otimização: Usar Consumer para atualizar apenas quando necessário
                        Consumer<TelemetryViewModel>(
                          builder: (context, viewModel, child) {
                            return Text(
                              viewModel.getCardinalDirection(),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            );
                          },
                        ),
                       Text(
                         'Direção',
                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                           color: Theme.of(context).colorScheme.outline,
                         ),
                       ),
                     ],
                   ),
                 ),
               ],
             ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  final TelemetryViewModel viewModel;

  const _StatisticsCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estatísticas da Sessão',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Otimização: Usar Selector para atualizar apenas quando a distância mudar
            Selector<TelemetryViewModel, double>(
              selector: (context, viewModel) => viewModel.totalDistance,
              builder: (context, totalDistance, child) {
                return _InfoRow(
                  icon: Icons.straighten,
                  label: 'Distância Total',
                  value: viewModel.formatDistance(totalDistance),
                );
              },
            ),
            // Otimização: Usar Selector para atualizar apenas quando a velocidade máxima mudar
            Selector<TelemetryViewModel, double>(
              selector: (context, viewModel) => viewModel.maxSpeed,
              builder: (context, maxSpeed, child) {
                return _InfoRow(
                  icon: Icons.speed,
                  label: 'Velocidade Máxima',
                  value: viewModel.formatSpeed(maxSpeed),
                );
              },
            ),
            // Otimização: Usar Selector para atualizar apenas quando a velocidade média mudar
            Selector<TelemetryViewModel, double>(
              selector: (context, viewModel) => viewModel.avgSpeed,
              builder: (context, avgSpeed, child) {
                return _InfoRow(
                  icon: Icons.trending_up,
                  label: 'Velocidade Média',
                  value: viewModel.formatSpeed(avgSpeed),
                );
              },
            ),
            // Otimização: Usar Selector para atualizar apenas quando o número de pontos mudar
            Selector<TelemetryViewModel, int>(
              selector: (context, viewModel) => viewModel.pointCount,
              builder: (context, pointCount, child) {
                return _InfoRow(
                  icon: Icons.location_on,
                  label: 'Pontos Coletados',
                  value: pointCount.toString(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MapSection extends StatefulWidget {
  final TelemetryViewModel viewModel;

  const _MapSection({required this.viewModel});

  @override
  State<_MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<_MapSection> {
  GoogleMapController? _mapController;
  LatLng? _initialPosition;

  @override
  void initState() {
    super.initState();
    _setInitialPosition();
  }

  void _setInitialPosition() {
    final position = widget.viewModel.currentPosition;
    if (position != null) {
      _initialPosition = LatLng(position.latitude, position.longitude);
    } else {
      // Posição padrão (São Paulo)
      _initialPosition = const LatLng(-23.5505, -46.6333);
    }
  }

  void _centerOnCurrentLocation() {
    final position = widget.viewModel.currentPosition;
    if (position != null && _mapController != null) {
      final latLng = LatLng(position.latitude, position.longitude);
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(latLng),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                // Delay para evitar operações simultâneas que podem causar buffer overflow
                Future.delayed(const Duration(milliseconds: 400), () {
                  if (mounted && _mapController != null) {
                    // Mapa pronto para operações
                  }
                });
              },
              initialCameraPosition: CameraPosition(
                target: _initialPosition ?? const LatLng(-23.5505, -46.6333),
                zoom: 15.0,
              ),
              markers: widget.viewModel.markers,
              polylines: widget.viewModel.polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomControlsEnabled: true,
              compassEnabled: true,
              trafficEnabled: false,
            ),
            
            // Botão para centralizar na localização atual
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: "center_location",
                onPressed: _centerOnCurrentLocation,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.my_location,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            
            // Indicador de status de gravação
            if (widget.viewModel.isRecording)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'GRAVANDO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}