import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/incident.dart';
import '../models/agent_log.dart';
import '../models/resource.dart';
import '../models/simulation.dart';

class ApiService {
  late final Dio _dio;
  late final FirebaseFirestore _firestore;

  // ── Backend URL configuration ────────────────────────────────────────────
  // PRODUCTION:  Cloud Run (default — works for APK on any network)
  static const String _cloudRunUrl =
      'https://bakhabarai-backend-654186953716.us-central1.run.app/api';

  // LOCAL DEV:   Your machine's IP on local WiFi (emulator uses 10.0.2.2)
  // Change this to your current LAN IP when testing locally
  static const String _localUrl = 'http://192.168.0.241:8000/api';

  // Toggle: set to true to hit local backend, false for Cloud Run.
  // Or pass --dart-define=USE_LOCAL=true when running flutter.
  static const bool _useLocal =
      bool.fromEnvironment('USE_LOCAL', defaultValue: false);

  static const String baseUrl = _useLocal ? _localUrl : _cloudRunUrl;
  // ─────────────────────────────────────────────────────────────────────────


  ApiService() {
    _firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'bakhabarai-db',
    );
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 180),
      receiveTimeout: const Duration(seconds: 180),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add logging interceptor for debugging in development
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
      ));
    }
  }

  // Helper to map Firestore doc to Incident model — fully defensive
  Map<String, dynamic>? _mapFirestoreToIncidentJson(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      // Location: Firestore stores as GeoPoint — handle null or wrong type
      double lat = 33.6844, lng = 73.0479; // fallback: Islamabad
      final rawGeo = data['location'];
      if (rawGeo is GeoPoint) {
        lat = rawGeo.latitude;
        lng = rawGeo.longitude;
      }

      final prediction = data['evolution_prediction'] is Map
          ? data['evolution_prediction'] as Map<String, dynamic>
          : null;

      // peak_time key: detector writes 'peak_time' inside evolution_prediction
      // but some LLM paths write 'peak_impact_time' — check both
      final peakTime = prediction?['peak_impact_time']
          ?? prediction?['peak_time']
          ?? data['peak_impact_time'];

      return {
        'crisis_id': doc.id,
        'type': data['type'] ?? 'unknown',
        'severity': data['severity'] ?? 'LOW',
        'confidence': (data['confidence_score'] as num?)?.toDouble() ?? 0.0,
        'status': data['status'] ?? 'active',
        'affected_population': (data['affected_population'] as num?)?.toInt() ?? 0,
        'timestamp': data['timestamp'] is Timestamp
            ? (data['timestamp'] as Timestamp).toDate().toIso8601String()
            : data['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
        'location': {
          'name': data['location_name'] ?? 'Unknown Location',
          'lat': lat,
          'lng': lng,
        },
        // expected_duration_hours is at root (set by DetectorAgent)
        'expected_duration_hours': (data['expected_duration_hours'] as num?)?.toInt()
            ?? (prediction?['duration_hours'] as num?)?.toInt(),
        'peak_impact_time': peakTime,
        'title': data['title'] ?? '',
        'signal_sources': data['signal_sources'] is List
            ? (data['signal_sources'] as List)
                .whereType<String>()
                .toList()
            : [],
        // media_url: guard against non-String values from Firestore
        'media_url': data['media_url'] is String ? data['media_url'] as String : null,
      };
    } catch (e) {
      debugPrint('Error mapping incident ${doc.id}: $e');
      return null;
    }
  }

  // REAL-TIME INCIDENTS STREAM (Active Only)
  Stream<List<Incident>> getIncidentsStream() {
    return _firestore
        .collection('incidents')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => _mapFirestoreToIncidentJson(doc))
          .whereType<Map<String, dynamic>>()
          .map((json) {
            try {
              return Incident.fromJson(json);
            } catch (e) {
              debugPrint('Incident.fromJson error: $e | json: $json');
              return null;
            }
          })
          .whereType<Incident>()
          .toList();

      list.sort((a, b) {
        if (a.timestamp == null) return 1;
        if (b.timestamp == null) return -1;
        return b.timestamp!.compareTo(a.timestamp!);
      });
      return list;
    }).handleError((e) {
      debugPrint('getIncidentsStream error: $e');
      return <Incident>[];
    });
  }

  // REAL-TIME INCIDENT HISTORY STREAM (All incidents)
  Stream<List<Incident>> getIncidentHistoryStream() {
    return _firestore
        .collection('incidents')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => _mapFirestoreToIncidentJson(doc))
          .whereType<Map<String, dynamic>>()
          .map((json) => Incident.fromJson(json))
          .toList();
    });
  }

  // REAL-TIME SINGLE INCIDENT STREAM
  Stream<Incident?> getIncidentStream(String id) {
    return _firestore
        .collection('incidents')
        .doc(id)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final json = _mapFirestoreToIncidentJson(doc);
      if (json == null) return null;
      return Incident.fromJson(json);
    });
  }

  // REAL-TIME AGENT LOGS STREAM
  Stream<List<AgentTrace>> getAgentLogsStream() {
    return _firestore
        .collection('agent_logs')
        .snapshots()
        .map((snapshot) {
      try {
        final list = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          if (data['timestamp'] is Timestamp) {
            data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
          } else if (data['timestamp'] == null) {
            data['timestamp'] = DateTime.now().toIso8601String();
          }
          return AgentTrace.fromJson(data);
        }).toList();

        // Sort in memory: Latest first
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return list;
      } catch (e) {
        debugPrint('Error parsing agent logs: $e');
        return <AgentTrace>[];
      }
    });
  }

  // REAL-TIME RESOURCES STREAM
  Stream<List<Resource>> getResourcesStream() {
    return _firestore
        .collection('resources')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Resource.fromJson(data);
      }).toList();
    });
  }

  // REAL-TIME SIMULATIONS STREAM
  Stream<List<ActionSimulation>> getSimulationsStream() {
    return _firestore
        .collection('action_simulations')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;

          // Fix timestamp
          if (data['timestamp'] is Timestamp) {
            data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
          } else {
            data['timestamp'] ??= DateTime.now().toIso8601String();
          }

          // Firestore uses 'impact' but model expects 'impact_prediction'
          // Also flatten any nested maps/lists to strings defensively
          final rawImpact = data['impact'] ?? data['impact_prediction'] ?? {};
          String safeStr(dynamic v) {
            if (v == null) return '';
            if (v is String) return v;
            if (v is List) return v.join(', ');
            if (v is Map) return v.values.map((e) => e is List ? e.join(', ') : e.toString()).join(' | ');
            return v.toString();
          }
          final impactMap = rawImpact is Map ? rawImpact : {};
          final improvement = impactMap['improvement_metrics'];
          data['impact_prediction'] = {
            'before_state': safeStr(impactMap['before_state']),
            'after_state': safeStr(impactMap['after_state']),
            'improvement_metrics': improvement is Map
                ? Map<String, String>.fromEntries(
                    improvement.entries.map((e) => MapEntry(e.key.toString(), safeStr(e.value))),
                  )
                : <String, String>{},
          };

          // Firestore uses 'notifications' but model expects 'stakeholder_notifications'
          final rawNotif = data['notifications'] ?? data['stakeholder_notifications'];
          if (rawNotif is Map) {
            data['stakeholder_notifications'] = Map<String, String>.fromEntries(
              rawNotif.entries.map((e) => MapEntry(e.key.toString(), safeStr(e.value))),
            );
          } else {
            data['stakeholder_notifications'] = <String, String>{};
          }

          return ActionSimulation.fromJson(data);
        } catch (e) {
          debugPrint('Error parsing simulation ${doc.id}: $e');
          return ActionSimulation(
            id: doc.id,
            incidentId: '',
            actionType: 'Unknown',
            description: 'Data parse error',
            impactPrediction: const {},
            stakeholderNotifications: const {},
            timestamp: DateTime.now(),
          );
        }
      }).where((s) => s.incidentId.isNotEmpty).toList();
    });
  }

  Future<void> submitReport(String message, {double? lat, double? lng, String? mediaUrl}) async {
    try {
      // Note: Endpoint is baseUrl + '/report' -> /api/report
      final data = {
        'message': message,
        'lat': lat ?? 33.6844,
        'lng': lng ?? 73.0479,
      };
      if (mediaUrl != null) {
        data['media_url'] = mediaUrl;
      }
      await _dio.post('/report', data: data);
    } on DioException catch (e) {
      debugPrint('Error submitting report: ${e.message}');
      throw Exception('Failed to submit report: ${e.response?.data['message'] ?? e.message}');
    } catch (e) {
      debugPrint('Unexpected error submitting report: $e');
      throw Exception('An unexpected error occurred.');
    }
  }

  Future<Map<String, dynamic>> runScenario(Map<String, dynamic> scenario) async {
    try {
      // Note: Endpoint is baseUrl + '/run-scenario' -> /api/run-scenario
      final response = await _dio.post('/run-scenario', data: scenario);
      return response.data;
    } on DioException catch (e) {
      debugPrint('Error running scenario: ${e.message}');
      throw Exception('Failed to run agent simulation: ${e.response?.data['message'] ?? e.message}');
    } catch (e) {
      debugPrint('Unexpected error running scenario: $e');
      throw Exception('An unexpected error occurred during simulation.');
    }
  }

  Future<List<String>> getPlacePredictions(String query) async {
    try {
      final response = await _dio.get('/places/autocomplete', queryParameters: {'q': query});
      if (response.data != null && response.data['predictions'] != null) {
        final predictions = response.data['predictions'] as List;
        return predictions.map((p) => p['description'] as String).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching places: $e');
      return [];
    }
  }
}
