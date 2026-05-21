import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import '../models/agent_log.dart';
import '../services/api_service.dart';

class AgentLogsScreen extends StatefulWidget {
  const AgentLogsScreen({super.key});

  @override
  State<AgentLogsScreen> createState() => _AgentLogsScreenState();
}

class _AgentLogsScreenState extends State<AgentLogsScreen> {
  final ApiService _apiService = ApiService();
  late Stream<List<AgentTrace>> _logsStream;
  final Set<String> _expandedLogIds = {};

  @override
  void initState() {
    super.initState();
    _logsStream = _apiService.getAgentLogsStream();
  }

  String _formatValue(dynamic val) {
    if (val == null) return 'None';
    if (val is Map || val is List) {
      try {
        final str = val.toString();
        if (str.length > 250) {
          return '${str.substring(0, 250)}...';
        }
        return str;
      } catch (_) {
        return val.toString();
      }
    }
    return val.toString();
  }

  Widget _buildExpandedDetails(AgentTrace log) {
    final List<Widget> sections = [];

    // Custom Agent Description and Icon based on Agent constitution
    String agentDesc = '';
    IconData agentIcon = LucideIcons.cpu;
    final normalizedAgent = log.agentName.toLowerCase();
    
    if (normalizedAgent.contains('signal') || normalizedAgent.contains('fusion')) {
      agentDesc = 'Gathers signals from weather/traffic APIs and reports to validate initial credibility.';
      agentIcon = LucideIcons.radio;
    } else if (normalizedAgent.contains('detector') || normalizedAgent.contains('crisis')) {
      agentDesc = 'Analyzes signals to classify crisis type, location, severity, and confidence level.';
      agentIcon = LucideIcons.search;
    } else if (normalizedAgent.contains('planner') || normalizedAgent.contains('resource')) {
      agentDesc = 'Allocates emergency response resources and explains optimization trade-offs.';
      agentIcon = LucideIcons.brainCircuit;
    } else if (normalizedAgent.contains('simulation') || normalizedAgent.contains('executor')) {
      agentDesc = 'Simulates evacuation routes, utility dispatches, and public safety alerts.';
      agentIcon = LucideIcons.play;
    } else if (normalizedAgent.contains('reporter') || normalizedAgent.contains('report')) {
      agentDesc = 'Synthesizes simulation results, compares pre/after states, and creates notifications.';
      agentIcon = LucideIcons.scrollText;
    } else if (normalizedAgent.contains('user')) {
      agentDesc = 'Direct incident reporting or query submitted by a citizen.';
      agentIcon = LucideIcons.users;
    } else {
      agentDesc = 'Orchestrates multi-agent logic flow for CIRO incident tracking.';
      agentIcon = LucideIcons.cpu;
    }

    sections.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(agentIcon, size: 16, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agent Role',
                    style: AppTextStyles.label.copyWith(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    agentDesc,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      height: 1.3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Inputs Section
    if (log.inputData.isNotEmpty) {
      sections.add(const SizedBox(height: 12));
      sections.add(
        Text(
          'Inputs Evaluated',
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      );
      sections.add(const SizedBox(height: 4));
      
      log.inputData.forEach((key, val) {
        if (val != null) {
          sections.add(
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textPrimary),
                        children: [
                          TextSpan(text: '$key: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                          TextSpan(text: _formatValue(val)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      });
    }

    // Decisions/Outputs Section
    if (log.outputData.isNotEmpty) {
      sections.add(const SizedBox(height: 12));
      sections.add(
        Text(
          'Decisions & Action Results',
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      );
      sections.add(const SizedBox(height: 4));

      log.outputData.forEach((key, val) {
        if (val != null) {
          sections.add(
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✓ ', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textPrimary),
                        children: [
                          TextSpan(text: '$key: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                          TextSpan(text: _formatValue(val)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: AppColors.textMuted.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          ...sections,
        ],
      ),
    );
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
      body: StreamBuilder<List<AgentTrace>>(
        stream: _logsStream,
        builder: (context, snapshot) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Agent Logs',
                    style: AppTextStyles.h1.copyWith(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Real-time execution trace & reasoning engine output.',
                    style: AppTextStyles.bodyMuted,
                  ),
                  const SizedBox(height: 16),
                  
                  // Stress Test Trigger (Moved from Incidents Screen)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Fire-and-forget: backend returns instantly, pipeline runs in background
                        // User can navigate freely while agents work
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '⚡ Agents activated — pipeline running in background',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            duration: Duration(seconds: 4),
                            backgroundColor: AppColors.textPrimary,
                          ),
                        );
                        try {
                          await _apiService.runScenario({});
                          // Response arrives in ~1 second (202 Accepted)
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '✅ Pipeline launched — check Agent Logs below',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                backgroundColor: AppColors.successGreen,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error: $e',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                backgroundColor: AppColors.dangerRed,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.zap, size: 16, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text(
                            'Run System Stress Test',
                            style: AppTextStyles.label.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Timeline
                  _buildTimelineBody(snapshot),
                  const SizedBox(height: 120), // Space for bottom nav bar
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineBody(AsyncSnapshot<List<AgentTrace>> snapshot) {
    final logs = snapshot.data ?? [];

    if (snapshot.connectionState == ConnectionState.waiting && logs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(LucideIcons.alertTriangle, color: AppColors.dangerRed, size: 40),
              const SizedBox(height: 12),
              Text('Failed to load logs', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(snapshot.error.toString(), style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(LucideIcons.scrollText, color: AppColors.textMuted, size: 40),
              const SizedBox(height: 12),
              Text('No traces available', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text('Run a crisis scenario to view traces.', style: AppTextStyles.bodyMuted),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Continuous line
        Positioned(
          left: 17,
          top: 30,
          bottom: 30,
          child: Container(
            width: 2,
            color: AppColors.accent.withValues(alpha: 0.2),
          ),
        ),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final isFirst = index == 0;
            final confidencePercent = (log.confidence * 100).toInt();
            final isExpanded = _expandedLogIds.contains(log.id);

            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dot Column
                  Container(
                    margin: const EdgeInsets.only(top: 20, right: 16),
                    width: 36,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isFirst)
                            Positioned(
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Card
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedLogIds.remove(log.id);
                          } else {
                            _expandedLogIds.add(log.id);
                          }
                        });
                      },
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: Colors.white,
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: const Border(
                              left: BorderSide(
                                color: AppColors.accent,
                                width: 4,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                                          style: AppTextStyles.label.copyWith(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.8),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              log.agentName,
                                              style: AppTextStyles.label.copyWith(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '$confidencePercent% Conf',
                                          style: AppTextStyles.label.copyWith(
                                            color: AppColors.accent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                        size: 16,
                                        color: AppColors.textMuted,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Log message / details
                              Text(
                                log.action,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              
                              // Inline teaser if collapsed
                              if (!isExpanded && (log.inputData.isNotEmpty || log.outputData.isNotEmpty))
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.info, size: 12, color: AppColors.accent),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Tap to view agent trace details',
                                        style: AppTextStyles.bodyMuted.copyWith(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Expandable trace details
                              if (isExpanded) _buildExpandedDetails(log),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
