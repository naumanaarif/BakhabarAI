import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import '../models/simulation.dart';
import '../models/incident.dart';
import '../services/api_service.dart';
import 'agent_logs_screen.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({Key? key}) : super(key: key);

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final ApiService _apiService = ApiService();
  late Stream<List<ActionSimulation>> _simulationsStream;
  late Stream<List<Incident>> _incidentsStream;

  String _selectedCategory = 'ALL';

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  @override
  void initState() {
    super.initState();
    _simulationsStream = _apiService.getSimulationsStream();
    _incidentsStream = _apiService.getIncidentsStream();
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
      body: StreamBuilder<List<Incident>>(
        stream: _incidentsStream,
        builder: (context, incSnapshot) {
          return StreamBuilder<List<ActionSimulation>>(
            stream: _simulationsStream,
            builder: (context, simSnapshot) {
              if (simSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }

              final simulations = simSnapshot.data ?? [];
              final incidents = incSnapshot.data ?? [];

              // Sort simulations by timestamp descending (newest first)
              simulations.sort((a, b) => b.timestamp.compareTo(a.timestamp));

              // Compute the latest simulation for each incident
              final latestSimIds = <String>{};
              final incidentSeen = <String>{};
              for (var sim in simulations) {
                if (!incidentSeen.contains(sim.incidentId)) {
                  incidentSeen.add(sim.incidentId);
                  latestSimIds.add(sim.id);
                }
              }

              // Dynamically extract types from active simulations
              final activeTypes = simulations
                  .map((sim) {
                    final incident = incidents.firstWhere(
                      (inc) => inc.id == sim.incidentId,
                      orElse: () => Incident(
                        id: 'unknown',
                        type: 'Alert',
                        location: Location(name: 'Unknown', lat: 0, lng: 0),
                        severity: 'LOW',
                        confidence: 0,
                        affectedPopulation: 0,
                        status: '',
                      ),
                    );
                    return incident.type.toUpperCase();
                  })
                  .toSet()
                  .toList();

              activeTypes.sort();
              activeTypes.insert(0, 'ALL');

              final filteredSims = simulations.where((sim) {
                if (_selectedCategory == 'ALL') return true;
                final incident = incidents.firstWhere(
                  (inc) => inc.id == sim.incidentId,
                  orElse: () => Incident(
                    id: 'unknown',
                    type: 'Alert',
                    location: Location(name: 'Unknown', lat: 0, lng: 0),
                    severity: 'LOW',
                    confidence: 0,
                    affectedPopulation: 0,
                    status: '',
                  ),
                );
                return incident.type.toUpperCase() == _selectedCategory;
              }).toList();

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Simulation Outcomes',
                        style: AppTextStyles.h1.copyWith(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dynamic Tab pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: activeTypes
                              .map((type) => _buildTabPill(type))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (filteredSims.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(
                                  LucideIcons.barChart2,
                                  size: 48,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No active simulations for $_selectedCategory',
                                  style: AppTextStyles.bodyMuted,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...filteredSims.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final sim = entry.value;
                          final incident = incidents.firstWhere(
                            (inc) => inc.id == sim.incidentId,
                            orElse: () => Incident(
                              id: 'unknown',
                              type: 'Alert',
                              location: Location(
                                name: 'Unknown',
                                lat: 0,
                                lng: 0,
                              ),
                              severity: 'LOW',
                              confidence: 0,
                              affectedPopulation: 0,
                              status: '',
                            ),
                          );
                          final isLatest = latestSimIds.contains(sim.id);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSimulationBody(sim, isLatest, incident),
                              if (idx < filteredSims.length - 1)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: Colors.grey.shade400,
                                          thickness: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          'NEXT SIMULATION',
                                          style: AppTextStyles.label.copyWith(
                                            color: AppColors.textMuted,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: Colors.grey.shade400,
                                          thickness: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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
      ),
    );
  }

  Widget _buildSimulationBody(
    ActionSimulation sim,
    bool isLatest,
    Incident incident,
  ) {
    final impact = sim.impactPrediction;

    // Format a raw slug like 'fire_extinguished' or 'power_outage' into readable text
    String humanize(String? raw, String fallback) {
      if (raw == null || raw.trim().isEmpty) return fallback;
      final s = raw.trim();
      // If it looks like a raw snake_case slug with no spaces (likely LLM shorthand)
      if (!s.contains(' ') && s.contains('_')) {
        return s.replaceAll('_', ' ').split(' ').map((w) {
          return w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w;
        }).join(' ');
      }
      return s;
    }

    // Add units to bare numeric metric values
    String fmtMetric(String key, dynamic val) {
      final s = val.toString().trim();
      // If it's a pure number, append unit based on key
      if (RegExp(r'^\d+$').hasMatch(s)) {
        if (key.contains('time') || key.contains('min')) return '$s min';
        if (key.contains('boost') || key.contains('percent')) return '$s%';
        return s;
      }
      return s;
    }

    // Format incident type: POWER_OUTAGE → Power Outage
    String fmtType(String t) {
      return t.replaceAll('_', ' ').split(' ').map((w) {
        return w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : w;
      }).join(' ');
    }

    final beforeState = humanize(
      impact['before_state']?.toString(),
      'Baseline: High impact without intervention',
    );
    final afterState = humanize(
      impact['after_state']?.toString(),
      'Predicted Result: Managed impact and restored flow',
    );
    final improvement = impact['improvement_metrics'] ?? {};

    IconData getCrisisIcon(String type) {
      switch (type.toLowerCase().replaceAll('_', ' ')) {
        case 'flood':         return LucideIcons.waves;
        case 'heatwave':      return LucideIcons.thermometerSun;
        case 'accident':      return LucideIcons.car;
        case 'power outage':  return LucideIcons.zap;
        case 'fire':          return LucideIcons.flame;
        case 'protest':       return LucideIcons.megaphone;
        case 'disease':       return LucideIcons.activity;
        default:              return LucideIcons.alertTriangle;
      }
    }

    final timeStr =
        '${sim.timestamp.day} ${_getMonthName(sim.timestamp.month)} ${sim.timestamp.hour.toString().padLeft(2, '0')}:${sim.timestamp.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Incident details header card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isLatest
                      ? AppColors.accent.withOpacity(0.1)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  getCrisisIcon(incident.type),
                  color: isLatest ? AppColors.accent : AppColors.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type + badge on same row — badge shrinks, type gets remaining space
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            fmtType(incident.type).toUpperCase(),
                            style: AppTextStyles.h2.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isLatest
                                ? AppColors.successGreen
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isLatest ? 'LATEST' : 'PREV',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            incident.location.name,
                            style: AppTextStyles.bodyMuted.copyWith(
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeStr,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sim.id.length >= 5 ? '#${sim.id.substring(0, 5)}' : '#${sim.id}',
                    style: AppTextStyles.label.copyWith(
                      fontSize: 9,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Before Intervention Card
        Card(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: const Border(
                left: BorderSide(color: AppColors.dangerRed, width: 4),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BEFORE INTERVENTION',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.dangerRed,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBulletItem(
                  iconColor: AppColors.dangerRed,
                  title: 'Current Baseline',
                  description: beforeState,
                ),
              ],
            ),
          ),
        ),

        // Divider / AI Actions Taken
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Divider(color: Colors.grey.shade300, thickness: 1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.cpu,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI ACTIONS TAKEN',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Divider(color: Colors.grey.shade300, thickness: 1),
              ),
            ],
          ),
        ),

        // Actions details list
        Card(
          color: Colors.white,
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActionItem(LucideIcons.gitCommit, sim.actionType),
                const SizedBox(height: 8),
                Text(
                  sim.description,
                  style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                ),
                if (sim.stakeholderNotifications.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Notifications Generated:',
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...sim.stakeholderNotifications.entries
                      .where((e) => e.value.isNotEmpty)
                      .map(
                        (e) {
                          // Choose icon per notification type
                          IconData notifIcon;
                          Color notifColor;
                          switch (e.key.toLowerCase()) {
                            case 'public':
                              notifIcon = LucideIcons.megaphone;
                              notifColor = AppColors.accent;
                              break;
                            case 'hospitals':
                              notifIcon = LucideIcons.crosshair;
                              notifColor = AppColors.dangerRed;
                              break;
                            case 'law_enforcement':
                            case 'police':
                              notifIcon = LucideIcons.shield;
                              notifColor = const Color(0xFF3B82F6); // blue
                              break;
                            case 'utility_providers':
                              notifIcon = LucideIcons.zap;
                              notifColor = AppColors.severityMedium;
                              break;
                            default:
                              notifIcon = LucideIcons.send;
                              notifColor = AppColors.accent;
                          }
                          // Clean label: underscores → spaces, title case
                          final label = e.key
                              .replaceAll('_', ' ')
                              .split(' ')
                              .map((w) => w.isNotEmpty
                                  ? '${w[0].toUpperCase()}${w.substring(1)}'
                                  : w)
                              .join(' ');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(notifIcon, size: 14, color: notifColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: AppTextStyles.body.copyWith(fontSize: 12),
                                      children: [
                                        TextSpan(
                                          text: '$label: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: notifColor,
                                          ),
                                        ),
                                        TextSpan(
                                          text: e.value,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
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
                      )
                      .toList(),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Simulated Outcome Card
        Card(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: const Border(
                left: BorderSide(color: AppColors.successGreen, width: 4),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIMULATED OUTCOME',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBulletItem(
                  iconColor: AppColors.successGreen,
                  title: 'Predicted Result',
                  description: afterState,
                  isSuccess: true,
                ),
                if (improvement.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    'Metrics Improvement:',
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: (improvement as Map).entries.map<Widget>((e) {
                      // Clean up key: snake_case → Title Case
                      final label = e.key.toString()
                          .replaceAll('_', ' ')
                          .split(' ')
                          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
                          .join(' ');
                      final value = fmtMetric(e.key.toString(), e.value);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.trendingDown,
                              size: 14,
                              color: AppColors.successGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$label: $value',
                              style: AppTextStyles.label.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTabPill(String title) {
    final isSelected = _selectedCategory == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
          ],
        ),
        child: Text(
          title,
          style: AppTextStyles.label.copyWith(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBulletItem({
    required Color iconColor,
    required String title,
    required String description,
    bool isSuccess = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isSuccess ? LucideIcons.checkCircle : LucideIcons.xCircle,
          color: iconColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.h2.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String text) {
    return Row(
      children: [
        const Icon(LucideIcons.checkCircle, color: AppColors.accent, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
