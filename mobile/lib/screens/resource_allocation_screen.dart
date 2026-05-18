import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import '../models/incident.dart';
import '../models/resource.dart';
import '../models/agent_log.dart';
import '../services/api_service.dart';
import 'simulation_screen.dart';

class ResourceAllocationScreen extends StatefulWidget {
  const ResourceAllocationScreen({Key? key}) : super(key: key);

  @override
  State<ResourceAllocationScreen> createState() => _ResourceAllocationScreenState();
}

class _ResourceAllocationScreenState extends State<ResourceAllocationScreen> {
  final ApiService _apiService = ApiService();
  late Stream<List<Incident>> _incidentsStream;
  late Stream<List<Resource>> _resourcesStream;
  late Stream<List<AgentTrace>> _logsStream;

  @override
  void initState() {
    super.initState();
    _incidentsStream = _apiService.getIncidentsStream();
    _resourcesStream = _apiService.getResourcesStream();
    _logsStream = _apiService.getAgentLogsStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Bakhabar',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: 'Ai',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<List<Resource>>(
        stream: _resourcesStream,
        builder: (context, resSnapshot) {
          return StreamBuilder<List<Incident>>(
            stream: _incidentsStream,
            builder: (context, incSnapshot) {
              return StreamBuilder<List<AgentTrace>>(
                stream: _logsStream,
                builder: (context, logSnapshot) {
                  if (resSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                  }

                  final resources = resSnapshot.data ?? [];
                  final incidents = incSnapshot.data ?? [];
                  final logs = logSnapshot.data ?? [];

                  // Find trade-off alerts from logs
                  final tradeOffLogs = logs.where((l) => l.action.toLowerCase().contains('trade-off') || l.action.toLowerCase().contains('delay')).toList();

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            'Resource Allocation',
                            style: AppTextStyles.h1.copyWith(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Live overview of active units and critical area deployments. High priority events are currently drawing maximum available assets.',
                            style: AppTextStyles.bodyMuted,
                          ),
                          const SizedBox(height: 24),

                          // Available Pool Card
                          _buildPoolCard(resources),
                          const SizedBox(height: 16),

                          // Trade-off Alert Box
                          if (tradeOffLogs.isNotEmpty)
                            _buildTradeOffBox(tradeOffLogs.first.action)
                          else
                            _buildTradeOffBox('All resources optimally assigned based on current priority.'),
                          
                          const SizedBox(height: 16),

                          // Show Simulation Button
                          _buildSimulationButton(),
                          const SizedBox(height: 28),

                          // Deployment sections
                          Text(
                            'Active Deployments',
                            style: AppTextStyles.h2.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 12),

                          if (incidents.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: Text('No active deployments', style: AppTextStyles.bodyMuted)),
                            )
                          else
                            ...incidents.map((incident) {
                              final assignedResources = resources.where((r) => r.currentIncidentId == incident.id).toList();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildDeploymentCard(incident, assignedResources),
                              );
                            }).toList(),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPoolCard(List<Resource> resources) {
    final medical = resources.where((r) => r.type == 'Medical').toList();
    final police = resources.where((r) => r.type == 'Police').toList();
    final rescue = resources.where((r) => r.type == 'Fire' || r.type == 'Rescue').toList();

    final medicalAvailable = medical.where((r) => r.status == 'available').length;
    final policeAvailable = police.where((r) => r.status == 'available').length;
    final rescueAvailable = rescue.where((r) => r.status == 'available').length;

    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Pool',
              style: AppTextStyles.h2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 20),

            _buildResourcePoolRow(
              icon: LucideIcons.activity,
              title: 'Medical',
              count: '$medicalAvailable / ${medical.length}',
              progress: medical.isEmpty ? 0 : medicalAvailable / medical.length,
              color: AppColors.accent,
            ),
            const SizedBox(height: 16),

            _buildResourcePoolRow(
              icon: LucideIcons.shield,
              title: 'Police',
              count: '$policeAvailable / ${police.length}',
              progress: police.isEmpty ? 0 : policeAvailable / police.length,
              color: AppColors.accent.withOpacity(0.8),
            ),
            const SizedBox(height: 16),

            _buildResourcePoolRow(
              icon: LucideIcons.hardHat,
              title: 'Rescue',
              count: '$rescueAvailable / ${rescue.length}',
              progress: rescue.isEmpty ? 0 : rescueAvailable / rescue.length,
              color: AppColors.dangerRed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeOffBox(String message) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(
            color: AppColors.accent,
            width: 4,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.alertTriangle, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.body.copyWith(fontSize: 14),
                children: [
                  const TextSpan(
                    text: 'Trade-off: ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                  TextSpan(text: message),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SimulationScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.barChart2, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Show Simulation',
              style: AppTextStyles.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeploymentCard(Incident incident, List<Resource> assignedResources) {
    final isHigh = incident.severity.toUpperCase() == 'HIGH' || incident.severity.toUpperCase() == 'CRITICAL';
    final priorityColor = isHigh ? AppColors.dangerRed : AppColors.severityMedium;

    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: priorityColor,
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${incident.location.name.split(',')[0]} ${incident.type.toUpperCase()}',
                    style: AppTextStyles.h2.copyWith(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Priority: ${incident.severity}',
                    style: AppTextStyles.label.copyWith(
                      color: priorityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Monitoring active in ${incident.location.name}. Resources deployed to mitigate impact.',
              style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Resources list
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigned Resources',
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (assignedResources.isEmpty)
                    Text('Awaiting dispatch...', style: AppTextStyles.bodyMuted.copyWith(fontSize: 12))
                  else
                    ...assignedResources.map((res) {
                      IconData icon;
                      Color color;
                      switch (res.type) {
                        case 'Medical':
                          icon = LucideIcons.activity;
                          color = AppColors.accent;
                          break;
                        case 'Police':
                          icon = LucideIcons.shield;
                          color = AppColors.accent.withOpacity(0.8);
                          break;
                        case 'Fire':
                        case 'Rescue':
                          icon = LucideIcons.hardHat;
                          color = AppColors.dangerRed;
                          break;
                        default:
                          icon = LucideIcons.package;
                          color = AppColors.textMuted;
                      }
                      return _buildResourceListItem(icon, res.name, color);
                    }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcePoolRow({
    required IconData icon,
    required String title,
    required String count,
    required double progress,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Text(count, style: AppTextStyles.bodyMuted.copyWith(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildResourceListItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
