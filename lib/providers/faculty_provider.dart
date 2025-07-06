import 'package:flutter/material.dart';
import 'package:campus_connect/models/faculty_model.dart';
import 'package:campus_connect/models/appointment_model.dart';
import 'package:campus_connect/models/availability_model.dart';
import 'package:campus_connect/services/api_service.dart';
import 'package:campus_connect/models/profile_model.dart';

class FacultyProvider extends ChangeNotifier {
  List<FacultyModel> _facultyList = [];
  List<AppointmentModel> _appointments = [];
  List<AvailabilityModel> _availabilities = [];
  FacultyModel? _selectedFaculty;
  bool _isLoading = false;
  String? _error;

  List<FacultyModel> get facultyList => _facultyList;
  List<AppointmentModel> get appointments => _appointments;
  List<AvailabilityModel> get availabilities => _availabilities;
  FacultyModel? get selectedFaculty => _selectedFaculty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchFacultyList() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/students/faculty');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        _facultyList =
            (data as List)
                .map((faculty) => FacultyModel.fromJson(faculty))
                .toList();
      } else {
        _error = response.error ?? 'Failed to fetch faculty list';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchFaculty(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_facultyList.isEmpty) {
        await fetchFacultyList();
      }

      if (query.isNotEmpty) {
        final lowercaseQuery = query.toLowerCase();
        _facultyList =
            _facultyList.where((faculty) {
              return faculty.name.toLowerCase().contains(lowercaseQuery) ||
                  faculty.department.toString().toLowerCase().contains(
                    lowercaseQuery,
                  );
            }).toList();
      } else {
        await fetchFacultyList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFacultyDetails(String facultyId) async {
    _isLoading = true;
    _error = null;
    _selectedFaculty = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/faculty/$facultyId');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        _selectedFaculty = FacultyModel.fromJson(data);
      } else {
        _error = response.error ?? 'Failed to fetch faculty details';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFacultyAvailability(String facultyId) async {
    _isLoading = true;
    _error = null;
    _availabilities = [];
    notifyListeners();

    try {
      final response = await ApiService.get(
        '/students/faculty/$facultyId/availability',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];

        if (data != null && data is List) {
          _availabilities =
              data
                  .map((availability) {
                    try {
                      return AvailabilityModel.fromJson(availability);
                    } catch (e) {
                      return null;
                    }
                  })
                  .whereType<AvailabilityModel>()
                  .toList();
        } else {
          _error = 'Invalid availability data format';
        }
      } else {
        _error = response.error ?? 'Failed to fetch faculty availability';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFacultyAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/appointments/faculty');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        _appointments =
            (data as List)
                .map((appointment) => AppointmentModel.fromJson(appointment))
                .toList();
      } else {
        _error = response.error ?? 'Failed to fetch appointments';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAppointmentStatus(
    String appointmentId,
    String status, {
    String? reason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = {
        'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      };

      final response = await ApiService.put(
        '/appointments/$appointmentId/status',
        body,
      );
      if (response.statusCode == 200) {
        await fetchFacultyAppointments();
        return true;
      } else {
        _error = response.error ?? 'Failed to update appointment status';
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

  Future<bool> completeAppointment(String appointmentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.put(
        '/appointments/$appointmentId/complete',
        {},
      );
      if (response.statusCode == 200) {
        await fetchFacultyAppointments();
        return true;
      } else {
        _error = response.error ?? 'Failed to complete appointment';
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

  Future<bool> cancelAppointment(String appointmentId, {String? reason}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = {if (reason != null && reason.isNotEmpty) 'reason': reason};

      final response = await ApiService.put(
        '/appointments/$appointmentId/cancel',
        body,
      );
      if (response.statusCode == 200) {
        await fetchFacultyAppointments();
        return true;
      } else {
        _error = response.error ?? 'Failed to cancel appointment';
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
