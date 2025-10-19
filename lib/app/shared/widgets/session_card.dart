import 'package:flutter/material.dart';

/// Widget reutilizável para exibir informações de sessões de telemetria
/// 
/// Características:
/// - Exibe status da sessão (ativa/histórico)
/// - Mostra informações formatadas (duração, distância, velocidade)
/// - Menu de ações (visualizar/excluir)
/// - Callback para ações customizáveis
class SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final String Function(Map<String, dynamic>) formatDuration;
  final String Function(double) formatDistance;
  final String Function(double) formatSpeed;
  final VoidCallback onTap;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const SessionCard({
    super.key,
    required this.session,
    required this.formatDuration,
    required this.formatDistance,
    required this.formatSpeed,
    required this.onTap,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = session['end_time'] == null;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green : Colors.grey,
          child: Icon(
            isActive ? Icons.play_arrow : Icons.history,
            color: Colors.white,
          ),
        ),
        title: Text(
          session['name'] ?? 'Sessão sem nome',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duração: ${formatDuration(session)}'),
            if (session['total_distance'] != null)
              Text('Distância: ${formatDistance(session['total_distance'])}'),
            if (session['max_speed'] != null)
              Text('Vel. Máx: ${formatSpeed(session['max_speed'])}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: const Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('Visualizar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'view':
                onView();
                break;
              case 'delete':
                _showDeleteConfirmation(context);
                break;
            }
          },
        ),
        onTap: onTap,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir esta sessão? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}