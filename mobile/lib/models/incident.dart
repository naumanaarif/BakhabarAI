class Location {
  final String name;
  final double lat;
  final double lng;

  Location({required this.name, required this.lat, required this.lng});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}

class Incident {
  final String id;
  final String type;
  final Location location;
  final String severity;
  final double confidence;
  final int affectedPopulation;
  final String status;
  final DateTime? timestamp;
  // Detail fields
  final int? expectedDurationHours;
  final String? peakImpactTime;
  final List<String>? signalSources;
  final String? mediaUrl;

  Incident({
    required this.id,
    required this.type,
    required this.location,
    required this.severity,
    required this.confidence,
    required this.affectedPopulation,
    required this.status,
    this.timestamp,
    this.expectedDurationHours,
    this.peakImpactTime,
    this.signalSources,
    this.mediaUrl,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['crisis_id'] as String,
      type: json['type'] as String,
      location: Location.fromJson(json['location']),
      severity: json['severity'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      affectedPopulation: (json['affected_population'] as num?)?.toInt() ?? 0,
      status: json['status'] as String,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      // Firestore returns numbers as num (double) — always use toInt()
      expectedDurationHours: (json['expected_duration_hours'] as num?)?.toInt(),
      peakImpactTime: json['peak_impact_time'] as String?,
      signalSources: json['signal_sources'] != null 
          ? List<String>.from(json['signal_sources'])
          : null,
      mediaUrl: json['media_url'] as String?,
    );
  }
}
