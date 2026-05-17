import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import 'agent_logs_screen.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({Key? key}) : super(key: key);

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  int _selectedTab = 0; // 0: Flood, 1: Heatwave, 2: Alerts

  @override
  Widget build(BuildContext context) {
    final String before1Title = _selectedTab == 0 ? 'Traffic Blockage' : _selectedTab == 1 ? 'Power Overload' : 'Conflicting Signals';
    final String before1Desc = _selectedTab == 0 ? 'Severe congestion reported on Main Blvd due to rising water levels. Vehicles stranded.' : _selectedTab == 1 ? 'Hospital auxiliary power running out.' : 'Unverified social media panic over false alert.';
    final String before2Title = _selectedTab == 0 ? 'Rescue Not Dispatched' : _selectedTab == 1 ? 'Ambulances Stalled' : 'Wasted Resources';
    final String before2Desc = _selectedTab == 0 ? 'Emergency teams stalled in sector G. 0/3 units available for immediate deployment.' : _selectedTab == 1 ? 'Heat stroke victims unassisted.' : 'Units assigned to false emergency.';

    final List<String> actions = _selectedTab == 0
        ? ['Traffic rerouted via Northern Bypass', '2 specialized aquatic rescue teams dispatched', 'Automated SMS alerts sent to 4,500 residents']
        : _selectedTab == 1
            ? ['Backup generators redirected to F-8 clinic', 'Mobile cooling stations deployed', 'Grid load-shedding adjusted']
            : ['Field verification team requested', 'Social media retraction posted', 'Units returned to pool'];

    final String after1Title = _selectedTab == 0 ? 'Congestion Reduced 60%' : _selectedTab == 1 ? 'Power Restored' : 'Panic Avoided';
    final String after1Desc = _selectedTab == 0 ? 'Flow restored to 40km/h on alternate routes. Main Blvd clearing expected in 45m.' : _selectedTab == 1 ? 'Critical sectors energized.' : 'Public informed of false alarm.';
    final String after2Title = _selectedTab == 0 ? 'ETA Rescue 4m' : _selectedTab == 1 ? 'Patients Treated' : 'Resources Freed';
    final String after2Desc = _selectedTab == 0 ? 'Units responding to Sector G priority calls. Estimated time of arrival significantly improved.' : _selectedTab == 1 ? 'Over 50 heatstroke victims cooled.' : 'Units available for actual emergencies.';

    final String confidence = _selectedTab == 0 ? '92%' : _selectedTab == 1 ? '88%' : '99%';
    final double confidenceVal = _selectedTab == 0 ? 0.92 : _selectedTab == 1 ? 0.88 : 0.99;

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
                'Simulation Outcomes',
                style: AppTextStyles.h1.copyWith(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 16),

              // Tab pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabPill(0, 'Flood'),
                    _buildTabPill(1, 'Heatwave'),
                    _buildTabPill(2, 'Alerts'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
                      left: BorderSide(
                        color: AppColors.dangerRed,
                        width: 4,
                      ),
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
                        title: before1Title,
                        description: before1Desc,
                      ),
                      const Divider(height: 24),
                      _buildBulletItem(
                        iconColor: AppColors.dangerRed,
                        title: before2Title,
                        description: before2Desc,
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
                    Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.cpu, color: AppColors.textMuted, size: 16),
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
                    Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
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
                    children: [
                      ...actions.map((action) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildActionItem(LucideIcons.gitCommit, action),
                      )).toList(),
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
                      left: BorderSide(
                        color: AppColors.successGreen,
                        width: 4,
                      ),
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
                        title: after1Title,
                        description: after1Desc,
                        isSuccess: true,
                      ),
                      const Divider(height: 24),
                      _buildBulletItem(
                        iconColor: AppColors.successGreen,
                        title: after2Title,
                        description: after2Desc,
                        isSuccess: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // AI Confidence widget
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
                        'AI Confidence',
                        style: AppTextStyles.h2.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            confidence,
                            style: AppTextStyles.h1.copyWith(
                              fontSize: 36,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Success Prob.',
                              style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: confidenceVal,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Based on historical flood data from 2022 and current infrastructural constraints.',
                        style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Decision Matrix / View Logs
              Card(
                color: AppColors.primary.withOpacity(0.3),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.cpu, size: 36, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'Decision Matrix',
                        style: AppTextStyles.h2.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Review the step-by-step logic and environmental parameters the AI evaluated.',
                        style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AgentLogsScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.accent, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'View Agent Logs',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Execute Plan Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Simulation Action plan executed successfully.'),
                        backgroundColor: AppColors.successGreen,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Execute Plan'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabPill(int index, String title) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
            )
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
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
