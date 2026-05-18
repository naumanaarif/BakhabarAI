import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import '../models/incident.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_loader.dart';
import 'incident_detail_screen.dart';
import 'resource_allocation_screen.dart';
import 'simulation_screen.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({Key? key}) : super(key: key);

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  final ApiService _apiService = ApiService();
  late Stream<List<Incident>> _incidentsStream;

  @override
  void initState() {
    super.initState();
    _incidentsStream = _apiService.getIncidentsStream();
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL':
        return AppColors.severityHigh;
      case 'MEDIUM':
      case 'ELEVATED':
        return AppColors.severityMedium;
      case 'LOW':
      case 'ROUTINE':
      default:
        return AppColors.severityLow;
    }
  }

  Color _getSeverityBgColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL':
        return AppColors.severityHigh.withOpacity(0.12);
      case 'MEDIUM':
      case 'ELEVATED':
        return AppColors.severityMedium.withOpacity(0.12);
      case 'LOW':
      case 'ROUTINE':
      default:
        return AppColors.severityLow.withOpacity(0.12);
    }
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
      ),
      body: StreamBuilder<List<Incident>>(
        stream: _incidentsStream,
        builder: (context, snapshot) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Active Incidents',
                    style: AppTextStyles.h1.copyWith(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
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
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Show Simulations'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ResourceAllocationScreen(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Colors.grey, width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Resource Allocation',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Incidents Content
                  _buildIncidentsContent(snapshot),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIncidentsContent(AsyncSnapshot<List<Incident>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Column(
        children: List.generate(3, (index) => const IncidentCardSkeleton()),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.dangerRed),
              const SizedBox(height: 16),
              Text('Failed to load incidents', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(snapshot.error.toString(), style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final incidents = snapshot.data ?? [];

    if (incidents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.checkCircle, size: 48, color: AppColors.successGreen),
              const SizedBox(height: 16),
              Text('All Clear', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text('No active crises in your area.', style: AppTextStyles.bodyMuted),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: incidents.length,
      itemBuilder: (context, index) {
        final incident = incidents[index];
        final isHigh = incident.severity.toUpperCase() == 'HIGH' || incident.severity.toUpperCase() == 'CRITICAL';
        final severityColor = _getSeverityColor(incident.severity);
        final confidencePercent = (incident.confidence * 100).toInt();

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => IncidentDetailScreen(incidentId: incident.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(
                    color: severityColor,
                    width: 4,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Badge row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${incident.location.name.split(',')[0]} ${incident.type.toUpperCase()}',
                          style: AppTextStyles.h2.copyWith(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSeverityBgColor(incident.severity),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          incident.severity,
                          style: AppTextStyles.label.copyWith(
                            color: severityColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Location and Time row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.mapPin, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              incident.location.name,
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Live',
                        style: AppTextStyles.bodyMuted.copyWith(
                          fontSize: 12,
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Confidence progress bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'AI Confidence',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$confidencePercent%',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: incident.confidence,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isHigh ? AppColors.accent : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
