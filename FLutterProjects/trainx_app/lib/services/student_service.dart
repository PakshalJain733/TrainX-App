import 'api_client.dart';

class StudentService {
  // GET /api/v1/student/dashboard
  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await ApiClient.get('/student/dashboard');
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return res['data'];
    }
    return res;
  }

  // GET /api/v1/student/profile
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await ApiClient.get('/student/profile');
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return res['data'];
    }
    return res;
  }

  // PATCH /api/v1/student/profile
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    return await ApiClient.patch('/student/profile', profileData);
  }

  // GET /api/v1/student/attendance
  static Future<Map<String, dynamic>> getAttendance() async {
    final res = await ApiClient.get('/student/attendance');
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return res['data'];
    }
    return res;
  }

  // POST /api/v1/attendance/mark
  static Future<Map<String, dynamic>> markAttendance(String code) async {
    return await ApiClient.post('/attendance/mark', {'code': code});
  }

  // POST /api/v1/student/attendance/leave
  static Future<Map<String, dynamic>> applyLeave({
    required String category,
    required String fromDate,
    required String toDate,
    required String reason,
    int days = 1,
  }) async {
    return await ApiClient.post('/student/attendance/leave', {
      'category': category,
      'start_date': fromDate,
      'end_date': toDate,
      'reason': reason,
      'days': days,
    });
  }

  // GET /api/v1/student/materials
  static Future<List<Map<String, dynamic>>> getMaterials() async {
    final res = await ApiClient.get('/student/materials');
    if (res['success'] == true && res['data'] is List) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // GET /api/v1/student/weekly-reports
  static Future<List<Map<String, dynamic>>> getWeeklyReports() async {
    final res = await ApiClient.get('/student/weekly-reports');
    if (res['success'] == true && res['data'] is List) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // GET /api/v1/student/support/tickets
  static Future<List<Map<String, dynamic>>> getSupportTickets() async {
    final res = await ApiClient.get('/student/support/tickets');
    if (res['success'] == true && res['data'] is List) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // POST /api/v1/student/support/tickets
  static Future<Map<String, dynamic>> createSupportTicket({
    required String subject,
    required String category,
    required String priority,
    required String description,
  }) async {
    return await ApiClient.post('/student/support/tickets', {
      'subject': subject,
      'category': category,
      'priority': priority,
      'description': description,
    });
  }

  // GET /api/v1/leaderboard
  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final res = await ApiClient.get('/leaderboard');
    if (res['success'] == true && res['data'] is List) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // GET /api/v1/leaderboard/student/my-rank
  static Future<Map<String, dynamic>> getMyRank() async {
    final res = await ApiClient.get('/leaderboard/student/my-rank');
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return res['data'];
    }
    return res;
  }
}
