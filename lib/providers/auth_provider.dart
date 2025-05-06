import 'package:flutter/material.dart';
import 'package:campus_connect/models/user_model.dart';
import 'package:campus_connect/models/student_model.dart';
import 'package:campus_connect/models/faculty_model.dart';
import 'package:campus_connect/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_connect/services/api_service.dart';
import 'package:campus_connect/models/profile_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  StudentModel? _studentProfile;
  FacultyModel? _facultyProfile;
  bool _isLoading = false;
  String? _error;
  final AuthService _authService = AuthService();

  UserModel? get user => _user;
  StudentModel? get studentProfile => _studentProfile;
  FacultyModel? get facultyProfile => _facultyProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  String get userRole => _user?.role ?? '';

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        await _fetchUserProfile();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestLoginOtp(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.requestLoginOtp(email);
      if (response.statusCode == 200) {
        return true;
      } else {
        _error = response.error ?? 'Failed to send OTP';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyLoginOtp(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.verifyLoginOtp(email, otp);
      if (response.statusCode == 200) {
        await _fetchUserProfile();
        return true;
      } else {
        _error = response.error ?? 'Invalid OTP';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> registerStudent(
    Map<String, dynamic> userData,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.registerStudent(userData);
      if (response.statusCode == 201) {
        return response.data;
      } else {
        _error = response.error ?? 'Registration failed';
        return null;
      }
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> registerFaculty(
    Map<String, dynamic> userData,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.registerFaculty(userData);
      if (response.statusCode == 201) {
        return response.data;
      } else {
        _error = response.error ?? 'Registration failed';
        return null;
      }
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyRegistrationOtp(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.verifyRegistrationOtp(email, otp);
      if (response.statusCode == 200) {
        await _fetchUserProfile();
        return true;
      } else {
        _error = response.error ?? 'Invalid OTP';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.logout();

      _user = null;
      _studentProfile = null;
      _facultyProfile = null;

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();

      return true;
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await _authService.getUserProfile();
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data['data'];

        if (userData['user'] != null) {
          _user = UserModel.fromJson(userData['user']);

          if (_user!.role == 'student' && userData['profile'] != null) {
            _studentProfile = StudentModel.fromJson(userData['profile']);
          } else if (_user!.role == 'faculty' && userData['profile'] != null) {
            _facultyProfile = FacultyModel.fromJson(userData['profile']);
          }
        }
      } else {
        _error = response.error ?? 'Failed to fetch user profile';
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> generateOtp(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.generateOtp(email);
      if (response.statusCode == 200) {
        return true;
      } else {
        _error = response.error ?? 'Failed to generate OTP';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.verifyOtp(email, otp);
      if (response.statusCode == 200) {
        return true;
      } else {
        _error = response.error ?? 'Failed to verify OTP';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStudentProfile(ProfileModel profile, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.put('/students/profile', {
        'name': profile.name,
        'phoneNumber': profile.phoneNumber,
        'course': profile.course,
        'branch': profile.branch,
        'currentYear': profile.currentYear,
        'currentSemester': profile.currentSemester,
        'isOTPVerified': true,
      });
      if (response.statusCode == 200) {
        await _fetchUserProfile();
        return true;
      } else {
        _error = response.error ?? 'Failed to update profile';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateFacultyProfile(ProfileModel profile, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.put('/faculty/profile', {
        'name': profile.name,
        'phoneNumber': profile.phoneNumber,
        'isOTPVerified': true,
      });
      if (response.statusCode == 200) {
        await _fetchUserProfile();
        return true;
      } else {
        _error = response.error ?? 'Failed to update profile';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
