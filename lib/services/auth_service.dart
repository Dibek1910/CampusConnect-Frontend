import 'package:campus_connect/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<ApiResponse> requestLoginOtp(String email) async {
    return await ApiService.post('/auth/login', {'email': email});
  }

  Future<ApiResponse> verifyLoginOtp(String email, String otp) async {
    final response = await ApiService.post('/auth/verify/login', {
      'email': email,
      'otp': otp,
    });

    if (response.statusCode == 200 && response.data != null) {
      final prefs = await SharedPreferences.getInstance();
      final data = response.data['data'];
      await prefs.setString('token', data['token']);
      await prefs.setString('role', data['role']);
      await prefs.setString('userId', data['userId']);
    }

    return response;
  }

  Future<ApiResponse> registerStudent(Map<String, dynamic> userData) async {
    return await ApiService.post('/auth/register/student', userData);
  }

  Future<ApiResponse> registerFaculty(Map<String, dynamic> userData) async {
    return await ApiService.post('/auth/register/faculty', userData);
  }

  Future<ApiResponse> verifyRegistrationOtp(String email, String otp) async {
    final response = await ApiService.post('/auth/verify/registration', {
      'email': email,
      'otp': otp,
    });

    if (response.statusCode == 200 && response.data != null) {
      final prefs = await SharedPreferences.getInstance();
      final data = response.data['data'];
      await prefs.setString('token', data['token']);
      await prefs.setString('role', data['role']);
      await prefs.setString('userId', data['userId']);
    }

    return response;
  }

  Future<ApiResponse> getAllowedBranches() async {
    return await ApiService.get('/auth/branches');
  }

  Future<ApiResponse> getAllowedDepartments() async {
    return await ApiService.get('/auth/departments');
  }

  Future<ApiResponse> getUserProfile() async {
    return await ApiService.get('/auth/me');
  }

  Future<ApiResponse> logout() async {
    try {
      final response = await ApiService.post('/auth/logout', {});

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('role');
      await prefs.remove('userId');

      return response;
    } catch (e) {
      print('Error during logout: $e');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('role');
      await prefs.remove('userId');

      return ApiResponse(
        statusCode: 500,
        data: null,
        error: 'Error during logout: $e',
      );
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  Future<ApiResponse> generateOtp(String email) async {
    return await ApiService.post('/auth/profile-update/send-otp', {
      "email": email,
    });
  }

  Future<ApiResponse> verifyOtp(String email, String otp) async {
    return await ApiService.post('/auth/profile-update/verify-otp', {
      "email": email,
      "otp": otp,
    });
  }
}
