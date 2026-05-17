import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
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
  bool _isLoading = true;
  String? _error;
  Incident? _incident;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final incident = await _apiService.getIncidentDetail(widget.incidentId);
      if (mounted) {
        setState(() {
          _incident = incident;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
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
    if (_isLoading) {
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

    if (_error != null || _incident == null) {
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
                Text(_error ?? 'Incident not found', style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    final severityColor = _getSeverityColor(_incident!.severity);
    final confidencePercent = (_incident!.confidence * 100).toInt();

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
                '${_incident!.location.name.split(',')[0]} ${_incident!.type.toUpperCase()}',
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
                  Text(_incident!.location.name, style: AppTextStyles.bodyMuted.copyWith(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 20),

              // Surveillance Image Card
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
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
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBRwVlyK9PIjECrBxzOzG774__9ciYxrr6bvTcEuq7qgZATxYjHcVzGGS9QSbOQ3zZfVMWIOBjy9_x_UT5I2aYVlFecVTVQ29rrgEZANkRA4oh8BwBppiFRHWbPxMWrE5q_bPdjHqew4Mo5xI7Gzg8Xfog_QB3dtR8A3I3FXuSpYBajAHNRmX2pBT3Ui2rPiqCR1BlnJ311SMJIfgnImnpyQ0Fd05KouLjRi1fXfaTfZ5hvlCgoDwYrkz3gtYajmBssCYk5-jD6_Dc',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      // Play button overlay
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
                                'LIVE FEED',
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

              // Bento Cards
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Severity & Confidence Card
                  Expanded(
                    child: Card(
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
                                Row(
                                  children: [
                                    const Icon(LucideIcons.alertTriangle, color: AppColors.accent, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      _incident!.type,
                                      style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _getSeverityBgColor(_incident!.severity),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _incident!.severity,
                                    style: AppTextStyles.label.copyWith(
                                      color: severityColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('AI Confidence', style: AppTextStyles.labelMuted.copyWith(fontSize: 11)),
                                Text('$confidencePercent%', style: AppTextStyles.label.copyWith(fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _incident!.confidence,
                                color: AppColors.accent,
                                backgroundColor: AppColors.primary,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Signal Sources Card
                  Expanded(
                    child: Card(
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
                              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Correlated ground data',
                              style: AppTextStyles.bodyMuted.copyWith(fontSize: 11),
                            ),
                            const SizedBox(height: 12),
                            // Source 1
                            Row(
                              children: [
                                const Icon(LucideIcons.radio, size: 12, color: AppColors.successGreen),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Thermal Node 4',
                                    style: AppTextStyles.label.copyWith(fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Source 2
                            Row(
                              children: [
                                const Icon(LucideIcons.shield, size: 12, color: AppColors.successGreen),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Sat-Link Beta',
                                    style: AppTextStyles.label.copyWith(fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
                              'Est. ${_incident!.affectedPopulation}',
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
                              '${_incident!.expectedDurationHours} Hours',
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
  }
}
