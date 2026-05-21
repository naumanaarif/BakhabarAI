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
    // Safe string helper — Maps/Lists from LLM output never crash display
    String safeStr(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      if (v is List) return v.join(', ');
      if (v is Map) return v.values.map((e) => e is List ? e.join(', ') : e.toString()).join(' | ');
      return v.toString();
    }

    final rawImpact = json['impact_prediction'] ?? json['impact'] ?? {};
    final impactMap = rawImpact is Map ? rawImpact : {};
    final improvement = impactMap['improvement_metrics'];

    final rawNotif = json['stakeholder_notifications'] ?? json['notifications'] ?? {};
    final notifMap = rawNotif is Map ? rawNotif : {};

    return ActionSimulation(
      id: safeStr(json['id']),
      incidentId: safeStr(json['incident_id']),
      actionType: safeStr(json['action_type']),
      description: safeStr(json['description']),
      impactPrediction: {
        'before_state': safeStr(impactMap['before_state']),
        'after_state': safeStr(impactMap['after_state']),
        'improvement_metrics': improvement is Map
            ? Map<String, String>.fromEntries(
                improvement.entries.map((e) => MapEntry(e.key.toString(), safeStr(e.value))),
              )
            : <String, String>{},
      },
      stakeholderNotifications: Map<String, String>.fromEntries(
        notifMap.entries.map((e) => MapEntry(e.key.toString(), safeStr(e.value))),
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
