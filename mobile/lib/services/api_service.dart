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
  
  /// Base URL for the FastAPI backend.
  /// Note: Use 10.0.2.2 for Android Emulator, localhost for iOS, or your machine's IP for physical devices.
  static const String baseUrl = 'http://192.168.0.241:8000/api'; 

  ApiService() {
    _firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'bakhabarai-db',
    );
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
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

  // Helper to map Firestore doc to Incident model
  Map<String, dynamic> _mapFirestoreToIncidentJson(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geo = data['location'] as GeoPoint;
    final prediction = data['evolution_prediction'] as Map<String, dynamic>?;

    return {
      'crisis_id': doc.id,
      'type': data['type'] ?? 'unknown',
      'severity': data['severity'] ?? 'LOW',
      'confidence': (data['confidence_score'] ?? 0.0).toDouble(),
      'status': data['status'] ?? 'active',
      'affected_population': data['affected_population'] ?? 0,
      'location': {
        'name': data['location_name'] ?? 'Unknown Location',
        'lat': geo.latitude,
        'lng': geo.longitude,
      },
      'expected_duration_hours': prediction?['expected_duration_hours'],
      'peak_impact_time': prediction?['peak_impact_time'],
      'signal_sources': data['signal_sources'] is List 
          ? List<String>.from(data['signal_sources']) 
          : [],
    };
  }

  // REAL-TIME INCIDENTS STREAM
  Stream<List<Incident>> getIncidentsStream() {
    return _firestore
        .collection('incidents')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Incident.fromJson(_mapFirestoreToIncidentJson(doc));
      }).toList();
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
      return Incident.fromJson(_mapFirestoreToIncidentJson(doc));
    });
  }

  // REAL-TIME AGENT LOGS STREAM
  Stream<List<AgentTrace>> getAgentLogsStream() {
    return _firestore
        .collection('agent_logs')
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          if (data['timestamp'] is Timestamp) {
            data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
          } else if (data['timestamp'] == null) {
            data['timestamp'] = DateTime.now().toIso8601String();
          }
          return AgentTrace.fromJson(data);
        }).toList();
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
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
        }
        if (data['stakeholder_notifications'] != null) {
          data['stakeholder_notifications'] = Map<String, String>.from(
            (data['stakeholder_notifications'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()))
          );
        }
        return ActionSimulation.fromJson(data);
      }).toList();
    });
  }

  Future<void> submitReport(String message, {double? lat, double? lng}) async {
    try {
      // Note: Endpoint is baseUrl + '/report' -> /api/report
      await _dio.post('/report', data: {
        'message': message,
        'lat': lat ?? 33.6844,
        'lng': lng ?? 73.0479,
      });
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
}
