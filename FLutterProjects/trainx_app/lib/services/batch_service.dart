import 'api_client.dart';

class BatchService {
  // GET /api/v1/batches/my-batches
  static Future<List<Map<String, dynamic>>> getMyBatches() async {
    final res = await ApiClient.get('/batches/my-batches');
    if (res['success'] == true && res['data'] is List) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // POST /api/v1/batches/join
  static Future<Map<String, dynamic>> joinBatch(String code) async {
    final cleanCode = code.trim().toUpperCase();
    return await ApiClient.post('/batches/join', {
      'join_code': cleanCode,
      'joinCode': cleanCode,
      'code': cleanCode,
    });
  }

  // GET /api/v1/batches/:id
  static Future<Map<String, dynamic>> getBatchById(dynamic id) async {
    final res = await ApiClient.get('/batches/$id');
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return res['data'];
    }
    return res;
  }

  // GET /api/v1/batches/:id/daily-topics
  static Future<List<Map<String, dynamic>>> getBatchDailyTopics(dynamic batchId) async {
    final res = await ApiClient.get('/batches/$batchId/daily-topics');
    if (res['success'] == true && res['data'] is List) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // GET /api/v1/batches/:id/tasks
  static Future<List<Map<String, dynamic>>> getBatchTasks(dynamic batchId) async {
    final res = await ApiClient.get('/batches/$batchId/tasks');
    if (res['success'] == true && res['data'] is List) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
}
