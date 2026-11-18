import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class ApiClient {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> getHeaders({bool isJson = true}) async {
    final token = await getToken();
    final headers = <String, String>{
      if (isJson) 'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Uri _uri(String endpoint) {
    if (endpoint.startsWith('http')) {
      return Uri.parse(endpoint);
    }
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('${AppConstants.baseUrl}$cleanEndpoint');
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(_uri(endpoint), headers: headers);
      return _processResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> post(String endpoint, dynamic body) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        _uri(endpoint),
        headers: headers,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> patch(String endpoint, dynamic body) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        _uri(endpoint),
        headers: headers,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network connection failed: $e'};
    }
  }

  static Map<String, dynamic> _processResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (body is Map<String, dynamic>) {
          return body;
        }
        return {'success': true, 'data': body};
      } else {
        final message = (body is Map) ? (body['message'] ?? 'Request failed') : 'Request failed';
        return {'success': false, 'message': message, 'statusCode': response.statusCode};
      }
    } catch (_) {
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'message': response.body,
        'statusCode': response.statusCode,
      };
    }
  }
}
