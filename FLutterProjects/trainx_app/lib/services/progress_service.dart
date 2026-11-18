import 'api_client.dart';

class ProgressService {
  // GET /api/v1/skill-gaps/my-gaps
  static Future<Map<String, dynamic>> getMySkillGaps() async {
    final res = await ApiClient.get('/skill-gaps/my-gaps');
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return res['data'];
    }
    return res;
  }

  // GET /api/v1/student/performance
  static Future<Map<String, dynamic>> getPerformance() async {
    final res = await ApiClient.get('/student/performance');
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return res['data'];
    }
    return res;
  }
}
