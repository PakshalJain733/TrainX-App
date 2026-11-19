import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class AuthService {
  static String normalizeRole(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.contains('superadmin') || lower.contains('super_admin') || lower.contains('super')) {
      return 'super_admin';
    }
    if (lower.contains('admin') || lower.contains('college_admin') || lower.contains('hod')) {
      return 'college_admin';
    }
    if (lower.contains('trainer') || lower.contains('instructor')) {
      return 'trainer';
    }
    if (lower.contains('mentor') || lower.contains('faculty')) {
      return 'mentor';
    }
    if (lower.contains('coordinator')) {
      return 'coordinator';
    }
    return 'student';
  }

  static String? extractRoleFromToken(String token) {
    if (token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length >= 2) {
        final normalized = base64Url.normalize(parts[1]);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final json = jsonDecode(decoded);
        return json['role']?.toString() ?? json['userRole']?.toString();
      }
    } catch (_) {}
    return null;
  }

  static Future<String> resolveCanonicalRole() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final jwtRole = extractRoleFromToken(token);

    if (jwtRole != null && jwtRole.isNotEmpty) {
      final normalized = normalizeRole(jwtRole);
      await prefs.setString('studentRole', normalized);
      await prefs.setString('userRole', normalized);
      await prefs.setString('role', normalized);
      return normalized;
    }

    final cached = prefs.getString('role') ?? prefs.getString('userRole') ?? prefs.getString('studentRole');
    if (cached != null && cached.isNotEmpty) {
      return normalizeRole(cached);
    }

    return 'student';
  }

  static Future<Map<String, dynamic>> _handleAuthResponse(http.Response response) async {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && (data['success'] == true || data['status'] == 'success')) {
        final payload = data['data'] ?? {};
        final user = payload['user'] ?? payload;
        final token = (payload['token'] ?? '').toString();

        final jwtRole = extractRoleFromToken(token);
        final rawRole = user['role']?.toString() ?? jwtRole ?? 'student';
        final role = normalizeRole(rawRole);

        // Save session locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('userId', (user['id'] ?? user['userId'] ?? '').toString());
        await prefs.setString('studentName', (user['name'] ?? 'User').toString());
        await prefs.setString('userName', (user['name'] ?? 'User').toString());
        await prefs.setString('studentEmail', (user['email'] ?? '').toString());
        await prefs.setString('userEmail', (user['email'] ?? '').toString());
        await prefs.setString('studentRole', role);
        await prefs.setString('userRole', role);
        await prefs.setString('role', role);
        await prefs.setString('department', (user['department'] ?? '').toString());

        return {
          'success': true,
          'user': user,
          'token': token,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Authentication failed. Please check credentials.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to server. Please check your backend.',
      };
    }
  }

  // Password Login (matches POST /api/v1/auth/login-password)
  static Future<Map<String, dynamic>> loginStudent(
    String identifier,
    String password, {
    bool rememberMe = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.loginEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': identifier.trim(),
          'password': password.trim(),
          'rememberMe': rememberMe,
        }),
      );
      return await _handleAuthResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: Backend is not reachable.',
      };
    }
  }

  // Send Email OTP (matches POST /api/v1/auth/send-otp)
  static Future<Map<String, dynamic>> sendOtp(String identifier) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.sendOtpEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': identifier.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && (data['success'] == true || data['status'] == 'success')) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent to your email successfully.',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send OTP.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Could not send OTP.',
      };
    }
  }

  // Verify OTP and Login (matches POST /api/v1/auth/verify-otp)
  static Future<Map<String, dynamic>> verifyOtp(
    String identifier,
    String otp, {
    bool rememberMe = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.verifyOtpEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': identifier.trim(),
          'otp': otp.trim(),
          'rememberMe': rememberMe,
        }),
      );
      return await _handleAuthResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error during OTP verification.',
      };
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, String>> getCurrentStudent() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('studentName') ?? 'Student',
      'email': prefs.getString('studentEmail') ?? '',
      'department': prefs.getString('department') ?? '',
      'role': prefs.getString('studentRole') ?? 'student',
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
