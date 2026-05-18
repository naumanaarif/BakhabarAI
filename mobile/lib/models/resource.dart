class Resource {
  final String id;
  final String name;
  final String type;
  final String status;
  final String? currentIncidentId;

  Resource({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.currentIncidentId,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      currentIncidentId: json['current_incident_id'] as String?,
    );
  }
}
