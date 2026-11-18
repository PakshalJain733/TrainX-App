import 'api_client.dart';

class InterviewService {
  // GET /api/v1/interviews/history
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final res = await ApiClient.get('/interviews/history');
    if (res['success'] == true && res['data'] is List) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // GET /api/v1/interviews/:id
  static Future<Map<String, dynamic>> getInterview(int id) async {
    final res = await ApiClient.get('/interviews/$id');
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return res['data'];
    }
    return res;
  }

  // POST /api/v1/interviews
  static Future<Map<String, dynamic>> createInterview({
    required String role,
    required List<String> topics,
    String? experienceLevel,
  }) async {
    final payload = <String, dynamic>{
      'role': role,
      'topics': topics,
    };
    if (experienceLevel != null) {
      payload['experience_level'] = experienceLevel;
    }
    return await ApiClient.post('/interviews', payload);
  }
}
