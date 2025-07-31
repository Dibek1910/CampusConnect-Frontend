import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiResponse {
  final int statusCode;
  final dynamic data;
  final String? error;

  ApiResponse({required this.statusCode, required this.data, this.error});
}

class ApiService {
  static String get baseUrl {
    return 'https://campusconenct-backend.onrender.com/api';
  }

  // static String get baseUrl {
  //   if (kIsWeb) {
  //     return 'http://localhost:5001/api';
  //   }

  //   if (Platform.isAndroid) {
  //     return 'http://10.0.2.2:5001/api';
  //   }

  //   if (Platform.isIOS) {
  //     return 'http://localhost:5001/api';
  //   }

  //   return 'http://localhost:5001/api';
  // }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<ApiResponse> get(String endpoint) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      return _processResponse(response);
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        data: null,
        error: 'Network error: $e',
      );
    }
  }

  static Future<ApiResponse> post(String endpoint, dynamic body) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      return _processResponse(response);
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        data: null,
        error: 'Network error: $e',
      );
    }
  }

  static Future<ApiResponse> put(String endpoint, dynamic body) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      return _processResponse(response);
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        data: null,
        error: 'Network error: $e',
      );
    }
  }

  static Future<ApiResponse> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      return _processResponse(response);
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        data: null,
        error: 'Network error: $e',
      );
    }
  }

  static ApiResponse _processResponse(http.Response response) {
    try {
      final dynamic data =
          response.body.isNotEmpty ? jsonDecode(response.body) : null;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(statusCode: response.statusCode, data: data);
      } else {
        String errorMessage = 'Unknown error occurred';
        if (data != null && data is Map<String, dynamic>) {
          if (data.containsKey('message')) {
            errorMessage = data['message'];
          } else if (data.containsKey('error')) {
            errorMessage = data['error'];
          }
        }

        return ApiResponse(
          statusCode: response.statusCode,
          data: null,
          error: errorMessage,
        );
      }
    } catch (e) {
      return ApiResponse(
        statusCode: response.statusCode,
        data: null,
        error: 'Failed to process response: $e',
      );
    }
  }

  static Future<ApiResponse> setAvailability(
    String facultyId,
    List<Map<String, dynamic>> slots,
  ) {
    return post('/faculty/set-availability', {
      "facultyId": facultyId,
      "availableSlots": slots,
    });
  }

  static Future<ApiResponse> fetchAvailability(String facultyId) {
    return get('/students/faculty/$facultyId/availability');
  }

  static Future<ApiResponse> bookAppointment(
    Map<String, dynamic> appointmentData,
  ) {
    return post('/appointments', appointmentData);
  }

  static Future<ApiResponse> fetchProfile(String endpoint) {
    return get(endpoint);
  }

  static Future<ApiResponse> updateProfile(
    String endpoint,
    Map<String, dynamic> data,
  ) {
    return put(endpoint, data);
  }

  static Future<ApiResponse> generateOtp() {
    return post('/auth/profile-update/send-otp', {});
  }

  static Future<ApiResponse> verifyOtp(String email, String otp) {
    return post('/auth/profile-update/verify-otp', {
      "email": email,
      "otp": otp,
    });
  }
}
