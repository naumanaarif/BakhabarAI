import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/incident.dart';
import '../models/agent_log.dart';

class ApiService {
  late final Dio _dio;
  
  // Use 10.0.2.2 for Android emulator to access localhost, or IP for physical device.
  // We use a simple fallback mechanism.
  static const String baseUrl = 'http://127.0.0.1:8000/api'; 

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
  }

  Future<List<Incident>> getIncidents() async {
    try {
      final response = await _dio.get('/incidents');
      final List<dynamic> data = response.data['incidents'];
      return data.map((json) => Incident.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching incidents: $e');
      // For development, if backend is down, we return an empty list or throw
      throw Exception('Failed to load incidents. Is the backend running?');
    }
  }

  Future<Incident> getIncidentDetail(String id) async {
    try {
      final response = await _dio.get('/incidents/$id');
      return Incident.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching incident detail: $e');
      throw Exception('Failed to load incident detail.');
    }
  }

  Future<void> submitReport(String message) async {
    try {
      // Send the report message to our mock backend
      await _dio.post('/report', data: {'message': message});
    } catch (e) {
      debugPrint('Error submitting report: $e');
      throw Exception('Failed to submit report. Please try again.');
    }
  }

  Future<List<AgentTrace>> getAgentLogs() async {
    try {
      final response = await _dio.get('/logs');
      if (response.data != null && response.data['traces'] != null) {
        final List<dynamic> data = response.data['traces'];
        return data.map((json) => AgentTrace.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching agent logs: $e');
      throw Exception('Failed to load agent logs.');
    }
  }

  Future<Map<String, dynamic>> runScenario(Map<String, dynamic> scenario) async {
    try {
      final response = await _dio.post('/run-scenario', data: scenario);
      return response.data;
    } catch (e) {
      debugPrint('Error running scenario: $e');
      throw Exception('Failed to run agent simulation.');
    }
  }
}
