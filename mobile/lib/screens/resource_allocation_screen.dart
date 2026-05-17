import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import 'simulation_screen.dart';

class ResourceAllocationScreen extends StatelessWidget {
  const ResourceAllocationScreen({Key? key}) : super(key: key);

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
      body: SingleChildScrollView(
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
              Card(
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
                        title: 'Ambulance',
                        count: '12 / 45',
                        progress: 0.26,
                        color: AppColors.accent,
                      ),
                      const SizedBox(height: 16),

                      // Police
                      _buildResourcePoolRow(
                        icon: LucideIcons.shield,
                        title: 'Police',
                        count: '84 / 120',
                        progress: 0.70,
                        color: AppColors.accent.withOpacity(0.8),
                      ),
                      const SizedBox(height: 16),

                      // Rescue
                      _buildResourcePoolRow(
                        icon: LucideIcons.hardHat,
                        title: 'Rescue',
                        count: '4 / 30',
                        progress: 0.13,
                        color: AppColors.dangerRed,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Trade-off Alert Box
              Container(
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
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
                            const TextSpan(
                              text: 'I-8 response delayed +8 mins due to G-10 flood priority.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Show Simulation Button
              SizedBox(
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
              ),
              const SizedBox(height: 28),

              // Deployment sections
              Text(
                'Active Deployments',
                style: AppTextStyles.h2.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 12),

              // Incident Deployment 1: G-10 FLOOD
              _buildDeploymentCard(
                title: 'G-10 FLOOD',
                priority: 'Priority: HIGH',
                priorityColor: AppColors.dangerRed,
                description: 'Massive water accumulation in sectors G-10/4 and G-10/1. Continuous monitoring required as weather models predict further rainfall.',
                resources: [
                  _buildResourceListItem(LucideIcons.activity, '5 Ambulances deployed to safe staging areas.', AppColors.accent),
                  _buildResourceListItem(LucideIcons.shield, '12 Units securing perimeter and managing traffic.', AppColors.accent.withOpacity(0.8)),
                  _buildResourceListItem(LucideIcons.hardHat, '3 Rescue boats en route to deepest sectors.', AppColors.dangerRed),
                ],
              ),
              const SizedBox(height: 16),

              // Incident Deployment 2: F-8 POWER GRID FAILURE
              _buildDeploymentCard(
                title: 'F-8 POWER GRID FAILURE',
                priority: 'Priority: MODERATE',
                priorityColor: AppColors.severityMedium,
                description: 'Localized blackout affecting commercial zones. Auxiliary power units currently sustaining hospital operations.',
                resources: [
                  _buildResourceListItem(LucideIcons.cpu, '2 Engineering crews dispatched for diagnostics.', AppColors.textMuted),
                  _buildResourceListItem(LucideIcons.shield, '4 Units providing localized security details.', AppColors.accent.withOpacity(0.8)),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
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

  Widget _buildDeploymentCard({
    required String title,
    required String priority,
    required Color priorityColor,
    required String description,
    required List<Widget> resources,
  }) {
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
                    title,
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
                    priority,
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
              description,
              style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Resources list
            Container(
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
                  ...resources,
                ],
              ),
            ),
          ],
        ),
      ),
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
