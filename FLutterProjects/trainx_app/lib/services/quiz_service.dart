import 'api_client.dart';

class QuizService {
  // GET /api/v1/assessments/available
  static Future<List<Map<String, dynamic>>> getAvailableQuizzes() async {
    final res = await ApiClient.get('/assessments/available');
    if (res['success'] == true && res['data'] is List) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // GET /api/v1/assessments/my-attempts
  static Future<List<Map<String, dynamic>>> getMyAttempts() async {
    final res = await ApiClient.get('/assessments/my-attempts');
    if (res['success'] == true && res['data'] is List) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // GET /api/v1/assessments/:id
  static Future<Map<String, dynamic>> getAssessmentById(dynamic id) async {
    final res = await ApiClient.get('/assessments/$id');
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return res['data'];
    }
    return res;
  }

  // POST /api/v1/assessments/:id/start
  static Future<Map<String, dynamic>> startAssessment(dynamic id) async {
    return await ApiClient.post('/assessments/$id/start', {});
  }

  // POST /api/v1/assessments/:id/submit
  static Future<Map<String, dynamic>> submitAssessment({
    required dynamic id,
    dynamic attemptId,
    required Map<String, dynamic> answers,
  }) async {
    final body = {
      'attemptId': attemptId,
      'answers': answers,
    };
    if (attemptId != null) {
      return await ApiClient.post('/assessments/attempts/$attemptId/submit', body);
    }
    return await ApiClient.post('/assessments/$id/submit', body);
  }
}
