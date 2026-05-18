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

  @override
  void initState() {
    super.initState();
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
    if (snapshot.connectionState == ConnectionState.waiting) {
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

    final logs = snapshot.data ?? [];

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
            color: AppColors.accent.withOpacity(0.2),
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
                                  color: AppColors.accent.withOpacity(0.2),
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
                    child: Card(
                      margin: EdgeInsets.zero,
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
                                            color: AppColors.primary.withOpacity(0.8),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.12),
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
                            
                            // Technical details hidden by default (only show if data exists and for debugging)
                            if (log.inputData.isNotEmpty || log.outputData.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  'Technical trace data recorded.',
                                  style: AppTextStyles.bodyMuted.copyWith(fontSize: 10, fontStyle: FontStyle.italic),
                                ),
                              ),
                          ],
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
