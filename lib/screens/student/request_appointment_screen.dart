import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:campus_connect/providers/appointment_provider.dart';
import 'package:campus_connect/widgets/button_widget.dart';
import 'package:campus_connect/widgets/input_field.dart';
import 'package:campus_connect/widgets/loading_indicator.dart';
import 'package:campus_connect/config/theme.dart';

class RequestAppointmentScreen extends StatefulWidget {
  final String facultyId;
  final String facultyName;

  const RequestAppointmentScreen({
    Key? key,
    required this.facultyId,
    required this.facultyName,
  }) : super(key: key);

  @override
  State<RequestAppointmentScreen> createState() =>
      _RequestAppointmentScreenState();
}

class _RequestAppointmentScreenState extends State<RequestAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedDuration = '30';
  String _selectedPurposeCategory = 'Academic';
  String _startTime = '09:00';
  bool _isSubmitting = false;

  final List<String> _durationOptions = ['15', '30', '45', '60'];
  final List<String> _purposeCategories = [
    'Academic',
    'Personal',
    'Project',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Set default date to next weekday if today is weekend
    _setDefaultDate();
  }

  void _setDefaultDate() {
    final now = DateTime.now();
    if (now.weekday > 5) {
      // If weekend, set to next Monday
      _selectedDate = now.add(Duration(days: 8 - now.weekday));
    } else {
      _selectedDate = now;
    }
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      selectableDayPredicate: (DateTime date) {
        return date.weekday <= 5; // Only weekdays
      },
      helpText: 'Select appointment date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_startTime.split(':')[0]),
        minute: int.parse(_startTime.split(':')[1]),
      ),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
      helpText: 'Select start time (9 AM - 6 PM)',
    );

    if (picked != null) {
      if (picked.hour < 9 || picked.hour >= 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a time between 9:00 AM and 6:00 PM'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      final int durationMinutes = int.parse(_selectedDuration);
      final int endHour = picked.hour + (picked.minute + durationMinutes) ~/ 60;
      final int endMinute = (picked.minute + durationMinutes) % 60;

      if (endHour > 18 || (endHour == 18 && endMinute > 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment must end before 6:00 PM'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      // Check if the time is not in the past for today's date
      final now = DateTime.now();
      if (_selectedDate.day == now.day &&
          _selectedDate.month == now.month &&
          _selectedDate.year == now.year) {
        if (picked.hour < now.hour ||
            (picked.hour == now.hour && picked.minute <= now.minute)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot select past time for today'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          return;
        }
      }

      setState(() {
        _startTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  String _calculateEndTime() {
    final parts = _startTime.split(':');
    final startHour = int.parse(parts[0]);
    final startMinute = int.parse(parts[1]);
    final durationMinutes = int.parse(_selectedDuration);

    final endTimeMinutes = startHour * 60 + startMinute + durationMinutes;
    final endHour = endTimeMinutes ~/ 60;
    final endMinute = endTimeMinutes % 60;

    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }

  Future<void> _requestAppointment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final appointmentProvider = Provider.of<AppointmentProvider>(
        context,
        listen: false,
      );

      final endTime = _calculateEndTime();

      final appointmentData = {
        'facultyId': widget.facultyId,
        'date': _selectedDate.toIso8601String(),
        'startTime': _startTime,
        'endTime': endTime,
        'duration': _selectedDuration,
        'purposeCategory': _selectedPurposeCategory,
        'purpose': _purposeController.text,
        'isDirectRequest': true,
      };

      final success = await appointmentProvider.requestAppointment(
        appointmentData,
      );

      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar(
          appointmentProvider.error ?? 'Failed to request appointment',
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Appointment Requested'),
            content: const Text(
              'Your appointment request has been sent to the faculty. You will be notified once it is approved or rejected.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentProvider = Provider.of<AppointmentProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Request Appointment'), elevation: 4),
      body:
          _isSubmitting
              ? const LoadingIndicator(message: 'Requesting appointment...')
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        margin: const EdgeInsets.only(bottom: 24),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Faculty Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow('Faculty', widget.facultyName),
                            ],
                          ),
                        ),
                      ),

                      Card(
                        margin: const EdgeInsets.only(bottom: 24),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Appointment Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Date: ${DateFormat('EEE, MMM d, yyyy').format(_selectedDate)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _selectDate(context),
                                    icon: const Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                    ),
                                    label: const Text('Select'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Start Time: $_startTime',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _selectTime(context),
                                    icon: const Icon(
                                      Icons.access_time,
                                      size: 18,
                                    ),
                                    label: const Text('Select'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Duration (minutes):',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedDuration,
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                        items:
                                            _durationOptions.map((duration) {
                                              return DropdownMenuItem<String>(
                                                value: duration,
                                                child: Text(
                                                  '$duration minutes',
                                                ),
                                              );
                                            }).toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _selectedDuration = value;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Purpose Category:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedPurposeCategory,
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                        items:
                                            _purposeCategories.map((category) {
                                              return DropdownMenuItem<String>(
                                                value: category,
                                                child: Text(category),
                                              );
                                            }).toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _selectedPurposeCategory = value;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),
                              Text(
                                'End Time: ${_calculateEndTime()}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      InputField(
                        label: 'Purpose Details',
                        hint:
                            'Briefly describe the purpose of your appointment',
                        controller: _purposeController,
                        maxLines: 5,
                        minLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the purpose of your appointment';
                          }
                          if (value.length < 10) {
                            return 'Purpose should be at least 10 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      ButtonWidget(
                        text: 'Request Appointment',
                        onPressed: _requestAppointment,
                        isLoading: _isSubmitting,
                        width: double.infinity,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
