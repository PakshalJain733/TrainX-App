// ─── Dashboard API Service ─────────────────────────────────────────────────
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class DashboardService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Fetches /api/v1/student/dashboard
  static Future<Map<String, dynamic>> fetchDashboard() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return {};

      final res = await http.get(
        Uri.parse('${AppConstants.baseUrl}/student/dashboard'),
        headers: _authHeaders(token),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return (body['data'] ?? body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  /// Fetches /api/v1/student/profile
  static Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return {};

      final res = await http.get(
        Uri.parse('${AppConstants.baseUrl}/student/profile'),
        headers: _authHeaders(token),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return (body['data'] ?? body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  /// Fetches /api/v1/batches/my-batches
  static Future<int> fetchMyBatchCount() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return 0;

      final res = await http.get(
        Uri.parse('${AppConstants.baseUrl}/batches/my-batches'),
        headers: _authHeaders(token),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'];
        if (data is List) return data.length;
      }
    } catch (_) {}
    return 0;
  }

  /// Fetches leaderboard /api/v1/leaderboard
  static Future<List<Map<String, dynamic>>> fetchLeaderboard(String studentId) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return [];

      final res = await http.get(
        Uri.parse('${AppConstants.baseUrl}/leaderboard'),
        headers: _authHeaders(token),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'];
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Join a batch by code
  static Future<Map<String, dynamic>> joinBatch(String code) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final res = await http.post(
        Uri.parse('${AppConstants.baseUrl}/batches/join'),
        headers: _authHeaders(token),
        body: jsonEncode({'join_code': code, 'joinCode': code, 'code': code}),
      );

      final body = jsonDecode(res.body);
      return {
        'success': body['success'] == true || res.statusCode == 200,
        'message': body['message'] ?? 'Done',
      };
    } catch (_) {
      return {'success': false, 'message': 'Connection error. Please try again.'};
    }
  }
}
