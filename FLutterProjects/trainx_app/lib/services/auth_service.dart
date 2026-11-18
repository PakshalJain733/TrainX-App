import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class AuthService {
  static Future<Map<String, dynamic>> _handleAuthResponse(http.Response response) async {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && (data['success'] == true || data['status'] == 'success')) {
        final payload = data['data'] ?? {};
        final user = payload['user'] ?? payload;
        final token = payload['token'] ?? '';

        final role = (user['role'] ?? '').toString().toLowerCase();
        if (role.isNotEmpty && role != 'student') {
          return {
            'success': false,
            'message': 'Access restricted: Only registered students can log in here.',
          };
        }

        // Save student session locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token.toString());
        await prefs.setString('userId', (user['id'] ?? '').toString());
        await prefs.setString('studentName', (user['name'] ?? 'Student').toString());
        await prefs.setString('studentEmail', (user['email'] ?? '').toString());
        await prefs.setString('studentRole', role);
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
