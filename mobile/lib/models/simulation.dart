class ActionSimulation {
  final String id;
  final String incidentId;
  final String actionType;
  final String description;
  final Map<String, dynamic> impactPrediction;
  final Map<String, String> stakeholderNotifications;
  final DateTime timestamp;

  ActionSimulation({
    required this.id,
    required this.incidentId,
    required this.actionType,
    required this.description,
    required this.impactPrediction,
    required this.stakeholderNotifications,
    required this.timestamp,
  });

  factory ActionSimulation.fromJson(Map<String, dynamic> json) {
    return ActionSimulation(
      id: json['id'] as String,
      incidentId: json['incident_id'] as String,
      actionType: json['action_type'] as String,
      description: json['description'] as String,
      impactPrediction: Map<String, dynamic>.from(json['impact_prediction'] ?? {}),
      stakeholderNotifications: Map<String, String>.from(json['stakeholder_notifications'] ?? {}),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'].toString()) 
          : DateTime.now(),
    );
  }
}
