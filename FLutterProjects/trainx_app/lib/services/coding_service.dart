import 'api_client.dart';

class CodingService {
  // GET /api/v1/student/practice-problems
  static Future<List<Map<String, dynamic>>> getPracticeProblems() async {
    final res = await ApiClient.get('/student/practice-problems');
    if (res['success'] == true && res['data'] is List) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // GET /api/v1/student/practice-problems/:id
  static Future<Map<String, dynamic>> getPracticeProblemById(dynamic id) async {
    final res = await ApiClient.get('/student/practice-problems/$id');
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return res['data'];
    }
    return res;
  }

  // POST /api/v1/code/run
  static Future<Map<String, dynamic>> runCode({
    required String code,
    required String language,
    String? input,
  }) async {
    return await ApiClient.post('/code/run', {
      'code': code,
      'language': language,
      'input': input ?? '',
    });
  }

  // POST /api/v1/code/submit
  static Future<Map<String, dynamic>> submitCode({
    required dynamic problemId,
    required String code,
    required String language,
  }) async {
    return await ApiClient.post('/code/submit', {
      'problem_id': problemId,
      'code': code,
      'language': language,
    });
  }

  // GET /api/v1/code/submissions/my
  static Future<List<Map<String, dynamic>>> getMySubmissions() async {
    final res = await ApiClient.get('/code/submissions/my');
    if (res['success'] == true && res['data'] is List) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
}
