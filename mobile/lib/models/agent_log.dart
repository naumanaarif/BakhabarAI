class AgentTrace {
  final String id;
  final String agentName;
  final String action;
  final Map<String, dynamic> inputData;
  final Map<String, dynamic> outputData;
  final double confidence;
  final DateTime timestamp;

  AgentTrace({
    required this.id,
    required this.agentName,
    required this.action,
    required this.inputData,
    required this.outputData,
    required this.confidence,
    required this.timestamp,
  });

  factory AgentTrace.fromJson(Map<String, dynamic> json) {
    return AgentTrace(
      id: json['id'] ?? '',
      agentName: json['agent_name'] ?? 'Unknown Agent',
      action: json['action'] ?? '',
      inputData: json['input_data'] ?? {},
      outputData: json['output_data'] ?? {},
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
