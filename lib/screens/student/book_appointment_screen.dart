import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:campus_connect/providers/appointment_provider.dart';
import 'package:campus_connect/widgets/button_widget.dart';
import 'package:campus_connect/widgets/input_field.dart';
import 'package:campus_connect/widgets/loading_indicator.dart';
import 'package:campus_connect/config/theme.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String facultyId;
  final String facultyName;
  final String availabilityId;
  final String day;
  final DateTime date;
  final String startTime;
  final String endTime;

  const BookAppointmentScreen({
    super.key,
    required this.facultyId,
    required this.facultyName,
    required this.availabilityId,
    required this.day,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  String _selectedPurposeCategory = 'Academic';
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _purposeCategories = [
    'Academic',
    'Personal',
    'Project',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d, yyyy').format(date);
  }

  Future<void> _bookAppointment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final appointmentProvider = Provider.of<AppointmentProvider>(
        context,
        listen: false,
      );

      final appointmentData = {
        'facultyId': widget.facultyId,
        'availabilityId': widget.availabilityId,
        'date': widget.date.toIso8601String(),
        'purpose': _purposeController.text,
        'purposeCategory': _selectedPurposeCategory,
        'isDirectRequest': false,
      };

      final success = await appointmentProvider.bookAppointment(
        appointmentData,
      );

      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar(
          appointmentProvider.error ?? 'Failed to book appointment',
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
            title: const Text('Appointment Booked'),
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
    final _ = Provider.of<AppointmentProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment'), elevation: 4),
      body:
          _isSubmitting
              ? const LoadingIndicator(message: 'Booking appointment...')
              : FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
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
                                  'Appointment Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildDetailRow('Faculty', widget.facultyName),
                                _buildDetailRow(
                                  'Date',
                                  _formatDate(widget.date),
                                ),
                                _buildDetailRow('Day', widget.day),
                                _buildDetailRow(
                                  'Time',
                                  '${widget.startTime} - ${widget.endTime}',
                                ),
                              ],
                            ),
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Purpose Category:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
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
                          text: 'Book Appointment',
                          onPressed: _bookAppointment,
                          isLoading: _isSubmitting,
                          width: double.infinity,
                        ),
                      ],
                    ),
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
