import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/incident.dart';
import '../services/api_service.dart';
import 'resource_allocation_screen.dart';
import 'simulation_screen.dart';

class IncidentDetailScreen extends StatefulWidget {
  final String incidentId;

  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  final ApiService _apiService = ApiService();
  late Stream<Incident?> _incidentStream;

  @override
  void initState() {
    super.initState();
    _incidentStream = _apiService.getIncidentStream(widget.incidentId);
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
    return StreamBuilder<Incident?>(
      stream: _incidentStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.primary,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            backgroundColor: AppColors.primary,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.dangerRed),
                    const SizedBox(height: 16),
                    Text('Error loading details', style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    Text(snapshot.error?.toString() ?? 'Incident not found', style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          );
        }

        final incident = snapshot.data!;
        final severityColor = _getSeverityColor(incident.severity);
        final confidencePercent = (incident.confidence * 100).toInt();

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
                      fontSize: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: 'Ai',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
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
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Area
                  Text(
                    '${incident.location.name.split(',')[0]} ${incident.type.toUpperCase()}',
                    style: AppTextStyles.h1.copyWith(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          incident.location.name,
                          style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        TimeUtils.formatFullDateTime(incident.timestamp),
                        style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (incident.mediaUrl != null) ...[
                    // Surveillance Image Card
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            Image.network(
                              incident.mediaUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) => const Center(child: Icon(LucideIcons.image, size: 48, color: AppColors.textMuted)),
                            ),
                            // Play button overlay (optional if it's a video)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withOpacity(0.15),
                                child: Center(
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.85),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                                    ),
                                    child: const Icon(LucideIcons.play, color: AppColors.textPrimary, size: 24),
                                  ),
                                ),
                              ),
                            ),
                            // Live Badge
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerRed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'MEDIA ATTACHED',
                                      style: AppTextStyles.label.copyWith(
                                        color: Colors.white,
                                        fontSize: 9,
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
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Bento Cards
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Severity & Confidence Card
                      Card(
                        margin: EdgeInsets.zero,
                        color: Colors.white,
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.04),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.alertTriangle, color: AppColors.accent, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            incident.type.toUpperCase(),
                                            style: AppTextStyles.label.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getSeverityBgColor(incident.severity),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      incident.severity,
                                      style: AppTextStyles.label.copyWith(
                                        color: severityColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('AI Confidence', style: AppTextStyles.labelMuted.copyWith(fontSize: 12)),
                                  Text('$confidencePercent%', style: AppTextStyles.label.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: incident.confidence,
                                  color: AppColors.accent,
                                  backgroundColor: AppColors.primary,
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Signal Sources Card
                      Card(
                        margin: EdgeInsets.zero,
                        color: Colors.white,
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.04),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Signal Sources',
                                style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Correlated ground data',
                                style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              if (incident.signalSources != null && incident.signalSources!.isNotEmpty)
                                ...incident.signalSources!.toSet().take(3).map((source) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.radio, size: 12, color: AppColors.successGreen),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          source.toUpperCase(),
                                          style: AppTextStyles.label.copyWith(fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList()
                              else
                                Row(
                                  children: [
                                    const Icon(LucideIcons.radio, size: 12, color: AppColors.textMuted),
                                    const SizedBox(width: 8),
                                    Text('Primary Feed Alpha', style: AppTextStyles.label.copyWith(fontSize: 12)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info Rows Card
                  Card(
                    margin: EdgeInsets.zero,
                    color: Colors.white,
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.04),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.users, color: AppColors.textMuted, size: 18),
                                    const SizedBox(width: 12),
                                    Text('Affected Population', style: AppTextStyles.body.copyWith(fontSize: 14)),
                                  ],
                                ),
                                Text(
                                  incident.affectedPopulation > 0 
                                      ? 'Est. ${incident.affectedPopulation}'
                                      : 'Calculating...',
                                  style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Colors.black12),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.clock, color: AppColors.textMuted, size: 18),
                                    const SizedBox(width: 12),
                                    Text('Expected Duration', style: AppTextStyles.body.copyWith(fontSize: 14)),
                                  ],
                                ),
                                Text(
                                  (incident.expectedDurationHours != null && incident.expectedDurationHours! > 0)
                                      ? '${incident.expectedDurationHours} Hours'
                                      : 'Analyzing...',
                                  style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 140), // Space for bottom action bar
                ],
              ),
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              border: const Border(top: BorderSide(color: Colors.black12)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SimulationScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(color: AppColors.accent, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.cpu, size: 16),
                            const SizedBox(width: 6),
                            Text('Simulation', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ResourceAllocationScreen(),
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
                            const Icon(LucideIcons.activity, size: 16),
                            const SizedBox(width: 6),
                            Text('Resources', style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
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
